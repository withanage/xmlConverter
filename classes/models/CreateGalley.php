<?php

/**
 * @file plugins/generic/xmlConverter/classes/models/CreateGalley.php
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2026 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class CreateGalley
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Create an article galley based on an existing file.
 */

namespace APP\plugins\generic\xmlConverter\classes\models;

use APP\core\Application;
use APP\core\Request;
use APP\core\Services;
use APP\facades\Repo;
use APP\plugins\generic\xmlConverter\classes\helpers\Jats;
use APP\publication\Publication;
use APP\submission\Submission;
use DOMDocument;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use PKP\config\Config;
use PKP\submissionFile\SubmissionFile;

class CreateGalley
{
    private Submission $submission;
    private Publication $publication;
    private SubmissionFile $submissionFile;

    /**
     * Fields posted by the form.
     */
    private array $fields = [
        'label' => '',
        'galleyLocale' => '',
        'createArticleMetaLicense' => '',
        'createArticleMetaHistory' => '',
        'createJournalMeta' => '',
        'createFirstPage' => '',
        'createLastPage' => '',
        'createDatePublished' => ''
    ];

    /**
     * Required fields.
     */
    private array $requiredFields = [
        'label',
        'galleyLocale',
        'createDatePublished'
    ];

    /**
     * Stores the list of validation errors.
     * [
     *   field1: ['Error message'],
     *   field2: ['Error message'],
     * ]
     */
    private array $validationErrors = [];

    public function __construct(array $params, Submission $submission, Publication $publication, SubmissionFile $submissionFile)
    {
        $this->submission = $submission;
        $this->publication = $publication;
        $this->submissionFile = $submissionFile;

        foreach ($this->fields as $key => $value) {
            $newValue = strip_tags($params[$key]);
            $this->fields[$key] = empty($newValue) ? '' : $newValue;
        }
    }

    /**
     * Validates the form data
     */
    public function validate(): bool
    {
        foreach ($this->requiredFields as $field) {
            if (empty($this->fields[$field])) {
                $this->validationErrors[$field][0] = __('validator.required');
            }
        }

        return empty($this->validationErrors);
    }

    /**
     * Executes the process of validating the form data, generating and saving a new XML file,
     * updating submission files, creating a new article galley, and handling dependent files.
     */
    public function execute(): JsonResponse
    {
        $request = Application::get()->getRequest();
        $context = $request->getJournal();
        $datePublished = $this->fields['createDatePublished'] ?: $this->publication->getData('datePublished');

        $sourceFile = Repo::submissionFile()->get($this->submissionFile->getId());

        $submissionDir = Repo::submissionFile()->getSubmissionDir(
            $this->submission->getData('contextId'), $this->submission->getId()
        );
        $files_dir = Config::getVar('files', 'files_dir') . DIRECTORY_SEPARATOR;

        $origDocument = new DOMDocument('1.0', 'utf-8');
        if (!Services::get('file')->fs->fileExists($sourceFile->getData('path'))) {
            return response()->json([
                'error' => __('plugins.generic.xmlConverter.error.fileNotFound')
            ], Response::HTTP_NOT_FOUND);
        }
        $sourceFileContent = Services::get('file')->fs->read($sourceFile->getData('path'));
        $origDocument->loadXML($sourceFileContent);

        $copyrightYear = $this->getCopyrightYear($request);

        if ($this->fields['createArticleMetaLicense'])
            Jats::updateArticleMetaCCBYLicense($origDocument, $context, $copyrightYear);

        if ($this->fields['createJournalMeta'])
            Jats::updateJournalMeta($origDocument, $context);

        Jats::updateJournalMetaPubDate(
            $origDocument, $context, $this->submission, $datePublished,
            $this->fields['createFirstPage'], $this->fields['createLastPage']);

        if ($this->fields['createArticleMetaHistory']) {
            Jats::updateArticleMetaHistory($origDocument, $this->submission, $datePublished);
        }

        $tmpFile = tempnam(sys_get_temp_dir(), 'texture-update-xml');
        file_put_contents($tmpFile, $origDocument->saveXML());
        $newFileId = Services::get('file')->add($tmpFile, $files_dir . $submissionDir . DIRECTORY_SEPARATOR . uniqid() . '.xml');
        $newSubmissionFile = Repo::submissionFile()->newDataObject();
        $newSubmissionFile->setAllData(
            [
                'fileId' => $newFileId,
                'assocType' => $sourceFile->getData('assocType'),
                'assocId' => $sourceFile->getData('assocId'),
                'fileStage' => SubmissionFile::SUBMISSION_FILE_PROOF,
                'mimetype' => $sourceFile->getData('mimetype'),
                'locale' => $sourceFile->getData('locale'),
                'genreId' => $sourceFile->getData('genreId'),
                // 'name' => $sourceFile->getData('name'),
                'submissionId' => $this->submission->getId()
            ]
        );
        $newSubmissionFileId = Repo::submissionFile()->add($newSubmissionFile);
        $newSubmissionFile = Repo::submissionFile()->get($newSubmissionFileId);
        unlink($tmpFile);

        $articleGalley = Repo::galley()->newDataObject();
        $articleGalley->setData('publicationId', $this->publication->getId());
        $articleGalley->setLabel($this->fields['label']);
        $articleGalley->setLocale($this->fields['galleyLocale']);
        $articleGalley->setData('submissionFileId', $newSubmissionFile->getId());
        Repo::galley()->add($articleGalley);

        // Get dependent files of the XML source file
        $dependentFiles = Repo::submissionFile()->getCollector()
            ->filterByAssoc(Application::ASSOC_TYPE_SUBMISSION_FILE, [$sourceFile->getData('id')])
            ->filterBySubmissionIds([$this->submission->getId()])
            ->filterByFileStages([SubmissionFile::SUBMISSION_FILE_DEPENDENT])
            ->includeDependentFiles()
            ->getMany();

        foreach ($dependentFiles as $dependentFile) {
            $newDependentFileId = Services::get('file')->add($files_dir . $dependentFile->getData('path'), $files_dir . $submissionDir . DIRECTORY_SEPARATOR . uniqid() . '.xml');
            $newDependentFile = Repo::submissionFile()->newDataObject();
            $newDependentFile->setAllData([
                'fileId' => $newDependentFileId,
                'assocType' => $dependentFile->getData('assocType'),
                'assocId' => $newSubmissionFile->getId(),
                'fileStage' => SubmissionFile::SUBMISSION_FILE_DEPENDENT,
                'mimetype' => $dependentFile->getData('mimetype'),
                'locale' => $dependentFile->getData('locale'),
                'genreId' => $dependentFile->getData('genreId'),
                'name' => $dependentFile->getData('name'),
                'submissionId' => $this->submission->getId()
            ]);
            Repo::submissionFile()->add($newDependentFile);
        }

        return response()->json($articleGalley->getAllData(), Response::HTTP_OK);
    }

    /**
     * Retrieves the list of validation errors.
     *
     * @return array An associative array containing validation errors.
     */
    public function getValidationErrors(): array
    {
        return $this->validationErrors;
    }

    /**
     * Determines the copyright year based on the journal's configured basis.
     */
    private function getCopyrightYear(Request $request): ?string
    {
        $copyrightYear = null;
        switch ($request->getJournal()->getData('copyrightYearBasis')) {
            case 'submission':
                $copyrightYear = date('Y', strtotime($this->publication->getData('datePublished')));
                break;
            case 'issue':
                if ($this->publication->getData('issueId')) {
                    $issue = Repo::issue()->getBySubmissionId($this->submission->getId());
                    if ($issue && $issue->getDatePublished()) {
                        $copyrightYear = date('Y', strtotime($issue->getDatePublished()));
                    }
                }
                break;
        }

        return $copyrightYear;
    }
}

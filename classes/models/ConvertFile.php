<?php

/**
 * @file plugins/generic/xmlConverter/classes/models/ConvertFile.php
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2026 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class ConvertFile
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Convert an article galley to another format.
 */

namespace APP\plugins\generic\xmlConverter\classes\models;

use APP\core\Services;
use APP\facades\Repo;
use APP\plugins\generic\xmlConverter\XmlConverterPlugin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use PKP\core\Core;
use PKP\file\PrivateFileManager;
use PKP\submissionFile\SubmissionFile;
use RuntimeException;

class ConvertFile
{
    private XmlConverterPlugin $plugin;
    private SubmissionFile $submissionFile;
    private string $conversionType;

    /**
     * Constants representing the conversion types.
     */
    private const CONVERSION_TEI_TO_JATS = 'teiToJats';
    private const CONVERSION_JATS_TO_TEI = 'jatsToTei';

    /**
     * Mapping of conversion types to their respective XSLT files.
     */
    private array $styleSheets = [
        self::CONVERSION_TEI_TO_JATS => [
            'TEI-Commons_to_JATS-Publishing.xsl',
        ],
        self::CONVERSION_JATS_TO_TEI => [
            'jats_2_commons1.xsl',
            'jats_2_commons2.xsl',
        ],
    ];

    public function __construct(XmlConverterPlugin $plugin, SubmissionFile $submissionFile, string $conversionType)
    {
        $this->plugin = $plugin;
        $this->submissionFile = $submissionFile;
        $this->conversionType = $conversionType;
    }

    /**
     * Executes the conversion process for XML files.
     */
    public function execute(): JsonResponse
    {
        $fileName = $this->submissionFile->getData('name');
        $genreId = $this->submissionFile->getData('genreId');
        $locale = $this->submissionFile->getData('locale');
        $submissionId = $this->submissionFile->getData('submissionId');
        $submission = Repo::submission()->get($submissionId);
        $contextId = $submission->getData('contextId');
        $fileManager = new PrivateFileManager();
        $filePath = $fileManager->getBasePath() . DIRECTORY_SEPARATOR . $this->submissionFile->getData('path');

        if (!file_exists($filePath)) {
            return response()->json([
                'error' => __('plugins.generic.xmlConverter.error.fileNotFound')
            ], Response::HTTP_NOT_FOUND);
        }

        // Determine the conversion type based on the requested page.
        switch ($this->conversionType) {
            case self::CONVERSION_TEI_TO_JATS:
                $newFile = $this->conversion($filePath, self::CONVERSION_TEI_TO_JATS);
                $ext = '-jats.xml';
                break;
            case self::CONVERSION_JATS_TO_TEI:
                $newFile = $this->conversion($filePath, self::CONVERSION_JATS_TO_TEI);
                $ext = '-tei.xml';
                break;
            default:
                return response()->json([
                    'message' => __("plugins.generic.xmlConverter.mimetypeError.message")
                ], Response::HTTP_OK);
        }

        // Prepare the new file metadata and add it to the submission repository.
        $newSubmissionFile = Repo::submissionFile()->dao->newDataObject();
        $newName = [];
        if (is_array($fileName)) {
            foreach ($fileName as $localeKey => $name) {
                $newName[$localeKey] = pathinfo($name)['filename'] . $ext;
            }
        } else {
            $newName[$locale] = pathinfo($fileName)['filename'] . $ext;
        }

        $submissionDir = Repo::submissionFile()->getSubmissionDir($contextId, $submissionId);
        $newFileId = Services::get('file')->add($newFile, $submissionDir . DIRECTORY_SEPARATOR . uniqid() . '.xml');
        $newSubmissionFile->setAllData([
            'fileId' => $newFileId,
            'assocType' => $this->submissionFile->getData('assocType'),
            'assocId' => $this->submissionFile->getData('assocId'),
            'fileStage' => $this->submissionFile->getData('fileStage'),
            'mimetype' => 'application/xml',
            'locale' => $locale,
            'genreId' => $genreId,
            'name' => $newName,
            'submissionId' => $submissionId,
        ]);
        $newSubmissionFileId = Repo::submissionFile()->add($newSubmissionFile);
        $newSubmissionFile = Repo::submissionFile()->get($newSubmissionFileId);

        return response()->json([
            'message' => $newSubmissionFile->getAllData()
        ], Response::HTTP_OK);
    }

    /**
     * Executes the XSLT conversion process for the given input file.
     *
     * @param string $filePath Path to the input XML file.
     * @param string $conversion Type of conversion to perform.
     *
     * @return string Path to the final transformed XML file.
     *
     * @throws \RuntimeException If the transformation process fails.
     */
    private function conversion(string $filePath, string $conversion): string
    {
        try {
            $tmpInput = $filePath;
            $tmpOutput = null;

            // Apply each XSLT stylesheet in sequence
            foreach ($this->styleSheets[$conversion] as $index => $stylesheet) {
                $tmpOutput = tempnam(sys_get_temp_dir(), $conversion);
                $command = $this->command($tmpInput, $tmpOutput, 'xslt/' . $conversion . '/' . $stylesheet);
                exec($command, $output, $result);

                if ($result !== 0) {
                    error_log("Command failed: " . implode("|", $output));
                    throw new RuntimeException("XSLT transformation failed.");
                }

                // Delete the previous temporary file, except for the initial input
                if ($index > 0 && file_exists($tmpInput)) {
                    unlink($tmpInput);
                }

                // The output file becomes the input for the next transformation
                $tmpInput = $tmpOutput;
            }
        } catch (RuntimeException $e) {
            throw new RuntimeException("Conversion failed: " . $e->getMessage());
        }

        return $tmpOutput;
    }

    /**
     * Constructs a shell command for an XSLT transformation.
     *
     * @param string $input Path to the input file.
     * @param string $output Path to the output file.
     * @param string $xslt Path to the XSLT stylesheet.
     *
     * @return string
     */
    private function command(string $input, string $output, string $xslt): string
    {
        $pluginPath = Core::getBaseDir() . DIRECTORY_SEPARATOR . $this->plugin->getPluginPath();
        $javaProperties = "-Djdk.xml.entityExpansionLimit=0 -Djdk.xml.totalEntitySizeLimit=0 -Djdk.xml.maxGeneralEntitySizeLimit=0";

        return sprintf(
            "cd %s && java %s -jar %s/bin/saxon-he-10.6.jar %s %s/%s -o:%s",
            $pluginPath,
            $javaProperties,
            $pluginPath,
            $input,
            $pluginPath,
            $xslt,
            $output,
        );
    }
}

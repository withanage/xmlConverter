<?php

/**
 * @file plugins/generic/xmlConverter/classes/models/CreateServiceFile.php
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2026 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class CreateServiceFile
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Create a service file.
 */

namespace APP\plugins\generic\xmlConverter\classes\models;

use APP\publication\Publication;
use APP\submission\Submission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;

class CreateServiceFile
{
    private Submission $submission;
    private Publication $publication;

    /**
     * Fields posted by the form.
     */
    private array $fields = [
        'serviceFile' => '',
        'serviceType' => '',
        'serviceFileLocale' => ''
    ];

    /**
     * Required fields.
     */
    private array $requiredFields = [
        'serviceFile',
        'serviceType',
        'serviceFileLocale'
    ];

    /**
     * Stores the list of validation errors.
     * [
     *   field1: ['Error message'],
     *   field2: ['Error message'],
     * ]
     */
    private array $validationErrors = [];

    private array $listOfServices = [
        'orkg'
    ];

    public function __construct(array $params, Submission $submission, Publication $publication)
    {
        $this->submission = $submission;
        $this->publication = $publication;

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

        if (!in_array($this->fields['serviceType'], $this->listOfServices)) {
            $this->validationErrors['serviceType'][0] = __('validation.invalidOption');
        }

        return empty($this->validationErrors);
    }

    /**
     * Executes the specified service operation based on the service type.
     */
    public function execute(): JsonResponse
    {
        switch ($this->fields['serviceType']) {
            case 'orkg':
                $handler = new OrkgServiceFile();
                $handler->setPublication($this->publication);
                $handler->setServiceFile($this->fields['serviceFile']);
                $handler->setServiceFileLocale($this->fields['serviceFileLocale']);
                $handler->setStageId($this->submission->getData('stageId'));
                $handler->setSubmission($this->submission);
                $handler->process();
                break;
            default:
                return response()->json([
                    'error' => __('api.404.resourceNotFound') . ' [' . $this->fields['serviceType'] . ']'
                ], Response::HTTP_NOT_FOUND);
        }

        return response()->json(['message' => ''], Response::HTTP_OK);
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
}

<?php

/**
 * @file plugins/generic/xmlConverter/classes/PluginApiHandler.php
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2026 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class PluginApiHandler
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Api handler for this plugin.
 */

namespace APP\plugins\generic\xmlConverter\classes;

use APP\facades\Repo;
use APP\plugins\generic\xmlConverter\classes\models\ConvertFile;
use APP\plugins\generic\xmlConverter\classes\models\CreateGalley;
use APP\plugins\generic\xmlConverter\classes\models\CreateServiceFile;
use APP\plugins\generic\xmlConverter\XmlConverterPlugin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request as IlluminateRequest;
use Illuminate\Http\Response;
use PKP\core\PKPBaseController;
use PKP\handler\APIHandler;
use PKP\plugins\Hook;
use PKP\security\Role;

class PluginApiHandler
{
    private XmlConverterPlugin $plugin;

    private const AUTHORIZED_ROLES = [
        Role::ROLE_ID_MANAGER,
        Role::ROLE_ID_SUB_EDITOR,
        Role::ROLE_ID_ASSISTANT
    ];

    public function __construct(XmlConverterPlugin $plugin)
    {
        $this->plugin = $plugin;
    }

    /**
     * This allows adding a route on the fly without defining an api controller.
     * Hook: APIHandler::endpoints::submissions
     * e.g. api/v1/submissions/xmlConverter/createGalley
     */
    public function addRouteDefault(string $hookName, PKPBaseController $apiController, APIHandler $apiHandler): bool
    {
        $apiHandler->addRoute(
            'POST',
            XmlConverterPlugin::PLUGIN_URL . '/createGalley/{submissionId}/{submissionFileId}',
            fn(IlluminateRequest $illuminateRequest): JsonResponse => $this->createGalley($illuminateRequest),
            'xmlConverter.createGalley',
            self::AUTHORIZED_ROLES
        );

        $apiHandler->addRoute(
            'POST',
            XmlConverterPlugin::PLUGIN_URL . '/createServiceFile/{submissionId}',
            fn(IlluminateRequest $illuminateRequest): JsonResponse => $this->createServiceFile($illuminateRequest),
            'xmlConverter.createServiceFile',
            self::AUTHORIZED_ROLES
        );

        return Hook::CONTINUE;
    }

    /**
     * This allows adding a route on the fly without defining an api controller.
     * Hook: APIHandler::endpoints::submissions
     * e.g. api/v1/submissions/xmlConverter/convert/teiToJats/{submissionFileId}
     */
    public function addRouteConversions(string $hookName, PKPBaseController $apiController, APIHandler $apiHandler): bool
    {
        $apiHandler->addRoute(
            'GET',
            XmlConverterPlugin::PLUGIN_URL . '/convert/{submissionFileId}/{conversionType}',
            fn(IlluminateRequest $illuminateRequest): JsonResponse => $this->convert($illuminateRequest),
            'xmlConverter.convert',
            self::AUTHORIZED_ROLES
        );

        return Hook::CONTINUE;
    }

    /**
     * Create a galley from an existing file.
     */
    public function createGalley(IlluminateRequest $illuminateRequest): JsonResponse
    {
        $submission = Repo::submission()->get((int)$illuminateRequest->route('submissionId'));
        $publication = $submission->getLatestPublication();
        $submissionFile = Repo::submissionFile()->get((int)$illuminateRequest->route('submissionFileId'));

        if (!$publication || !$submissionFile) {
            return response()->json([
                'error' => __('api.404.resourceNotFound')
            ], Response::HTTP_NOT_FOUND);
        }

        $createGalley = new CreateGalley($illuminateRequest->input(), $submission, $publication, $submissionFile);

        if (!$createGalley->validate()) {
            return response()->json([
                'validationErrors' => $createGalley->getValidationErrors()
            ], Response::HTTP_OK);
        }

        return $createGalley->execute();
    }

    /**
     * Create a service or external file.
     */
    public function createServiceFile(IlluminateRequest $illuminateRequest): JsonResponse
    {
        $submission = Repo::submission()->get((int)$illuminateRequest->route('submissionId'));
        $publication = $submission->getLatestPublication();

        if (!$publication) {
            return response()->json([
                'error' => __('api.404.resourceNotFound')
            ], Response::HTTP_NOT_FOUND);
        }

        $createServiceFile = new CreateServiceFile($illuminateRequest->input(), $submission, $publication);

        if (!$createServiceFile->validate()) {
            return response()->json([
                'validationErrors' => $createServiceFile->getValidationErrors()
            ], Response::HTTP_OK);
        }

        return $createServiceFile->execute();
    }

    /**
     * Handles the conversion process for XML files.
     */
    public function convert(IlluminateRequest $illuminateRequest): JsonResponse
    {
        $submissionFile = Repo::submissionFile()->get((int)$illuminateRequest->route('submissionFileId'));
        $conversionType = $illuminateRequest->route('conversionType');

        if (!$submissionFile) {
            return response()->json(
                ['error' => __('api.404.resourceNotFound')],
                Response::HTTP_NOT_FOUND
            );
        }

        $convertFile = new ConvertFile($this->plugin, $submissionFile, $conversionType);

        return $convertFile->execute();
    }
}

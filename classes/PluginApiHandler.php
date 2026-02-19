<?php

namespace APP\plugins\generic\xmlConverter\api\v1\submissions;

use APP\API\v1\submissions\SubmissionController;
use APP\plugins\generic\xmlConverter\handlers\XmlConverterHandler;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Route;
use PKP\security\Role;

class XmlConvertController extends SubmissionController
{
    /**
     * @copydoc \PKP\core\PKPBaseController::getGroupRoutes()
     */
    public function getGroupRoutes(): void
    {
        parent::getGroupRoutes();
        Route::middleware([
            self::roleAuthorizer([
                Role::ROLE_ID_MANAGER,
                Role::ROLE_ID_SUB_EDITOR,
                Role::ROLE_ID_ASSISTANT,
            ]),
        ])->group(function () {
            Route::get('file/{type}/convert', $this->convert(...))
                ->name('submission.convert')
                ->where('type', '[A-Za-z]+');
        });
    }

    /**
     * Convert JATS and TEI files
     * @param Request $illuminateRequest
     * @return JsonResponse
     * @throws Exception
     */
    public function convert(Request $illuminateRequest): JsonResponse
    {
        try {
            $conversion = (new XmlConverterHandler())
                ->convert(
                    $illuminateRequest->get('fileId'),
                    $illuminateRequest->route()->parameter('type')
                );
            return response()->json([
                'message' => $conversion,
            ], Response::HTTP_OK);
        } catch (Exception $exception) {
            return response()->json([
                'message' => $exception,
            ], Response::HTTP_OK);
        }
    }
}

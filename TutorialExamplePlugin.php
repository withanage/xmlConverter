<?php
namespace APP\plugins\generic\tutorialExample;

use PKP\plugins\GenericPlugin;

class TutorialExamplePlugin extends GenericPlugin
{
    public function register($category, $path, $mainContextId = NULL)
	{
        // Register the plugin even when it is not enabled
        $success = parent::register($category, $path);

        if ($success && $this->getEnabled()) {
			HookRegistry::register('TemplateManager::fetch', array($this, 'templateFetchCallback'));
			HookRegistry::register('LoadHandler', array($this, 'callbackLoadHandler'));
			$this->_registerTemplateResource();
        }

        return $success;
    }

    /**
     * Provide a name for this plugin
     *
     * The name will appear in the Plugin Gallery where editors can
     * install, enable and disable plugins.
     */
    public function getDisplayName()
	{
		return __('plugins.generic.jats2tei.displayName');
    }

    /**
     * Provide a description for this plugin
     *
     * The description will appear in the Plugin Gallery where editors can
     * install, enable and disable plugins.
     */
    public function getDescription()
	{
        return 'This plugin is an example created for a tutorial on how to create a plugin.';
    }
	public function templateFetchCallback($hookName, $params) {
		$request = $this->getRequest();
		$dispatcher = $request->getDispatcher();

		$templateMgr = $params[0];
		$resourceName = $params[1];
		if ($resourceName == 'controllers/grid/gridRow.tpl') {
			/* @var $row GridRow */
			$row = $templateMgr->getTemplateVars('row');
			$data = $row->getData();
			if (is_array($data) && (isset($data['submissionFile']))) {
				$submissionFile = $data['submissionFile'];
				$fileExtension = strtolower($submissionFile->getData('mimetype'));

				// Ensure that the conversion is run on the appropriate workflow stage
				$stageId = (int) $request->getUserVar('stageId');
				$submissionId = $submissionFile->getData('submissionId');
				$submission = Services::get('submission')->get($submissionId); /** @var $submission Submission */
				$submissionStageId = $submission->getData('stageId');
				$roles = $request->getUser()->getRoles($request->getContext()->getId());

				$accessAllowed = false;
				foreach ($roles as $role) {
					if (in_array($role->getId(), [ROLE_ID_MANAGER, ROLE_ID_SUB_EDITOR, ROLE_ID_ASSISTANT])) {
						$accessAllowed = true;
						break;
					}
				}
				if (in_array(strtolower($fileExtension), static::getSupportedMimetypes()) && // show only for files with docx extension
					$accessAllowed && // only for those that have access according to the DOCXConverterHandler rules
					in_array($stageId, $this->getAllowedWorkflowStages()) && // only for stage ids copyediting or higher
					in_array($submissionStageId, $this->getAllowedWorkflowStages()) // only if submission has correspondent stage id
				) {

					$path = $dispatcher->url($request, ROUTE_PAGE, null, 'docxParser', 'parse', null,
						array(
							'submissionId' => $submissionId,
							'fileId' => $submissionFile->getData('fileId'),
							'stageId' => $stageId
						));
					$pathRedirect = $dispatcher->url($request, ROUTE_PAGE, null, 'workflow', 'access',
						array(
							'submissionId' => $submissionId,
							'fileId' => $submissionFile->getData('fileId'),
							'stageId' => $stageId
						));

					import('lib.pkp.classes.linkAction.request.AjaxAction');
					$linkAction = new LinkAction(
						'parse',
						new PostAndRedirectAction($path, $pathRedirect),
						__('plugins.generic.jats2tei.button.parseDocx')
					);
					$row->addAction($linkAction);
				}
			}
		}
	}
	public static function getSupportedMimetypes()
	{
		return [
			'application/xml',
			'text/xml',
		];
	}
	public function getAllowedWorkflowStages() {
		return [
			WORKFLOW_STAGE_ID_EDITING,
			WORKFLOW_STAGE_ID_PRODUCTION
		];
	}


}

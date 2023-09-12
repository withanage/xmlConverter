<?php

import('lib.pkp.classes.plugins.GenericPlugin');

class TeiToJatsPlugin extends GenericPlugin
{

	function register($category, $path, $mainContextId = null)
	{

		if (parent::register($category, $path, $mainContextId)) {
			if ($this->getEnabled()) {
				// Register callbacks.
				HookRegistry::register('LoadHandler', array($this, 'callbackLoadHandler'));
				HookRegistry::register('TemplateManager::fetch', array($this, 'templateFetchCallback'));

				$this->_registerTemplateResource();
			}
			return true;
		}
		return false;
	}

	function getPluginUrl($request) {
		return $request->getBaseUrl() . '/' . $this->getPluginPath();
	}
	public function getDisplayName()
	{
		return __('plugins.generic.tei2Jats.displayName');
	}

	public function getDescription()
	{
		return __('plugins.generic.tei2Jats.description');
	}

	public function templateFetchCallback($hookName, $params)
	{
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
				$stageId = (int)$request->getUserVar('stageId');
				$submissionId = $submissionFile->getData('submissionId');
				$submission = Services::get('submission')->get($submissionId);
				$submissionStageId = $submission->getData('stageId');
				$roles = $request->getUser()->getRoles($request->getContext()->getId());

				$accessAllowed = false;
				foreach ($roles as $role) {
					if (in_array($role->getId(), [ROLE_ID_MANAGER, ROLE_ID_SUB_EDITOR, ROLE_ID_ASSISTANT, ROLE_ID_SITE_ADMIN])) {
						$accessAllowed = true;
						break;
					}
				}
				if (in_array(strtolower($fileExtension), static::getSupportedMimetypes()) && $accessAllowed && in_array($stageId, $this->getAllowedWorkflowStages()) && // only for stage ids copyediting or higher
					in_array($submissionStageId, $this->getAllowedWorkflowStages())
				) {

					$path = $dispatcher->url($request, ROUTE_PAGE, null, 'teiToJatsConverter', 'convert', null,
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
						'convertTeiToJats',
						new PostAndRedirectAction($path, $pathRedirect),
						__('plugins.generic.teitojats.button.convertToTei')
					);
					$row->addAction($linkAction);
				}

				}

			}
		}



	public static function getSupportedMimetypes()
	{
		return ['text/xml', 'application/xml'];
	}

	public function getAllowedWorkflowStages()
	{
		return [
			WORKFLOW_STAGE_ID_EDITING, WORKFLOW_STAGE_ID_PRODUCTION];
	}

	public function callbackLoadHandler(string $hookName, array $args): bool
	{
		$page = $args[0];
		$op = $args[1];
		if($page && $args) {
			$pageOperator = "$page/$op";
			switch ($pageOperator) {
				case "teiToJatsConverter/convert":
					$this->import('handlers/TeiToJatsHandler');
					define('HANDLER_CLASS', 'TeiToJatsHandler');
					return true;
				default:
					break;
			}
		}

		return false;
	}


}

<?php

namespace APP\plugins\generic\teitojats;

use APP\core\Application;
use APP\facades\Repo;
use APP\plugins\generic\teitojats\handlers\TeiToJatsHandler;
use APP\template\TemplateManager;
use PKP\linkAction\LinkAction;
use PKP\linkAction\request\PostAndRedirectAction;
use PKP\plugins\GenericPlugin;
use PKP\plugins\Hook;
use PKP\security\Role;

class TeiToJatsPlugin extends GenericPlugin
{
	/**
	 * @copydoc GenericPlugin::register()
	 * 
	 * @param string $category
	 * @param string $path
     * @param mixed  $mainContextId
	 * 
	 * @return bool
     */
	public function register($category, $path, $mainContextId = null): bool
	{
		$success = parent::register($category, $path);

		if ($success && $this->getEnabled()) {
			$javaChecker = exec('command java --version >/dev/null && echo "yes" || echo "no"');
		
			if ('yes' == $javaChecker) {
				Hook::add('LoadHandler', [$this, 'callbackLoadHandler']);
				Hook::add('TemplateManager::fetch', [$this, 'templateFetchCallback']);

				$this->_registerTemplateResource();
			}
		}

		return $success;
	}

	/**
	 * Get the URL of this plugin.
	 * 
	 * @param PKPRequest $request
	 * 
	 * @return string
	 */
	public function getPluginUrl($request): string
	{
		return $request->getBaseUrl() . '/' . $this->getPluginPath();
	}

	/**
	 * Provide the display name of this plugin.
	 * 
	 * The name will appear in the Plugin Gallery where editors can install, enable and disable plugins.
	 * 
	 * @return string
	 */
	public function getDisplayName(): string
	{
		return __('plugins.generic.teiToJats.displayName');
	}

	/**
	 * Provide the description of this plugin.
	 * 
	 * The name will appear in the Plugin Gallery where editors can install, enable and disable plugins.
	 * 
	 * @return string
	 */
	public function getDescription(): string
	{
		return __('plugins.generic.teiToJats.description');
	}

	/**
	 * Called before a component template is rendered and returned in an ajax request.
	 * 
	 * @param string $hookName
	 * @param array  $params
	 * 
	 * @return void
	 */
	public function templateFetchCallback($hookName, $params): void
	{
		$request = $this->getRequest();
		$dispatcher = $request->getDispatcher();

		$resourceName = $params[1];

		if ('controllers/grid/gridRow.tpl' == $resourceName) {
			$templateManager = TemplateManager::getManager($request);

			/** @var GridRow $row */
			$row = $templateManager->getTemplateVars('row');
			$data = $row->getData();

			if (is_array($data) && (isset($data['submissionFile']))) {
				// Ensure that the conversion is run on the appropriate workflow stage
				$submissionFile = $data['submissionFile'];
				$submissionId = $submissionFile->getData('submissionId');
				$submission = Repo::submission()->get($submissionId);
				$submissionStageId = $submission->getData('stageId');
				
				$roles = $request->getUser()->getRoles($request->getContext()->getId());
				$accessAllowed = false;
				foreach ($roles as $role) {
					if (in_array($role->getId(), [Role::ROLE_ID_MANAGER, Role::ROLE_ID_SUB_EDITOR, Role::ROLE_ID_ASSISTANT, Role::ROLE_ID_SITE_ADMIN])) {
						$accessAllowed = true;
						
						break;
					}
				}

				$stageId = (int)$request->getUserVar('stageId');
				$fileExtension = strtolower($submissionFile->getData('mimetype'));
				if (
					in_array(strtolower($fileExtension), static::getSupportedMimetypes())
					&& $accessAllowed
					&& in_array($stageId, static::getAllowedWorkflowStages())
					&& in_array($submissionStageId, static::getAllowedWorkflowStages())
				) {
					$args = [
						'submissionId' => $submissionId,
						'fileId' => $submissionFile->getData('fileId'),
						'stageId' => $stageId
					];

					$path = $dispatcher->url($request, Application::ROUTE_PAGE, null, 'teiToJatsConverter', 'convert', null, $args);
					$pathRedirect = $dispatcher->url($request, Application::ROUTE_PAGE, null, 'workflow', 'access', $args);

					$row->addAction(
						new LinkAction(
							'teiToJatsConverter',
							new PostAndRedirectAction($path, $pathRedirect),
							__("plugins.generic.teiToJats.button")
						)
					);
				}
			}
		}
	}

	/**
	 * Provide a list of the supported MIME types.
	 * 
	 * @return array
	 */
	public static function getSupportedMimetypes(): array
	{
		return ['text/xml', 'application/xml'];
	}

	/**
	 * Provide a list of the allowed workflow stages ids.
	 * 
	 * @return array
	 */
	public function getAllowedWorkflowStages(): array
	{
		return [WORKFLOW_STAGE_ID_EDITING, WORKFLOW_STAGE_ID_PRODUCTION];
	}

	/**
	 * Route any request to a custom handler.
	 * 
	 * @param string $hookName
	 * @param array  $args
	 * 
	 * @return bool
	 */
	public function callbackLoadHandler($hookName, $args): bool
	{
		$page = $args[0];
		$operator = $args[1];

		if ('teiToJatsConverter' == $page && 'convert' == $operator) {
			define('HANDLER_CLASS', TeiToJatsHandler::class);
			
			return true;
		}

		return false;
	}
}

if (!PKP_STRICT_MODE) {
    class_alias('\APP\plugins\generic\teitojats\TeiToJatsPlugin', '\TeiToJatsPlugin');
}

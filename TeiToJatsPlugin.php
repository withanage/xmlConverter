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
	 * @param string     $category
	 * @param string	 $path
     * @param null|mixed $mainContextId
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
	 * Route any request to a custom handler.
	 * 
	 * @param string $hookName
	 * @param array  $args
	 * 
	 * @return bool
	 */
	public function callbackLoadHandler(string $hookName, array $args): bool
	{
		$page = $args[0];
		$operator = $args[1];

		if (in_array($page, static::getAllowedConversions()) && 'convert' == $operator) {
			define('HANDLER_CLASS', TeiToJatsHandler::class);
			
			return true;
		}

		return false;
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

			/** @var $row GridRow */
			$row = $templateManager->getTemplateVars('row');
			$data = $row->getData();

			if (is_array($data) && isset($data['submissionFile'])) {
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

					$pathRedirect = $dispatcher->url($request, Application::ROUTE_PAGE, null, 'workflow', 'access', $args);

					$conversions = static::getAllowedConversions();
					foreach ($conversions as $conversion) {
						$row->addAction(
							new LinkAction(
								$conversion,
								new PostAndRedirectAction(
									$dispatcher->url(
										$request,
										Application::ROUTE_PAGE,
										null,
										$conversion,
										'convert',
										null,
										$args
									),
									$pathRedirect
								),
								__("plugins.generic.$conversion.button")
							)
						);
					}
				}
			}
		}
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
		return __('plugins.generic.tei2Jats.displayName');
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
		return __('plugins.generic.tei2Jats.description');
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
	 * Provide a list of the conversions allowed.
	 * 
	 * @return array
	 */
	public static function getAllowedConversions(): array
	{
		return [
			'teiToJats',
			'jatsToTei',
		];
	}

	/**
	 * Provide a list of the allowed workflow stages ids.
	 * 
	 * @return array
	 */
	public static function getAllowedWorkflowStages(): array
	{
		return [WORKFLOW_STAGE_ID_EDITING, WORKFLOW_STAGE_ID_PRODUCTION];
	}
}

if (!PKP_STRICT_MODE) {
    class_alias('\APP\plugins\generic\teitojats\TeiToJatsPlugin', '\TeiToJatsPlugin');
}

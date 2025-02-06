<?php

namespace APP\plugins\generic\xmlConverter;

use APP\core\Application;
use APP\facades\Repo;
use APP\plugins\generic\xmlConverter\handlers\XmlConverterHandler;
use APP\template\TemplateManager;
use PKP\core\PKPRequest;
use PKP\linkAction\LinkAction;
use PKP\linkAction\request\PostAndRedirectAction;
use PKP\plugins\GenericPlugin;
use PKP\plugins\Hook;
use PKP\security\Role;

/**
 * Class XmlConverterPlugin
 * 
 * This plugin provides XML conversion capabilities within the application.
 * It supports specific file conversions (e.g., TEI to JATS and JATS to TEI)
 * and integrates into the application's workflow through hooks and custom handlers.
 */
class XmlConverterPlugin extends GenericPlugin
{
	/**
	 * Register the plugin and initialize its hooks and resources.
	 * 
	 * @copydoc GenericPlugin::register()
	 * 
	 * @param string $category		The category to register the plugin in.
	 * @param string $path			The path to the plugin.
     * @param mixed  $mainContextId The context ID, if applicable.
	 * 
	 * @return bool
     */
	public function register($category, $path, $mainContextId = null): bool
	{
		$success = parent::register($category, $path, $mainContextId);

		if ($success && $this->getEnabled()) {
			// Check if Java is available on the system
			$javaChecker = exec('command java --version >/dev/null && echo "yes" || echo "no"');
		
			if ('yes' == $javaChecker) {
				// Add hooks for custom handler and template processing
				Hook::add('LoadHandler', [$this, 'callbackLoadHandler']);
				Hook::add('TemplateManager::fetch', [$this, 'templateFetchCallback']);

				// Register additional template resources
				$this->_registerTemplateResource();
			}
		}

		return $success;
	}

	/**
	 * Load a custom handler for specific page requests.
	 * 
	 * @param string $hookName Name of the hook being triggered.
	 * @param array  $args	   Arguments passed to the hook.
	 * 
	 * @return bool
	 */
	public function callbackLoadHandler(string $hookName, array $args): bool
	{
		$page = $args[0];
		$operator = $args[1];

		 // Check if the requested page and operator match allowed conversions
		if (in_array($page, static::getAllowedConversions()) && 'convert' == $operator) {
			define('HANDLER_CLASS', XmlConverterHandler::class);

			return true;
		}

		return false;
	}

	/**
	 * Modify template output before rendering in an AJAX request.
	 * 
	 * @param string $hookName Name of the hook being triggered.
	 * @param array  $params   Parameters passed to the hook.
	 * 
	 * @return void
	 */
	public function templateFetchCallback(string $hookName, array $params): void
	{
		$request = $this->getRequest();
		$dispatcher = $request->getDispatcher();

		$resourceName = $params[1];

		if ('controllers/grid/gridRow.tpl' == $resourceName) {
			$templateManager = TemplateManager::getManager($request);

			/** @var GridRow $row */
			$row = $templateManager->getTemplateVars('row');
			$data = $row->getData();

			if (is_array($data) && isset($data['submissionFile'])) {
				// Ensure that the conversion is run on the appropriate workflow stage
				$submissionFile = $data['submissionFile'];
				$submissionId = $submissionFile->getData('submissionId');
				$submission = Repo::submission()->get($submissionId);
				$submissionStageId = $submission->getData('stageId');
				
				// Check user roles for access permissions
				$roles = $request->getUser()->getRoles($request->getContext()->getId());
				$accessAllowed = false;
				foreach ($roles as $role) {
					if (in_array($role->getId(), [Role::ROLE_ID_MANAGER, Role::ROLE_ID_SUB_EDITOR, Role::ROLE_ID_ASSISTANT, Role::ROLE_ID_SITE_ADMIN])) {
						$accessAllowed = true;
						
						break;
					}
				}

				// Verify workflow stage and file type compatibility
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

					// Add conversion actions to the grid row
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
								__("plugins.generic.xmlConverter.button.$conversion")
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
	 * @param PKPRequest $request The current request object.
	 * 
	 * @return string
	 */
	public function getPluginUrl(PKPRequest $request): string
	{
		return $request->getBaseUrl() . '/' . $this->getPluginPath();
	}

	/**
	 * Get the display name of the plugin.
	 * The name will appear in the Plugin Gallery where editors can install, enable and disable plugins.
	 * 
	 * @return string
	 */
	public function getDisplayName(): string
	{
		return __('plugins.generic.xmlConverter.displayName');
	}

	/**
	 * Get the description of the plugin.
	 * The name will appear in the Plugin Gallery where editors can install, enable and disable plugins.
	 * 
	 * @return string
	 */
	public function getDescription(): string
	{
		return __('plugins.generic.xmlConverter.description');
	}

	/**
	 * Get the list of allowed conversions.
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
	 * Get the list of supported MIME types for conversion.
	 * 
	 * @return array
	 */
	public static function getSupportedMimetypes(): array
	{
		return [
			'text/xml',
			'application/xml',
		];
	}

	/**
	 * Get the list of allowed workflow stage IDs.
	 * 
	 * @return array
	 */
	public function getAllowedWorkflowStages(): array
	{
		return [
			WORKFLOW_STAGE_ID_EDITING,
			WORKFLOW_STAGE_ID_PRODUCTION,
		];
	}
}

if (!PKP_STRICT_MODE) {
	// Allow legacy aliasing for backward compatibility
    class_alias('\APP\plugins\generic\xmlConverter\XmlConverterPlugin', '\XmlConverterPlugin');
}

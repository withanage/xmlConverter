<?php

import('classes.handler.Handler');


class TeiToJatsHandler extends Handler
{
	protected object $plugin;

	protected array $allowedMethods = [ 'convert'];

	function __construct()
	{
		parent::__construct();

		$this->plugin = PluginRegistry::getPlugin('generic', LATEX_CONVERTER_PLUGIN_NAME);
		$this->addRoleAssignment([ROLE_ID_MANAGER, ROLE_ID_SUB_EDITOR, ROLE_ID_ASSISTANT,ROLE_ID_SITE_ADMIN],['convert']);
	}

	function authorize($request, &$args, $roleAssignments): bool
	{
		import('lib.pkp.classes.security.authorization.WorkflowStageAccessPolicy');
		$this->addPolicy(new WorkflowStageAccessPolicy($request, $args, $roleAssignments,
			'submissionId', (int)$request->getUserVar('stageId')));
		return parent::authorize($request, $args, $roleAssignments);
	}

	public function extractExecute($args, $request): JSONMessage
	{
		$action = new Extract($this->plugin, $request, $args);

		$action->readInputData();

		$action->process();

		return $request->redirectUrlJson($request->getDispatcher()->url($request, ROUTE_PAGE, null, 'workflow', 'access', null,
			array(
				'submissionId' => $request->getUserVar('submissionId'),
				'stageId' => $request->getUserVar('stageId')
			)
		));
	}

	/**
	 * Converts LaTex file to pdf
	 * @param $args
	 * @param $request
	 * @return JSONMessage
	 */
	public function convert($args, $request): JSONMessage
	{
		$fileId = (int) $request->getUserVar('fileId');
		$submissionFiles = Services::get('submissionFile')->getMany([
			'fileIds' => [$fileId],
		]);
		$submissionFile = $submissionFiles->current();

		$fileManager = new PrivateFileManager();
		$filePath = $fileManager->getBasePath() . '/' . $submissionFile->getData('path');

	}
}


<?php

namespace APP\plugins\generic\teitojats\handlers;

use APP\core\Services;
use APP\facades\Repo;
use APP\handler\Handler;
use APP\plugins\generic\teitojats\TeiToJatsPlugin;
use PKP\core\Core;
use PKP\core\JSONMessage;
use PKP\file\PrivateFileManager;
use PKP\plugins\PluginRegistry;
use PKP\security\authorization\WorkflowStageAccessPolicy;
use PKP\security\Role;

class TeiToJatsHandler extends Handler
{
	/** @var TeiToJatsPlugin $plugin */
	protected TeiToJatsPlugin $plugin;

	/** @var array $allowedMethods */
	protected array $allowedMethods = ['convert'];

	/**
	 * Constructor.
	 * 
	 * @return void
	 */
	public function __construct()
	{
		parent::__construct();

		$this->plugin = PluginRegistry::getPlugin('generic', 'teitojatsplugin');
		$this->addRoleAssignment([Role::ROLE_ID_MANAGER, Role::ROLE_ID_SUB_EDITOR, Role::ROLE_ID_ASSISTANT, Role::ROLE_ID_SITE_ADMIN], $this->allowedMethods);
	}

	/**
	 * Authorize the request.
	 * 
	 * @param PKPRequest $request
	 * @param array		 $args
	 * @param array	     $roleAssignments
	 * 
	 * @return bool
	 */
	public function authorize($request, &$args, $roleAssignments): bool
	{
		$this->addPolicy(new WorkflowStageAccessPolicy($request, $args, $roleAssignments, 'submissionId', (int)$request->getUserVar('stageId')));

		return parent::authorize($request, $args, $roleAssignments);
	}

	/**
	 * Convert.
	 * 
	 * @param array 	 $args
	 * @param PKPRequest $request
	 * 
	 */
	public function convert($args, $request): JSONMessage
	{
		/* Get informations of the file to convert */
		$fileId = (int)$request->getUserVar('fileId');
		$submissionFile = Repo::submissionFile()
			->getCollector()
			->filterByFileIds([$fileId])
			->getMany()
			->getIterator()
			->current()
		;
		$fileName = $submissionFile->getData('name');
		$genreId = $submissionFile->getData('genreId');
		$locale = $submissionFile->getData('locale');
		$submissionId = $submissionFile->getData('submissionId');
		$submission = Repo::submission()->get($submissionId);
		$contextId = $submission->getData('contextId');
		$fileManager = new PrivateFileManager();
		$filePath = $fileManager->getBasePath() . '/' . $submissionFile->getData('path');
		$pluginPath = Core::getBaseDir() . '/' . $this->plugin->getPluginPath();		

		/* Convert the file TEI-Commons to JATS-Publishing */
		$newFile = tempnam(sys_get_temp_dir(), 'teiToJats');
		$command = "cd $pluginPath && java -jar $pluginPath/bin/saxon-he-10.6.jar $filePath $pluginPath/xslt/TEI-Commons_to_JATS-Publishing.xsl -o:$newFile";
		shell_exec($command);

		/* Add new JATS XML file */
		$newSubmissionFile = Repo::submissionFile()->dao->newDataObject();
		$newName = [];
		if (is_array($fileName)) {
			foreach ($fileName as $localeKey => $name) {
				$newName[$localeKey] = pathinfo($name)['filename'] . '-jats.xml';
			}
		} else {
			$newName[$locale] = pathinfo($fileName)['filename'] . '-jats.xml';
		}

		$submissionDir = Repo::submissionFile()->getSubmissionDir($contextId, $submissionId);
		$newFileId = Services::get('file')->add($newFile, $submissionDir . DIRECTORY_SEPARATOR . uniqid() . '.xml');
		$newSubmissionFile->setAllData([
			'fileId' => $newFileId,
			'assocType' => $submissionFile->getData('assocType'),
			'assocId' => $submissionFile->getData('assocId'),
			'fileStage' => $submissionFile->getData('fileStage'),
			'mimetype' => 'application/xml',
			'locale' => $locale,
			'genreId' => $genreId,
			'name' => $newName,
			'submissionId' => $submissionId,
		]);
		$newSubmissionFile = Repo::submissionFile()->add($newSubmissionFile, $request);

		return new JSONMessage(true);
	}
}

if (!PKP_STRICT_MODE) {
    class_alias('\APP\plugins\generic\teitojats\handlers\TeiToJatsHandler', '\TeiToJatsHandler');
}

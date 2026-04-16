/**
 * @file plugins/generic/xmlConverter/resources/js/main-default.js
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2026 John Willinsky
 * Distributed under the GNU GPL v3. For full terms see the file docs/COPYING.
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Vite main file
 */
import CreateGalleyModal from './Components/CreateGalleyModal.vue';
import AddExternalFileModal from './Components/AddExternalFileModal.vue';

pkp.registry.registerComponent('CreateGalleyModal', CreateGalleyModal);
pkp.registry.registerComponent('AddExternalFileModal', AddExternalFileModal);

pkp.registry.storeExtend(
	'fileManager_PRODUCTION_READY_FILES',
	(piniaContext) => {
		const dashboardStore = pkp.registry.getPiniaStore('dashboard');
		const fileStore = piniaContext.store;

		if (
			dashboardStore.dashboardPage !== 'editorialDashboard' ||
			fileStore.props.submissionStageId !==
			pkp.const.WORKFLOW_STAGE_ID_PRODUCTION
		) {
			return;
		}

		const {useModal} = pkp.modules.useModal;
		const {useLocalize} = pkp.modules.useLocalize;
		const {useUrl} = pkp.modules.useUrl;
		const {useDataChanged} = pkp.modules.useDataChanged;

		const {openSideModal} = useModal();
		const {t, localize} = useLocalize();
		const {triggerDataChange} = useDataChanged();

		function dataUpdateCallback() {
			triggerDataChange();
		}

		const {submission} = fileStore.props;

		fileStore['addExternalFileAction'] = function (args) {
			openSideModal(AddExternalFileModal, {
				url: args.url,
				onClose: dataUpdateCallback,
			});
		};

		fileStore.extender.extendFn('getTopItems', (topItems, args) => {
			let newItems = topItems;
			const {apiUrl} = useUrl(
				`submissions/xmlConverter/createServiceFile/${submission.id}`
			);
			newItems.unshift({
				component: 'FileManagerActionButton',
				props: {
					label: t('plugins.generic.xmlConverter.createServiceFile.addFile'),
					name: 'addExternalFile',
					action: 'addExternalFileAction',
					actionArgs: {
						url: apiUrl.value,
						onClose: dataUpdateCallback
					}
				}
			});
			return newItems;
		});

		fileStore.extender.extendFn('getItemActions', (itemActions, args) => {
			const localizedName = localize(args.file.name);
			if (!localizedName.endsWith('.xml')) {
				return itemActions;
			}

			let newActions = itemActions;
			newActions.push({
				label: t('plugins.generic.xmlConverter.links.createGalley'),
				name: 'createGalley',
				icon: 'FileText',
				actionFn: ({file}) => {
					const {apiUrl} = useUrl(
						`submissions/xmlConverter/createGalley/${file.submissionId}/${file.id}`
					);
					openSideModal(CreateGalleyModal, {
						url: apiUrl.value,
						onClose: dataUpdateCallback
					});
				}
			});
			return newActions;
		});
	},
);

/*
// This is needed for extracting localised texts by the plugin i18nExtractKeys
const localeKeys = [
	// common
	t("common.cancel"),
	t("common.language"),
	t("common.save"),
	t("common.type"),
	t("submission.layout.galleyLabel"),
	t("submission.layout.galleyLabelInstructions"),
	t("submission.layout.newGalley"),
	t("validator.required"),

	// default
	t("plugins.generic.xmlConverter.createGalley.createArticleMetaHistory"),
	t("plugins.generic.xmlConverter.createGalley.createArticleMetaLicense"),
	t("plugins.generic.xmlConverter.createGalley.customModifications"),
	t("plugins.generic.xmlConverter.createGalley.datePublished"),
	t("plugins.generic.xmlConverter.createGalley.firstPage"),
	t("plugins.generic.xmlConverter.createGalley.createJournalMeta"),
	t("plugins.generic.xmlConverter.createGalley.lastPage"),
	t("plugins.generic.xmlConverter.createServiceFile.addFile"),
	t("plugins.generic.xmlConverter.createServiceFile.file.description"),
	t("plugins.generic.xmlConverter.createServiceFile.file.name"),
	t("plugins.generic.xmlConverter.createServiceFile.orkg"),
	t("plugins.generic.xmlConverter.createServiceFile.upload"),
	t("plugins.generic.xmlConverter.links.createGalley"),

	// conversions
	t("plugins.generic.xmlConverter.button.jatsToTei"),
	t("plugins.generic.xmlConverter.button.jatsToTei.dialog"),
	t("plugins.generic.xmlConverter.button.teiToJats"),
	t("plugins.generic.xmlConverter.button.teiToJats.dialog"),
	t("plugins.generic.xmlConverter.mimetypeError.message"),
	t("plugins.generic.xmlConverter.mimetypeError.title"
];
*/

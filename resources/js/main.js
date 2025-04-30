// File manager extensions
const {useLocalize} = pkp.modules.useLocalize;
const {useModal} = pkp.modules.useModal;
const {useFetch} = pkp.modules.useFetch;
const {useUrl} = pkp.modules.useUrl;
const {openDialog} = useModal();
const {t, localize, localizeSubmission} = useLocalize();

const getSupportedMimetypes = ['text/xml', 'application/xml']; //this plugin only support this formats
pkp.registry.storeExtendFn(
	'fileManager_FINAL_DRAFT_FILES',
	'getItemActions',
	(originalResult, args) => {
		return [
			...originalResult,
			{
				label: t('plugins.generic.xmlConverter.button.teiToJats'), // convert TEI file to JATS
				name: 'teiToJats',
				icon: 'FileExcel',
				actionFn: async ({file}) => {
					if (getSupportedMimetypes.includes(file.mimetype)) {
						const {apiUrl: xmlCovertUrl} = useUrl(
							`submissions/file/teiToJats/convert`,
						);
						const {data, isLoading, fetch} = useFetch(xmlCovertUrl, {
							query: {
								fileId: file.fileId,
							},
						});
						await fetch();
						if(data.value){
							window.location.reload(); // reload for reflect data changes
						}
					} else {
						commonMimetypeErrorModal();
					}
				},
			},
			{
				label: t('plugins.generic.xmlConverter.button.jatsToTei'), //convert JATS file to TEI
				name: 'jatsToTei',
				icon: 'FileExcel',
				actionFn: async ({file}) => {
					if (getSupportedMimetypes.includes(file.mimetype)) {
						const {useFetch} = pkp.modules.useFetch;
						const {useUrl} = pkp.modules.useUrl;

						const {apiUrl: xmlCovertUrl} = useUrl(
							`submissions/file/jatsToTei/convert`,
						);
						const {data, isLoading, fetch} = useFetch(xmlCovertUrl, {
							query: {
								fileId: file.fileId,
							},
						});
						await fetch();
						if(data.value){
							window.location.reload(); // reload for reflect data changes
						}
					} else {
						commonMimetypeErrorModal(); // handle mimetype error
					}
				},
			},
		];
	},
);

/**
 * show error popup for incorrect mimetypes
 * conversions
 */
function commonMimetypeErrorModal() {
	openDialog({
		title: t('plugins.generic.xmlConverter.mimetypeError.title'),
		message: t('plugins.generic.xmlConverter.mimetypeError.message'),
		actions: [
			{
				label: 'Close',
				isWarnable: true,
				callback: (close) => {
					close();
				},
			},
		],
		modalStyle: 'negative',
	});
}

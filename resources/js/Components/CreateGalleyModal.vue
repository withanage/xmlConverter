<template>
	<PkpSideModalBody>
		<template #title>
			{{ t('submission.layout.newGalley') }}
		</template>
		<PkpSideModalLayoutBasic>
			<PkpFieldText
				:allErrors="errors"
				:isRequired="true"
				:label="t('submission.layout.galleyLabel')"
				:description="t('submission.layout.galleyLabelInstructions')"
				:value="currentValue.label"
				class="mb-8"
				component="field-text"
				formId="default"
				groupId="createGalley"
				inputType="text"
				name="label"
				@change="
					(fieldName, propName, newValue, localeKey) =>
						updateCurrentValueData(fieldName, newValue)
				"
			/>
			<PkpFieldSelect
				:allErrors="errors"
				:isRequired="true"
				:label="t('common.language')"
				:options="galleyLocaleOptions"
				:value="currentValue.galleyLocale"
				class="mb-8"
				component="field-select"
				formId="default"
				groupId="createGalley"
				name="galleyLocale"
				@change="
					(fieldName, propName, newValue, localeKey) =>
						updateCurrentValueData(fieldName, newValue)
				"
			/>
			<PkpFieldOptions
				:allErrors="errors"
				:label="
					t('plugins.generic.xmlConverter.createGalley.customModifications')
				"
				:options="customModificationsOptions"
				:value="[]"
				class="mb-8"
				component="field-options"
				formId="default"
				groupId="createGalley"
				name="customModifications"
				type="checkbox"
				@change="
					(fieldName, propName, newValue, localeKey) =>
						updateCurrentValueData(fieldName, newValue)
				"
			/>
			<div class="mb-8">
				<div class="inline-flex pr-4">
					<PkpFieldText
						:allErrors="errors"
						:isRequired="false"
						:label="t('plugins.generic.xmlConverter.createGalley.firstPage')"
						:value="currentValue.createFirstPage"
						component="field-text"
						formId="default"
						groupId="createGalley"
						inputType="number"
						name="createFirstPage"
						@change="
							(fieldName, propName, newValue, localeKey) =>
								updateCurrentValueData(fieldName, newValue)
						"
					/>
				</div>
				<div class="inline-flex">
					<PkpFieldText
						:allErrors="errors"
						:isRequired="false"
						:label="t('plugins.generic.xmlConverter.createGalley.lastPage')"
						:value="currentValue.createLastPage"
						component="field-text"
						formId="default"
						groupId="createGalley"
						inputType="number"
						name="createLastPage"
						@change="
							(fieldName, propName, newValue, localeKey) =>
								updateCurrentValueData(fieldName, newValue)
						"
					/>
				</div>
			</div>
			<PkpFieldText
				:allErrors="errors"
				:isRequired="true"
				:label="t('plugins.generic.xmlConverter.createGalley.datePublished')"
				:value="currentValue.datePublished"
				class="mb-8"
				component="field-text"
				formId="default"
				groupId="createGalley"
				inputType="date"
				name="createDatePublished"
				@change="
					(fieldName, propName, newValue, localeKey) =>
						updateCurrentValueData(fieldName, newValue)
				"
			/>
			<div>
				<PkpButton @click="handleSubmit">{{ t('common.save') }}</PkpButton>
				&nbsp;
				<PkpButton @click="handleCancel">{{ t('common.cancel') }}</PkpButton>
			</div>
		</PkpSideModalLayoutBasic>
	</PkpSideModalBody>
</template>

<script setup>
import {inject, ref} from 'vue';

const {useFetch} = pkp.modules.useFetch;
const {useLocalize} = pkp.modules.useLocalize;
const {t} = useLocalize();

const emit = defineEmits(['close']);
const errors = ref({});
const closeModal = inject('closeModal');

const props = defineProps({
	url: {type: String, required: true},
	onClose: {type: Function, required: true}
});

const currentValue = ref({
	label: '',
	galleyLocale: '',
	createJournalMeta: false,
	createArticleMetaLicense: false,
	createArticleMetaHistory: false,
	createFirstPage: '',
	createLastPage: '',
	createDatePublished: '',
});

const requiredFields = ['label', 'galleyLocale', 'createDatePublished'];

const galleyLocaleOptions = Object.entries(pkp.context.supportedLocales).map(
	([key, label]) => ({value: key, label: label})
);

const customModificationsOptions = ref([
	{
		value: 'createJournalMeta',
		label: t('plugins.generic.xmlConverter.createGalley.createJournalMeta')
	},
	{
		value: 'createArticleMetaLicense',
		label: t('plugins.generic.xmlConverter.createGalley.createArticleMetaLicense')
	},
	{
		value: 'createArticleMetaHistory',
		label: t('plugins.generic.xmlConverter.createGalley.createArticleMetaHistory')
	}
]);

function updateCurrentValueData(fieldName, newValue) {
	if (fieldName === 'customModifications') {
		customModificationsOptions.value.forEach((item) => {
			currentValue.value[item.value] = false;
		});
		newValue.forEach((item) => {
			currentValue.value[item] = true;
		});
	} else {
		currentValue.value[fieldName] = newValue;
	}
}

async function handleSubmit() {
	if (formErrorsFound()) {
		return;
	}

	const {fetch, data} = useFetch(props.url, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'X-Csrf-Token': pkp.currentUser.csrfToken,
		},
		body: currentValue.value
	});

	await fetch().then(() => {
		if (data.value['validationErrors']) {
			errors.value = data.value['validationErrors'];
		} else {
			emit('close');
			closeModal();
		}
	});
}

function handleCancel() {
	emit('close');
	closeModal();
}

function formErrorsFound() {
	let errorsFound = false;
	errors.value = {};
	Object.keys(currentValue.value).forEach((key) => {
		if (requiredFields.includes(key) && currentValue.value[key].length === 0) {
			errors.value[key] = [t('validator.required')];
			errorsFound = true;
		}
	});
	return errorsFound;
}
</script>

<style scoped>
.pr-4 {
	padding-right: 1rem;
}

.mb-8 {
	margin-bottom: 2rem;
}
</style>

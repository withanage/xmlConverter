<template>
	<PkpSideModalBody>
		<template #title>
			{{ t('plugins.generic.xmlConverter.createServiceFile.upload') }}
		</template>
		<PkpSideModalLayoutBasic>
			<PkpFieldText
				:allErrors="errors"
				:isRequired="true"
				:label="t('plugins.generic.xmlConverter.createServiceFile.file.name')"
				:description="t('plugins.generic.xmlConverter.createServiceFile.file.description')"
				:value="currentValue.serviceFile"
				class="mb-8"
				component="field-text"
				formId="default"
				groupId="addExternalFileForm"
				inputType="text"
				name="serviceFile"
				@change="
					(fieldName, propName, newValue, localeKey) =>
						updateCurrentValueData(fieldName, newValue)
				"
			/>
			<PkpFieldSelect
				:allErrors="errors"
				:isRequired="true"
				:label="t('common.type')"
				:options="serviceTypeOptions"
				:value="currentValue.serviceType"
				class="mb-8"
				component="field-select"
				formId="default"
				groupId="addExternalFileForm"
				name="serviceType"
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
				:value="currentValue.serviceFileLocale"
				class="mb-8"
				component="field-select"
				formId="default"
				groupId="addExternalFileForm"
				name="serviceFileLocale"
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
	serviceFile: '',
	serviceType: '',
	serviceFileLocale: '',
});

const requiredFields = ['serviceFile', 'serviceType', 'serviceFileLocale'];

const galleyLocaleOptions = Object.entries(pkp.context.supportedLocales).map(
	([key, label]) => ({value: key, label: label})
);

const serviceTypeOptions = [{
	value: 'orkg',
	label: t('plugins.generic.xmlConverter.createServiceFile.orkg')
}];

function updateCurrentValueData(fieldName, newValue) {
	currentValue.value[fieldName] = newValue;
}

const handleSubmit = async () => {
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
};

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
.mb-8 {
	margin-bottom: 2rem;
}
</style>

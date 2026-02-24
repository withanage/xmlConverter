/**
 * @file plugins/generic/xmlConverter/vite.config.default.js
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2025 John Willinsky
 * Distributed under the GNU GPL v3. For full terms see the file docs/COPYING.
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Vite configuration
 */

import {resolve} from 'path';
import {defineConfig} from 'vite';
import vue from '@vitejs/plugin-vue';
import i18nExtractKeys from './lib/i18nExtractKeys.vite.js';

export default defineConfig({
	target: 'es2016',
	plugins: [i18nExtractKeys(), vue()],
	build: {
		lib: {
			entry: resolve(__dirname, 'resources/js/main-default.js'),
			name: 'XmlConverterDefault',
			fileName: 'build-default',
			formats: ['iife'],
		},
		outDir: resolve(__dirname, 'public/build'),
		rollupOptions: {
			external: ['vue'],
			output: {
				globals: {
					vue: 'pkp.modules.vue',
				},
			},
		},
	},
});

<?php

/**
 * @file plugins/generic/xmlConverter/XmlConverterPlugin.php
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2026 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class XmlConverterPlugin
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief This plugin provides XML conversion capabilities within the application.
 * It supports specific file conversions (e.g., TEI to Jats and Jats to TEI)
 * and integrates into the application's workflow through hooks and custom handlers.
 */

namespace APP\plugins\generic\xmlConverter;

use APP\core\Application;
use APP\core\Request;
use APP\plugins\generic\xmlConverter\classes\PluginApiHandler;
use APP\template\TemplateManager;
use PKP\plugins\GenericPlugin;
use PKP\plugins\Hook;

class XmlConverterPlugin extends GenericPlugin
{
    public const PLUGIN_URL = 'xmlConverter';

    public const DAR_MANIFEST_FILE = 'manifest.xml';
    public const DAR_MANUSCRIPT_FILE = 'manuscript.xml';

    public const FILE_TYPE_DAR = 'dar';
    public const FILE_TYPE_ZIP = 'zip';
    public const FILE_TYPE_HTML = 'html';

    /**
     * @copydoc GenericPlugin::register()
     */
    public function register($category, $path, $mainContextId = null): bool
    {
        if (parent::register($category, $path, $mainContextId)) {
            if ($this->getEnabled()) {
                $request = Application::get()->getRequest();
                $templateMgr = TemplateManager::getManager($request);
                $apiController = new PluginApiHandler($this);

                Hook::add('APIHandler::endpoints::submissions', $apiController->addRouteDefault(...));
                $this->addResourcesDefault($request, $templateMgr);

                // Execute only if Java is installed
                if ('yes' === exec('command java --version >/dev/null && echo "yes" || echo "no"')) {
                    Hook::add('APIHandler::endpoints::submissions', $apiController->addRouteConversions(...));
                    $this->addResourcesConversions($request, $templateMgr);
                }
            }
            return true;
        }
        return false;
    }

    /**
     * @copydoc Plugin::getDisplayName
     */
    public function getDisplayName(): string
    {
        return __('plugins.generic.xmlConverter.displayName');
    }

    /**
     * @copydoc Plugin::getDescription
     */
    public function getDescription(): string
    {
        return __('plugins.generic.xmlConverter.description');
    }

    /**
     * Adds JavaScript and CSS resources for the default feature set.
     */
    public function addResourcesDefault(Request $request, TemplateManager $templateMgr): void
    {
        $templateMgr->addJavaScript(
            'XmlConverterDefaultJs',
            "{$request->getBaseUrl()}/{$this->getPluginPath()}/public/build/build-default.iife.js",
            [
                'inline' => false,
                'contexts' => ['backend'],
                'priority' => TemplateManager::STYLE_SEQUENCE_LAST
            ]
        );

        $templateMgr->addStyleSheet('XmlConverterStyle',
            "{$request->getBaseUrl()}/{$this->getPluginPath()}/public/build/build-default.css",
            [
                'contexts' => ['backend']
            ]
        );
    }

    /**
     * Adds JavaScript and CSS resources for the conversion feature set with Java requirement.
     */
    public function addResourcesConversions(Request $request, TemplateManager $templateMgr): void
    {
        $templateMgr->addJavaScript(
            'XmlConverterConversionsJs',
            "{$request->getBaseUrl()}/{$this->getPluginPath()}/public/build/build-conversions.iife.js",
            [
                'inline' => false,
                'contexts' => ['backend'],
                'priority' => TemplateManager::STYLE_SEQUENCE_LAST
            ]
        );
    }
}

// For backwards compatibility -- expect this to be removed approx. OJS/OMP/OPS 3.6
if (!PKP_STRICT_MODE) {
    class_alias('\APP\plugins\generic\xmlConverter\XmlConverterPlugin', '\XmlConverterPlugin');
}

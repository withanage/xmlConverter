<?php

import('lib.pkp.classes.plugins.GenericPlugin');

class Tei2JatsPlugin extends GenericPlugin
{
    public function register($category, $path, $mainContextId = NULL)
	{
        $success = parent::register($category, $path);

        if ($success && $this->getEnabled()) {
        }

        return $success;
    }

    /**
     * Provide a name for this plugin
     *
     * The name will appear in the Plugin Gallery where editors can
     * install, enable and disable plugins.
     */
    public function getDisplayName()
	{
		return __('plugins.generic.tei2Jats.displayName');
    }

    /**
     * Provide a description for this plugin
     *
     * The description will appear in the Plugin Gallery where editors can
     * install, enable and disable plugins.
     */
    public function getDescription()
	{
		return __('plugins.generic.tei2Jats.description');
    }
}

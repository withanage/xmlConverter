<?php

/**
 * @file plugins/generic/xmlConverter/classes/helpers/XMLAmpersandEscaper.php
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2026 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class XMLAmpersandEscaper
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Helper XMLAmpersandEscaper
 */

namespace APP\plugins\generic\xmlConverter\classes\helpers;

use DOMDocument;

class XMLAmpersandEscaper
{
	private const UNESCAPED_AMPERSAND_PATTERN = '/&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/';

    /**
     * Escapes unescaped ampersands in the given content by converting them to '&amp;'.
     */
    public static function escapeAmpersands(string $content): string
	{
		if (empty($content)) {
			return $content;
		}

		return preg_replace_callback(
			self::UNESCAPED_AMPERSAND_PATTERN,
			function ($matches) {
				return '&amp;';
			},
			$content
		);
	}

    /**
     * Validates if a given XML content properly handles ampersands and other XML-specific characters.
     */
    public static function validateXmlAmpersands(string $content): bool
	{
		if (empty($content)) {
			return true;
		}

		$previousError = libxml_use_internal_errors(true);

		$dom = new DOMDocument();
		$success = $dom->loadXML($content);

		libxml_use_internal_errors($previousError);

		return $success;
	}

    /**
     * Attempts to fix invalid XML ampersands in the given content and validates the result.
     */
    public static function fixAndValidate(string $content): array
	{
		$originalValid = self::validateXmlAmpersands($content);

		if ($originalValid) {
			return [
				'content' => $content,
				'valid' => true,
				'original_valid' => true,
				'fixed' => false
			];
		}

		$fixedContent = self::escapeAmpersands($content);
		$fixedValid = self::validateXmlAmpersands($fixedContent);

		return [
			'content' => $fixedContent,
			'valid' => $fixedValid,
			'original_valid' => false,
			'fixed' => true
		];
	}
}

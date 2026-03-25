<?php

/**
 * @file plugins/generic/xmlConverter/classes/models/OrkgServiceFile.php
 *
 * Copyright (c) 2014-2025 Simon Fraser University
 * Copyright (c) 2003-2025 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class OrkgServiceFile
 *
 * @ingroup plugins_generic_xmlconverter
 *
 * @brief Service File class for OrkgServiceFile
 */

namespace APP\plugins\generic\xmlConverter\classes\models;

use APP\plugins\generic\xmlConverter\classes\helpers\JatsHeader;
use APP\plugins\generic\xmlConverter\classes\helpers\XMLAmpersandEscaper;
use Exception;
use InvalidArgumentException;
use RuntimeException;

class OrkgServiceFile extends AbstractServiceFile
{
    private const ORKG_EXPORT_URL = 'https://orkg.org/simcomp/thing/export';
    private const MIME_TYPE = 'text/xml';
    private string $fileType = 'xml';

    public function setAdditionalFileMetadata(array &$metadata): void
    {
        $metadata['mimetype'] = self::MIME_TYPE;
        $metadata['name'] = [
            parent::getServiceFileLocale() => parent::getServiceFile() . '.' . $this->getFileType()
        ];
    }

    public function modifyContent(string &$content): void
    {
        $content = XMLAmpersandEscaper::escapeAmpersands($content);

        try {
            $processor = new JatsHeader($content);
            $content = $processor->process();
        } catch (Exception $e) {
            echo "Error: " . $e->getMessage();
        }
    }

    public function cleanServiceFilePath(&$serviceFile): string
    {
        $serviceFile = trim($serviceFile);

        if (empty($serviceFile)) {
            $this->handle404('Empty file path provided.');
        }

        if (filter_var($serviceFile, FILTER_VALIDATE_URL)) {
            $path = parse_url($serviceFile, PHP_URL_PATH);

            if ($path === null) {
                $this->handle404('Invalid URL path: ' . $serviceFile);
            }

            $parts = explode('/', trim($path, '/'));
            $lastPart = end($parts);

            if (preg_match('/^R\d+$/', $lastPart)) {
                return $lastPart;
            }

            $this->handle404($serviceFile . ' is not a valid OrkgServiceFile R-number.');
        }

        return $serviceFile;
    }

    protected function downloadServiceFile(): string
    {
        $queryParams = http_build_query([
            'format' => strtoupper($this->getFileType()),
            'thing_key' => parent::getServiceFile(),
            'thing_type' => 'REVIEW',
        ]);

        $tempFile = parent::createTempFilePath();
        $downloadUrl = self::ORKG_EXPORT_URL . '?' . $queryParams;

        if (!$this->downloadFile($downloadUrl, $tempFile)) {
            throw new RuntimeException('Failed to download file from OrkgServiceFile service');
        }

        return $tempFile;
    }

    public function getFileType(): string
    {
        return $this->fileType;
    }

    protected function validateDownloadedFile(string $filePath): void
    {
        if (!file_exists($filePath) || filesize($filePath) === 0) {
            throw new RuntimeException('Downloaded file is invalid or empty');
        }

        if (@simplexml_load_file($filePath) === false) {
            throw new RuntimeException('Downloaded file is not valid XML');
        }
    }

    protected function validateServiceFileId(): void
    {
        $serviceFile = parent::getServiceFile();
        if (!$serviceFile || !preg_match('/^[a-zA-Z0-9_-]+$/', $serviceFile)) {
            throw new InvalidArgumentException('Invalid service file identifier');
        }
    }
}

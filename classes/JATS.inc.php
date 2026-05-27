<?php

/**
 * @file plugins/generic/xmlConverter/classes/JATS.inc.php
 *
 * Copyright (c) 2014-2019 Simon Fraser University
 * Copyright (c) 2003-2019 John Willinsky
 * Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
 *
 * @class JATS
 *
 * @brief JATS XML metadata manipulation class
 */

class JATS extends \DOMDocument
{

    public static function getJournalMeta(DOMDocument $origDocument, $context): void
    {
        $xpath = new DOMXpath($origDocument);

        foreach ($xpath->query("//article/front/journal-meta") ?: [] as $existing) {
            $existing->parentNode->removeChild($existing);
        }

        $articleMeta = $xpath->query("//article/front/article-meta")->item(0);
        if (!$articleMeta || !$context) return;

        $journalId     = trim((string)$context->getLocalizedAcronym());
        $issnValue     = trim((string)$context->getData('onlineIssn'));
        $publisherName = trim((string)$context->getData('publisherInstitution'));
        $journalTitle  = trim((string)$context->getLocalizedName());
        if ($journalId === '' && $issnValue === '' && $publisherName === '' && $journalTitle === '') return;

        $journalMeta = $origDocument->createElement('journal-meta');
        if ($journalId !== '') {
            $jid = $origDocument->createElement('journal-id', $journalId);
            $jid->setAttribute('journal-id-type', 'publisher-id');
            $journalMeta->appendChild($jid);
        }
        if ($journalTitle !== '') {
            $titleGroup = $origDocument->createElement('journal-title-group');
            $titleGroup->appendChild($origDocument->createElement('journal-title', htmlspecialchars($journalTitle, ENT_XML1)));
            $journalMeta->appendChild($titleGroup);
        }
        if ($issnValue !== '') {
            $issn = $origDocument->createElement('issn', $issnValue);
            $issn->setAttribute('pub-type', 'epub');
            $journalMeta->appendChild($issn);
        }
        if ($publisherName !== '') {
            $publisher = $origDocument->createElement('publisher');
            $publisher->appendChild($origDocument->createElement('publisher-name', $publisherName));
            $journalMeta->appendChild($publisher);
        }
        $articleMeta->parentNode->insertBefore($journalMeta, $articleMeta);
    }

    public static function getArticleTitle(DOMDocument $origDocument, Publication $publication): void
    {
        $title = trim((string)$publication->getLocalizedTitle());
        if ($title === '') return;

        $xpath = new DOMXpath($origDocument);
        $articleMeta = $xpath->query('//article/front/article-meta')->item(0);
        if (!$articleMeta) return;

        foreach ($xpath->query('./title-group', $articleMeta) ?: [] as $n) {
            $articleMeta->removeChild($n);
        }
        $tg = $origDocument->createElement('title-group');
        $tg->appendChild($origDocument->createElement('article-title', htmlspecialchars($title, ENT_XML1)));

        $contribGroup = $xpath->query('./contrib-group', $articleMeta)->item(0);
        if ($contribGroup) {
            $articleMeta->insertBefore($tg, $contribGroup);
        } else {
            $articleMeta->appendChild($tg);
        }
    }


    public static function getArticleMetaHistory(DOMDocument $origDocument, Submission $submission, $datePublished = null): void
    {

        $xpath = new DOMXpath($origDocument);

        $editDecisionDao = DAORegistry::getDAO('EditDecisionDAO');
        $history = $xpath->query("//article/front/article-meta/history");

        foreach ($history as $item) {
            $item->parentNode->removeChild($item);
        }
        $history = $origDocument->createElement('history');
        $dateReceived = $submission->getData('dateSubmitted');
        if ($dateReceived) {
            $dateReceived = self::getDate($origDocument, $dateReceived, 'received');
            $history->appendChild($dateReceived);
        }

        $dateAccepted = null;
        $decisions = $editDecisionDao->getEditorDecisions($submission->getId());
        foreach ($decisions as $decision) {
            if ($decision['stageId'] == WORKFLOW_STAGE_ID_EXTERNAL_REVIEW && $decision['decision'] == SUBMISSION_EDITOR_DECISION_ACCEPT)
                $dateAccepted = $decision['dateDecided'];
        }
        if ($dateAccepted) {
            $history->appendChild(self::getDate($origDocument, $dateAccepted, 'accepted'));
        }

        if ($datePublished) {
            $history->appendChild(self::getDate($origDocument, $datePublished, 'published'));
        }


        $articleMeta = $xpath->query("//article/front/article-meta");
        if ($articleMeta)
            $articleMeta->item(0)->appendChild($history);


    }


    public static function getJournalMetaPubDate(DOMDocument $origDocument, $context, $submission, $datePublished, $firstPage = null, $lastPage = null): void
    {
        $xpath = new DOMXpath($origDocument);
        $timestamp = strtotime($datePublished);

        $issueDao = DAORegistry::getDAO('IssueDAO');

        $pubDate = $xpath->query("//article/front/article-meta/pub-date");

        foreach ($pubDate as $item) {
            $item->parentNode->removeChild($item);
        }

        $pubDate = $origDocument->createElement('pub-date');
        $pubDate->setAttribute('pub-type', 'epub');
        $day = $origDocument->createElement('day', date('d', $timestamp));
        $pubDate->appendChild($day);
        $month = $origDocument->createElement('month', date('m', $timestamp));
        $pubDate->appendChild($month);
        $year = $origDocument->createElement('year', date('Y', $timestamp));
        $pubDate->appendChild($year);


        $issue = $issueDao->getBySubmissionId($submission->getId(), $context->getId());
        if ($issue) {
            $volume = $origDocument->createElement('volume', $issue->getVolume());
            $pubDate->appendChild($volume);
        }

        if ($firstPage) {
            $pubDate->appendChild($origDocument->createElement('fpage', $firstPage));
        }
        if ($lastPage) {
            $pubDate->appendChild($origDocument->createElement('lpage', $lastPage));
        }
        $articleMeta = $xpath->query("//article/front/article-meta");
        if ($articleMeta)
            $articleMeta->item(0)->appendChild($pubDate);


    }


    public static function getArticleMetaCCBYLicense(DOMDocument $origDocument, $context, $copyrightYear = null, $licenseUrlOverride = null): void
    {


        $xpath = new DOMXpath($origDocument);
        $permissions = $xpath->query("//article/front/article-meta/permissions");

        foreach ($permissions as $permission) {
            if ($permission->parentNode)
                $permission->parentNode->removeChild($permission);

        }


        $articleMeta = $xpath->query("//article/front/article-meta");
        $licenseUrl = ($licenseUrlOverride !== null && $licenseUrlOverride !== '')
            ? $licenseUrlOverride
            : $context->getData('licenseUrl');
        if (count($articleMeta) > 0 and $licenseUrl) {


            PKPString::regexp_match_get('/http[s]?:(www\.)?\/\/creativecommons.org\/licenses\/([a-z]+(-[a-z]+)*)\/(\d.0)\/*([a-z]*).*/i', $licenseUrl, $matches);
            if (count($matches) > 5 and $matches[2] and $matches[4]) {

                if (!$copyrightYear)
                    $copyrightYear = date('Y');

                $permissionNode = $origDocument->createElement('permissions');
                $copyrightStatementNode = $origDocument->createElement('copyright-statement', '© ' . $copyrightYear . ' The Author(s)');
                $permissionNode->appendChild($copyrightStatementNode);
                $copyrightYearNode = $origDocument->createElement('copyright-year', $copyrightYear);
                $permissionNode->appendChild($copyrightYearNode);

                $copyrightLicenseNode = $origDocument->createElement('license');
                $copyrightLicenseNode->setAttribute('license-type', 'open-access');
                $copyrightLicenseNode->setAttribute('xlink:href', $licenseUrl);
                $copyrightLicenseNode->setAttribute('xml:lang', 'en');

                $copyrightLicensePNode = $origDocument->createElement('license-p');

                $inlineGraphicNode = $origDocument->createElement('inline-graphic');
                $inlineGraphicNode->setAttribute('xlink:href', 'https://mirrors.creativecommons.org/presskit/buttons/88x31/svg/' . $matches[2] . '.svg');
                $copyrightLicensePNode->appendChild($inlineGraphicNode);

                $countryCode = $matches[5] ? strtoupper($matches[5]) : '';
                $isoCodes = new \Sokil\IsoCodes\IsoCodesFactory();
                $country = $isoCodes->getCountries()->getByAlpha2($countryCode) ? $isoCodes->getCountries()->getByAlpha2($countryCode)->getName() : '';
                $licensePTextNode = $origDocument->createTextNode("This work is published under the Creative Commons  {$country} License {$matches[4]} (CC BY {$matches[4]} {$countryCode}).");

                $copyrightLicensePNode->appendChild($licensePTextNode);
                $copyrightLicenseNode->appendChild($copyrightLicensePNode);
                $permissionNode->appendChild($copyrightLicenseNode);
                $articleMeta[0]->appendChild($permissionNode);
            }
        }

    }

    public static function getContribGroup(DOMDocument $origDocument, Publication $publication): void
    {
        $xpath = new DOMXpath($origDocument);
        $articleMeta = $xpath->query('//article/front/article-meta')->item(0);
        if (!$articleMeta) return;

        foreach ($xpath->query('./contrib-group | ./aff', $articleMeta) ?: [] as $n) {
            $articleMeta->removeChild($n);
        }

        $authors = $publication->getData('authors');
        if (!$authors || (is_countable($authors) && count($authors) === 0)) return;

        $locale = $publication->getData('locale') ?: AppLocale::getLocale();
        $cg = $origDocument->createElement('contrib-group');
        $cg->setAttribute('content-type', 'author');

        $affs = []; $affIndex = 1;
        foreach ($authors as $author) {
            $given  = (string)$author->getLocalizedGivenName($locale);
            $family = (string)$author->getLocalizedFamilyName($locale);
            $email  = (string)$author->getEmail();
            $orcid  = (string)$author->getOrcid();
            $aff    = (string)$author->getLocalizedAffiliation($locale);

            $c = $origDocument->createElement('contrib');
            $c->setAttribute('contrib-type', 'person');
            $name = $origDocument->createElement('name');
            if ($family !== '') $name->appendChild($origDocument->createElement('surname', htmlspecialchars($family, ENT_XML1)));
            if ($given !== '')  $name->appendChild($origDocument->createElement('given-names', htmlspecialchars($given, ENT_XML1)));
            $c->appendChild($name);
            if ($email !== '') $c->appendChild($origDocument->createElement('email', htmlspecialchars($email, ENT_XML1)));
            if ($orcid !== '') {
                $cid = $origDocument->createElement('contrib-id', htmlspecialchars($orcid, ENT_XML1));
                $cid->setAttribute('contrib-id-type', 'orcid');
                $c->appendChild($cid);
            }
            if ($aff !== '') {
                if (!isset($affs[$aff])) $affs[$aff] = 'aff-' . $affIndex++;
                $xref = $origDocument->createElement('xref');
                $xref->setAttribute('ref-type', 'aff');
                $xref->setAttribute('rid', $affs[$aff]);
                $c->appendChild($xref);
            }
            $cg->appendChild($c);
        }
        $articleMeta->appendChild($cg);

        foreach ($affs as $text => $id) {
            $a = $origDocument->createElement('aff');
            $a->setAttribute('id', $id);
            $a->appendChild($origDocument->createElement('institution', htmlspecialchars($text, ENT_XML1)));
            $articleMeta->appendChild($a);
        }
    }

    public static function getDate(\DOMDocument $origDocument, string $dateAndTime, $type = null): DOMElement
    {
        $timestamp = strtotime($dateAndTime);
        $date = $origDocument->createElement('date');
        if ($type)
            $date->setAttribute('type', $type);
        $date->setAttribute('iso-8601-date', date('Y-m-d', $timestamp));
        $day = $origDocument->createElement('day', date('d', $timestamp));
        $date->appendChild($day);
        $month = $origDocument->createElement('month', date('m', $timestamp));
        $date->appendChild($month);
        $year = $origDocument->createElement('year', date('Y', $timestamp));
        $date->appendChild($year);
        return $date;

    }
}

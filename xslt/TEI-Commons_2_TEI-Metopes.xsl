<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns:mml="http://www.w3.org/1998/Math/MathML"
		version="2.0"
		exclude-result-prefixes="tei xsl">

	<xsl:output method="xml" encoding="UTF-8" indent="no"/>


	<xsl:param name="output"/>

	<!-- PSEUDO-TABLEAUX ASSOCIATIFS -->
	<!-- les équivalences @rend -> @style pour la typo -->
	<xsl:variable name="typoRef">
		<style eq="bold">gras</style>
		<style eq="italic">Italique</style>
		<style eq="bold italic">italic_gras</style>
		<style eq="italic bold">italic_gras</style>
		<style eq="small-caps">SC</style>
		<style eq="small-caps-ital">SC_italic</style>
		<style eq="small-caps italic">SC_italic</style>
		<style eq="italic small-caps">SC_italic</style>
		<style eq="strikethrough">line-through</style>
		<style eq="sup">Exposant</style>
		<style eq="sup italic">Exposant_Italic</style>
		<style eq="italic sup">Exposant_Italic</style>
		<style eq="sub">Indice</style>
		<style eq="underline">souligne</style>
	</xsl:variable>

	<!-- les affiliations (pour mettre un pointeur dans le header) -->
	<xsl:variable name="listAffiliations">
		<xsl:for-each select="distinct-values(.//*:affiliation/*:orgName)">
			<orgRef n="{position()}">
				<xsl:value-of select="."/>
			</orgRef>
		</xsl:for-each>
	</xsl:variable>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:TEI">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="change" select="'metopes_edition'"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<!-- HEADER -->
	<xsl:template match="*:titleStmt">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
		<xsl:if test="not(following-sibling::*:editionStmt)">
			<editionStmt xmlns="http://www.tei-c.org/ns/1.0">
				<edition>
					<date>
						<xsl:value-of select="current-date()"/>
					</date>
				</edition>
			</editionStmt>
		</xsl:if>
	</xsl:template>

	<xsl:template match="*:titleStmt//*:title">
		<xsl:copy>
			<xsl:apply-templates select="@* except @type"/>
			<xsl:attribute name="type" select="if(@type='trl') then('alt') else(@type)"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:editor">
		<xsl:copy>
			<xsl:attribute name="role" select="if(not(@role) or @role='##') then('edt') else(@role)"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:titleStmt//*:persName">
		<name xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:value-of select="string-join(.//text(), ' ')"/>
		</name>
	</xsl:template>

	<xsl:template match="*:titleStmt//*:affiliation">
		<xsl:variable name="orgName" select="*:orgName"/>
		<xsl:variable name="orgRef">
			<xsl:if test="string-length($listAffiliations//*:orgRef[text()=$orgName]/@n) eq 1">
				<xsl:text>0</xsl:text>
			</xsl:if>
			<xsl:value-of select="$listAffiliations//*:orgRef[text()=$orgName]/@n"/>
		</xsl:variable>
		<xsl:copy>
			<ref xmlns="http://www.tei-c.org/ns/1.0" type="affiliation">
				<xsl:attribute name="target">
					<xsl:value-of select="'#aff'||$orgRef"/>
				</xsl:attribute>
			</ref>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:publicationStmt">
		<!-- voir exemple complet pour savoir quoi mettre -->
		<publicationStmt xmlns="http://www.tei-c.org/ns/1.0">
			<publisher></publisher>
			<ab type="papier">
				<dimensions>
					<dim type="pagination"></dim>
				</dimensions>
				<date></date>
			</ab>
			<idno type="book"></idno>
			<ab type="lodel">
				<date></date>
			</ab>
		</publicationStmt>
	</xsl:template>

	<xsl:template match="*:encodingDesc">
		<xsl:copy>
			<xsl:apply-templates select="*:tagsDecl|*:editorialDecl"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:listChange">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- FRONT -->
	<xsl:template match="*:front">
		<xsl:copy>
			<xsl:apply-templates select="*:div[@type='titlePage']"/>
			<xsl:if test="*:div[@type='abstract'] or *:div[@type='keywords']">
				<xsl:call-template name="resume_motscles"/>
			</xsl:if>
			<xsl:apply-templates select="*:note"/>
			<xsl:apply-templates select="*:argument"/>
			<xsl:apply-templates select="*:div[@type='inst-partner']"/>
			<xsl:if test="*:div[@type='data' or @type='publication']">
				<div xmlns="http://www.tei-c.org/ns/1.0" type="data">
					<xsl:if test="*:div[@type='data']">
						<xsl:for-each select="*:div[@type='data']/*:p">
							<p style="lien_donnees">
								<xsl:apply-templates select="node()"/>
							</p>
						</xsl:for-each>
					</xsl:if>
					<xsl:if test="*:div[@type='publication']">
						<xsl:for-each select="*:div[@type='publication']/*:p">
							<p style="lien_publications">
								<xsl:apply-templates select="node()"/>
							</p>
						</xsl:for-each>
					</xsl:if>
				</div>
			</xsl:if>
			<xsl:if test="*:div[@type='ack' or @type='dedication'] or *:epigraph">
				<div xmlns="http://www.tei-c.org/ns/1.0" type="prelim">
					<xsl:apply-templates select="*:epigraph"/>
					<xsl:if test="*:div[@type='dedication']">
						<xsl:for-each select="*:div[@type='dedication']/*:p">
							<p style="txt_dedicace">
								<xsl:apply-templates select="node()"/>
							</p>
						</xsl:for-each>
					</xsl:if>
					<xsl:if test="*:div[@type='ack']">
						<xsl:for-each select="*:div[@type='ack']/*:p">
							<p style="txt_remerciements">
								<xsl:apply-templates select="node()"/>
							</p>
						</xsl:for-each>
					</xsl:if>
				</div>
			</xsl:if>
		</xsl:copy>
	</xsl:template>

	<!-- FRONT: titlePage et titlePart -->
	<xsl:template match="*:div[@type='titlePage']">
		<titlePage xmlns="http://www.tei-c.org/ns/1.0">
			<docTitle>
				<xsl:apply-templates select="*:p[starts-with(@rend, 'title')]"/>
			</docTitle>
			<xsl:apply-templates select="*:p[not(starts-with(@rend, 'title'))]"/>
		</titlePage>
	</xsl:template>

	<xsl:template match="*:div[@type='titlePage']/*:p[starts-with(@rend, 'title')]">
		<xsl:variable name="type" select="substring-after(@rend, '-')"/>
		<titlePart xmlns="http://www.tei-c.org/ns/1.0">
			<!-- TODO: j’ai possiblement un attribut @style vide : WAD ? -->
			<xsl:attribute name="style" select="
				if($type='sup')
					then('T_Surtitre')
				else if($type='main')
					then('T_3_Article')
				else if($type='sub')
					then('T_SousTitre')
				else if($type='trl')
					then('T_0_Article_UK')
				else('')"/>
			<xsl:attribute name="type" select="if($type='trl') then('alt') else($type)"/>
			<xsl:apply-templates select="@* except @rend|node()"/>
		</titlePart>
	</xsl:template>

	<!-- TODO: c’est bien toujours "author-aut" ? Jamais "author-XXX" ?-->
	<xsl:template match="*:div[@type='titlePage']/*:p[@rend='author-aut']">
		<docAuthor style="txt_auteur" xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()"/>
		</docAuthor>
	</xsl:template>

	<xsl:template match="*:div[@type='titlePage']/*:p[not(starts-with(@rend, 'title')) and not(@rend='author-aut')]">
		<xsl:choose>
			<xsl:when test="@rend='authority_affiliation'">
				<xsl:variable name="orgName" select="text()"/>
				<xsl:variable name="orgRef">
					<xsl:if test="string-length($listAffiliations//*:orgRef[text()=$orgName]/@n) eq 1">
						<xsl:text>0</xsl:text>
					</xsl:if>
					<xsl:value-of select="$listAffiliations//*:orgRef[text()=$orgName]/@n"/>
				</xsl:variable>
				<byline style="auteur_Institution" xmlns="http://www.tei-c.org/ns/1.0">
					<affiliation xml:id="{'aff'||$orgRef}">
						<xsl:apply-templates select="node()"/>
					</affiliation>
				</byline>
			</xsl:when>
			<xsl:when test="@rend='authority_mail'">
				<byline style="auteur_Courriel" xmlns="http://www.tei-c.org/ns/1.0">
					<email>
						<xsl:choose>
							<xsl:when test="*:ref">
								<xsl:apply-templates select="*:ref"/>
							</xsl:when>
							<xsl:otherwise>
								<ref target="mailto:{text()}">
									<xsl:apply-templates select="node()"/>
								</ref>
							</xsl:otherwise>
						</xsl:choose>
					</email>
				</byline>
			</xsl:when>
			<xsl:when test="starts-with(@rend, 'editor')">
				<byline style="txt_collaborateur" xmlns="http://www.tei-c.org/ns/1.0">
					<xsl:apply-templates select="node()"/>
				</byline>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- FRONT: résumé et mots-clés -->
	<!-- vérifier que c’est nécessaire avec un front complet -->
	<xsl:template name="resume_motscles">
		<xsl:variable name="mainLang" select="substring-before(//*:langUsage/*:language/@ident, '-')"/>
		<div xmlns="http://www.tei-c.org/ns/1.0" type="resume_motscles">
			<xsl:for-each select="//*:div[@type='abstract' or @type='keywords']/*:p">
				<xsl:variable name="style">
					<xsl:value-of select="if(parent::*:div/@type='abstract') then('txt_Resume') else('txt_Motclef')"/><xsl:value-of
						select="if(parent::*:div/@xml:lang=$mainLang) then('') else('_italique')"/>
				</xsl:variable>
				<p style="{$style}" xml:lang="{parent::*:div/@xml:lang}">
					<xsl:apply-templates select="node()"/>
				</p>
			</xsl:for-each>
		</div>
	</xsl:template>

	<!-- FRONT: chapô-->
	<xsl:template match="*:argument">
		<xsl:copy>
			<xsl:for-each select="*:p">
				<p xmlns="http://www.tei-c.org/ns/1.0" style="txt_chapo">
					<xsl:apply-templates select="node()"/>
				</p>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>

	<!-- FRONT: partenaires -->
	<xsl:template match="*:div[@type='inst-partner']">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="partenaires">
			<xsl:for-each select="*:p">
				<p style="org_part">
					<xsl:apply-templates select="node()"/>
				</p>
			</xsl:for-each>
		</div>
	</xsl:template>


	<!-- BODY -->
	<xsl:template match="*:text/*:body">
		<xsl:copy>
			<div type="chapitre" xml:id="mainDiv" xmlns="http://www.tei-c.org/ns/1.0">
				<xsl:apply-templates/>
			</div>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:div/*:head">
		<xsl:variable name="level" select="substring-after(parent::*:div/@type, 'section')"/>
		<xsl:copy>
			<xsl:attribute name="style" select="'T_'||$level"/>
			<xsl:attribute name="subtype" select="'level'||$level"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>


	<!-- PARAGRAPHES, LISTES ET ENCADRÉS-->
	<!-- TODO: peut-être faire 3 templates : div/p, note/p et figure/p
		Les note/p n’ont jamais d’attributs
		Vérifier solidité du test pour le code en block
	-->
	<xsl:template match="*:body//*:p|*:back//*:p">
		<xsl:copy>
			<xsl:if test="not(parent::*:note) and not(child::*:code[not(@rend='inline')])">
				<xsl:attribute name="style" select="
					if(@rend='break')
						then('txt_separateur')
					else if(@rend='caption')
						then('txt_Legende')
					else if(@rend='consecutive')
						then('txt_Normal_suite')
					else if(@rend='credits' and preceding-sibling::*:graphic)
						then('ill-credits-sources')
					else if(@rend='credits' and preceding-sibling::*:table)
						then('table-credits-sources')
					else if(@rend='#rtl')
						then('txt_Normal_inv')
					else('txt_Normal')"/>
			</xsl:if>
			<xsl:if test="@rend='break'">
				<xsl:attribute name="rend" select="'break'"/>
			</xsl:if>
			<xsl:if test="@rend='#rtl'">
				<xsl:attribute name="rend" select="'rtl'"/>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:body//*:list/*:item">
		<xsl:copy>
			<xsl:attribute name="style" select="'txt_Liste_'||count(ancestor::*:list)"/>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>


	<!-- TODO: @n nécessaire ? Correspond à l’ordre ou à un label ?
			La structure COMMONS est-elle bien floatingText/body/head ou floatingText/body/div/head ?
			A REVOIR l.1075 et 1185
	-->

	<xsl:template match="*:floatingText">
		<floatingText xmlns="http://www.tei-c.org/ns/1.0" type="encadre" subtype="{@type}">
			<xsl:apply-templates select="node()"/>
		</floatingText>
	</xsl:template>

	<xsl:template match="*:floatingText/*:body">
		<xsl:copy>
			<div xmlns="http://www.tei-c.org/ns/1.0" type="encadre">
				<xsl:apply-templates select="node()"/>
			</div>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:floatingText/*:body/*:head">
		<head style="{'titreEnc'||ancestor::*:floatingText/@type}" xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()"/>
		</head>
	</xsl:template>

	<xsl:template match="*:cit">
		<xsl:apply-templates select="node()"/>
	</xsl:template>

	<!-- TODO
		@style = txt_Epigraphe | txt_Citation | txt_Citation_italique
		@rend = quotation | quotation italique		> seulement pour les blocks
			> que faire de quotation2 ? > à garder
		@xml:lang = reprendre si présent ? > oui
		Est-ce bien la présence ou non d’@xml:lang qui "déclenche" l’italique ? > oui
		Si oui, style "txt_Epigraphe_italique" ? > non
		distinction "txt_Citation" (block) vs "typo_Citation" (inline)	> se baser sur la présence d’un parent p
	-->
	<xsl:template match="*:quote">
		<xsl:copy>
			<xsl:if test="not(ancestor::*:epigraph)">
				<xsl:attribute name="rend" select="if(@xml:lang) then('quotation italique') else('quotation')"/>
			</xsl:if>
			<xsl:attribute name="style"
						   select="if(ancestor::*:epigraph) then('txt_Epigraphe') else if(@xml:lang) then('txt_Citation_italique') else('txt_Citation')"/>
			<xsl:if test="@xml:lang">
				<xsl:attribute name="xml:lang" select="@xml:lang"/>
			</xsl:if>
			<xsl:if test="@type='gloss'">
				<xsl:attribute name="type" select="'glose'"/>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<!-- POÉSIE -->
	<!-- garder encodage COMMONS sauf ajout @style="txt_vers" sur les l -->

	<xsl:template match="*:l">
		<xsl:copy>
			<xsl:attribute name="style" select="'txt_vers'"/>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<!-- THÉÂTRE -->
	<!--
		name@type="speaker"	 -> à rebasculer dans un <speaker> en début de <sp> ?
		sp/@who="locuteur" -> "$locuteur" ?
		Je vois pas de différences sinon
	-->


	<!-- LINGUISTIQUE -->
	<!-- TODO: le passage de cit à quote (avec suppression d’un niveau si je lis bien ?) devrait être réglé par le traitement standard des citations imbriquées ?
			Sinon : - @n devient <num>
					- ordre glose/réf. biblio sont inversés : WAD ? Ou ordre inimportant, toujours reproduire celui du doc
	-->


	<!-- ENTRETIENS, CODE : encodages identiques sauf erreur…? -->
	<!-- CODE: manque @style + il est présent (mais superflu) sur le p parent -->
	<xsl:template match="*:code">
		<xsl:copy>
			<xsl:attribute name="style" select="'txt_code'"/>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<!-- FIGURES, TABLEAUX et MATH -->
	<!-- besoin d’un template pour enlever l’attribut figure/@rend='block' ? -->

	<!-- TODO: est-ce que le @rend='block' est bien là, ou est-ce qu’on déduit de l’absence de @rend='inline' ? > pas de "inline"
			   Est-ce qu’on veut vraiment le @rend='block' sur le <formula> enfant ? > oui
			   Est-ce qu’il faut un @style="mathml" sur le <p> comme dans l’exemple ou pas ? > oui
			   		> penser aussi au tex/latex
			   		> formule dans p, cf métopes l.770
	-->
	<xsl:template match="*:figure[not(@rend='inline')][*:formula]">
		<p xmlns="http://www.tei-c.org/ns/1.0" rend="block">
			<xsl:attribute name="style" select="*:formula/@notation"/>
			<xsl:apply-templates select="node()"/>
		</p>
	</xsl:template>

	<xsl:template match="*:formula">
		<xsl:copy>
			<xsl:attribute name="notation" select="@notation"/>
			<!-- TODO: Cf. commentaire précédent -->
			<xsl:attribute name="rend" select="if(parent::*:figure/@rend='inline') then('inline') else('block')"/>
			<xsl:apply-templates select="node()"/>
			<xsl:if test="@notation!='mathml'">
				<xsl:apply-templates select="following-sibling::*:graphic"/>
			</xsl:if>
		</xsl:copy>
	</xsl:template>

	<!-- TODO: ça à l’air de fonctionner…? -->
	<!-- c’est pas forcément du mml, revoir ça -->
	<!-- mais si c’est du latex je devrai pas avoir d’élément descendant de formula, right ? -->
	<xsl:template match="*:formula//element()">
		<xsl:element name="mml:{local-name()}">
			<xsl:apply-templates select="@*|node()"/>
		</xsl:element>
	</xsl:template>

	<!-- TODO: pas d’intervention nécessaire sur le contenu des tableaux a priori ? -->
	<xsl:template match="*:figure[*:table]">
		<xsl:apply-templates select="node()"/>
	</xsl:template>

	<xsl:template match="*:table">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:if test="following-sibling::*:head">
				<head xmlns="http://www.tei-c.org/ns/1.0">
					<xsl:apply-templates select="following-sibling::*:head/node()"/>
				</head>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:figure[*:table]/*:head"/>

	<xsl:template match="*:figure/*:head[preceding-sibling::*:graphic]">
		<xsl:copy>
			<xsl:attribute name="style" select="'titre_figure'"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:figure[@rend='inline']">
		<xsl:apply-templates select="element()"/>
	</xsl:template>


	<!-- NOTES -->
	<xsl:template match="*:note[@place]">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="style" select="'txt_Note'"/>
			<xsl:attribute name="type" select="if(@type) then(@type) else('standard')"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>


	<!-- BACK -->
	<!-- Bibliographie -->
	<!-- C’était pas censé être @type='bibliographIE' dans Métopes du coup ? -->
	<xsl:template match="*:div[@type='bibliography']">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="bibliography" xml:id="bibliography">
			<head style="T_1">
				<xsl:apply-templates select="*:head/node()"/>
			</head>
			<xsl:apply-templates select="*:listBibl|*:bibl"/>
		</div>
	</xsl:template>

	<!-- les bibl sont pas numérotés pareil ('9' vs '09') : WAD ? -->
	<xsl:template match="*:div[@type='bibliography']//*:bibl">
		<xsl:copy>
			<xsl:attribute name="style" select="'txt_Bibliographie'"/>
			<xsl:attribute name="type" select="'orig'"/>
			<xsl:apply-templates select="@xml:id|node()"/>
		</xsl:copy>
	</xsl:template>


	<!-- ANNEXES -->
	<xsl:template match="*:div[@type='appendix']">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="annexe">
			<head style="T_1">
				<xsl:apply-templates select="*:head/node()"/>
			</head>
			<xsl:apply-templates select="*:div"/>
		</div>
	</xsl:template>

	<!-- TYPO -->
	<xsl:template match="*:hi[@rend!='uppercase']">
		<xsl:copy>
			<!--
			Pour info on aurait pu faire comme ça
			<xsl:attribute name="style" select="'typo_'||string-join(for $rend in tokenize(@rend) return $typoRef//*:style[@eq=$rend], '_')" />
			-->
			<xsl:variable name="rend" select="@rend"/>
			<xsl:attribute name="style" select="'typo_'||$typoRef//*:style[@eq=$rend]"/>
			<xsl:attribute name="rend" select="if($rend='strikethrough') then('line-through') else($rend)"/>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*:hi[@rend='uppercase']">
		<xsl:apply-templates select="node()"/>
	</xsl:template>


</xsl:stylesheet>

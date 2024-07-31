<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Code source sous licence CECILL-C. Veuillez vous référer au fichier LICENSE.txt pour plus d'informations
Source code under CECILL-C licence. Please refer to the LICENSE.txt file for more information.

Copyright IR Métopes

Copyright Université de Caen Normandie

Esplanade de la paix
CS 14032
14032 Caen CEDEX 5

Contributeurs : IR Métopes (CB, EC), Pôle Document numérique (OVP)
 -->


<xsl:stylesheet
version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:tei="http://www.tei-c.org/ns/1.0"
xmlns:xlink="http://www.w3.org/1999/xlink"
xmlns:xi="http://www.w3.org/2001/XInclude"
xmlns:mml="http://www.w3.org/1998/Math/MathML"
exclude-result-prefixes="tei xsl">

<xsl:output method="xml" encoding="UTF-8" indent="no" />

	<xsl:variable name="lang" select="//*:article/@xml:lang" />

	<xsl:template match="/">
		<TEI change="commons_edition" xmlns="http://www.tei-c.org/ns/1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mml="http://www.w3.org/1998/Math/MathML">
			<xsl:apply-templates select="*:article/*:front" />
			<text xml:id="text">
				<xsl:call-template name="text-front" />
				<xsl:apply-templates select="*:article/*:body" />
				<xsl:if test="//*:back/*:app-group or //*:back/*:ref-list or //*:bio">
					<back xmlns="http://www.tei-c.org/ns/1.0">
						<xsl:apply-templates select="//*:back/*:app-group|//*:back/*:ref-list|//*:bio" />
					</back>
				</xsl:if>
			</text>
		</TEI>
	</xsl:template>


	<!--        -->
	<!-- HEADER -->
	<!--        -->
	
	<xsl:template match="*:front">
		<teiHeader xmlns="http://www.tei-c.org/ns/1.0">		
			<fileDesc>
				<titleStmt>
					<xsl:apply-templates select="*:article-meta/*:title-group/element()|*:article-meta/*:contrib-group/element()" mode="header-mode"/>
				</titleStmt>
				<publicationStmt>
					<ab type="expression">
						<bibl>	
							<xsl:for-each select="//*:journal-meta/*:publisher/*:publisher-name">
								<publisher>
									<xsl:apply-templates select="node()" />
								</publisher>
							</xsl:for-each>
							<xsl:choose>
								<xsl:when test="//*:article-meta/*:permissions">
									<xsl:apply-templates select="//*:article-meta/*:permissions" />
								</xsl:when>
								<xsl:otherwise>
									<availability>
										<licence>
											<p></p>
										</licence>
									</availability> 
								</xsl:otherwise>
							</xsl:choose>
							<ref type="book" target="#"/>
						</bibl>
					</ab>
					<ab type="editorial_workflow">
   						<xsl:for-each select="*:article-meta/*:history/*:date">	
   							<date type="{@date-type}">
								<xsl:attribute name="when">
									<xsl:call-template name="orderDatesAttr">
										<xsl:with-param name="date" select="." />
									</xsl:call-template>			
								</xsl:attribute>
								<xsl:call-template name="orderDatesText">
									<xsl:with-param name="date" select="." />
								</xsl:call-template>
							</date>
   						</xsl:for-each>
   						<xsl:if test="not(*:article-meta/*:history/*:date)">
   							<date type="received" when="AAAA-MM-JJ"></date>
   							<date type="accepted" when="AAAA-MM-JJ"></date>
   						</xsl:if>
   					</ab>
					<ab type="book">
   						<bibl>
      						<distributor></distributor>
							<xsl:choose>
								<xsl:when test="//*:article/*:front/*:article-meta/*:pub-date[@date-type='pub' and @publication-format='print']">
									<date type="publishing">
										<xsl:attribute name="when">
											<xsl:call-template name="orderDatesAttr">
												<xsl:with-param name="date" select="//*:article/*:front/*:article-meta/*:pub-date[@date-type='pub' and @publication-format='print']" />
											</xsl:call-template>			
										</xsl:attribute>
										<xsl:call-template name="orderDatesText">
											<xsl:with-param name="date" select="//*:article/*:front/*:article-meta/*:pub-date[@date-type='pub' and @publication-format='print']" />
										</xsl:call-template>
									</date>
								</xsl:when>
								<xsl:otherwise>
									<date type="publishing" when="AAAA-MM-JJ"></date>
								</xsl:otherwise>
							</xsl:choose>						
							<xsl:variable name="pagination" select="concat(//*:article/*:front/*:article-meta/*:fpage, '-', //*:article/*:front/*:article-meta/*:lpage)" />
							<xsl:choose>
								<xsl:when test="$pagination!='-'">
									<dim type="pagination" unit="page" extent="{$pagination}">
										<xsl:value-of select="$pagination" />
									</dim>
								</xsl:when>
								<xsl:otherwise>
									<dim type="pagination" unit="page" extent="xx-yy"></dim>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:for-each select="//*:journal-meta/*:publisher/*:publisher-name">
								<publisher>
									<xsl:apply-templates select="node()" />
								</publisher>
							</xsl:for-each>
							<xsl:choose>
								<xsl:when test="//*:article-meta/*:permissions">
									<xsl:apply-templates select="//*:article-meta/*:permissions" />
								</xsl:when>
								<xsl:otherwise>
									<availability>
										<licence>
											<p></p>
										</licence>
									</availability> 
								</xsl:otherwise>
							</xsl:choose>
						</bibl>
					</ab>
					<ab type="digital_online" subtype="HTML">
						<bibl>
							<distributor></distributor>
							<xsl:choose>
								<xsl:when test="//*:article/*:front/*:article-meta/*:pub-date[@date-type='pub' and @publication-format='electronic']">
									<date type="publishing">
										<xsl:attribute name="when">
											<xsl:call-template name="orderDatesAttr">
												<xsl:with-param name="date" select="//*:article/*:front/*:article-meta/*:pub-date[@date-type='pub' and @publication-format='electronic']" />
											</xsl:call-template>			
										</xsl:attribute>
										<xsl:call-template name="orderDatesText">
											<xsl:with-param name="date" select="//*:article/*:front/*:article-meta/*:pub-date[@date-type='pub' and @publication-format='electronic']" />
										</xsl:call-template>
									</date>
								</xsl:when>
								<xsl:otherwise>
									<date type="publishing" when="AAAA-MM-JJ"></date>
								</xsl:otherwise>
							</xsl:choose>
							<date type="embargoend" when="AAAA-MM-JJ"></date>
							<idno type="pii"><xsl:value-of select="//*:article/*:front/*:article-meta/*:article-id[@pub-id-type='pii']" /></idno> 
							<idno type="DOI"><xsl:value-of select="//*:article/*:front/*:article-meta/*:article-id[@pub-id-type='doi']" /></idno>
							<ref target="URL"><xsl:value-of select="//*:article/*:front/*:article-meta/*:self-uri/@xlink:href" /></ref>
							<xsl:choose>
								<xsl:when test="//*:article-meta/*:permissions">
									<xsl:apply-templates select="//*:article-meta/*:permissions" />
								</xsl:when>
								<xsl:otherwise>
									<availability>
										<licence>
											<p></p>
										</licence>
									</availability> 
								</xsl:otherwise>
							</xsl:choose>
					   </bibl>
					</ab>
				</publicationStmt>
				<sourceDesc>
					<p>Jats file</p>
				</sourceDesc>
			</fileDesc>
			<encodingDesc>
				<p></p>
				<xsl:if test="//*:list[@list-type]">
					<tagsDecl>
						<rendition scheme="css" xml:id="list-decimal">list-style-type:decimal;</rendition>
						<rendition scheme="css" xml:id="list-disc">list-style-type:disc;</rendition>
					</tagsDecl>
				</xsl:if>
			</encodingDesc>
			<profileDesc>
				<!-- TODO: je pars du principe que l’@xml:lang de l’élément article est toujours rempli -->
				<langUsage>
					<language ident="{$lang}" />
				</langUsage>
				<textClass>
					<xsl:for-each select="*:article-meta/*:kwd-group">
						<keywords scheme="keyword">
							<xsl:if test="@xml:lang">
								<xsl:attribute name="xml:lang" select="@xml:lang" />
							</xsl:if>
							<list>
								<xsl:apply-templates select="*:kwd" />
							</list>
						</keywords>
					</xsl:for-each>
				</textClass>
			</profileDesc>
			<revisionDesc>
				<listChange>
					<change type="creation" when="{concat(year-from-date(current-date()), '-', month-from-date(current-date()), '-', day-from-date(current-date()))}">JATS to TEI Commons conversion</change>
				</listChange>
			</revisionDesc>
		</teiHeader>
	</xsl:template>

	<xsl:template name="orderDatesAttr">
		<xsl:param name="date" />
		<xsl:if test="$date/*:year">
			<xsl:value-of select="$date/*:year"/>
			<xsl:if test="$date/*:month or $date/*:day">
				<xsl:text>-</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:if test="$date/*:month">
			<xsl:value-of select="$date/*:month"/>
			<xsl:if test="$date/*:day">
				<xsl:text>-</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:if test="$date/*:day">
			<xsl:value-of select="$date/*:day"/>
		</xsl:if>		
	</xsl:template>

	<xsl:template name="orderDatesText">
		<xsl:param name="date" />
		<xsl:if test="$date/*:year">
			<xsl:value-of select="$date/*:year"/>
			<xsl:if test="$date/*:month or $date/*:day">
				<xsl:text>/</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:if test="$date/*:month">
			<xsl:value-of select="$date/*:month"/>
			<xsl:if test="$date/*:day">
				<xsl:text>/</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:if test="$date/*:day">
			<xsl:value-of select="$date/*:day"/>
		</xsl:if>		
	</xsl:template>

	<xsl:template match="*:trans-title-group" mode="header-mode">
		<xsl:apply-templates select="node()" mode="header-mode"/>		
	</xsl:template>

	<!-- TODO: a priori on ne prend pas les sous-titres traduit ? -->	
	<xsl:template match="*:article-title|*:subtitle|*:alt-title|*:trans-title" mode="header-mode">
		<title xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:attribute name="type" select="
				if(local-name()='article-title')
					then('main')
				else if(local-name()='subtitle')
					then('sub')
				else if(local-name()='trans-title')
					then('trl')
				else ('???')
			"/>
			<xsl:if test="parent::*:trans-title-group">
				<xsl:attribute name="xml:lang" select="parent::*:trans-title-group/@xml:lang"/>
			</xsl:if>
			<xsl:apply-templates select="node()" />
		</title>		
	</xsl:template>

	<!-- TODO: autres rôles à prendre en compte ? Au moins traducteur -->
	<xsl:template match="*:contrib" mode="header-mode">
		<xsl:choose>
			<xsl:when test="@contrib-type='author'">
				<author xmlns="http://www.tei-c.org/ns/1.0" role="aut">
					<xsl:apply-templates select="*:name" mode="header-mode" />
					<xsl:apply-templates select="node() except *:name" mode="header-mode" />
				</author>
			</xsl:when>
			<xsl:when test="@contrib-type='editor'">
				<editor xmlns="http://www.tei-c.org/ns/1.0" role="edt">
					<xsl:apply-templates select="*:name" mode="header-mode" />
					<xsl:apply-templates select="node() except *:name" mode="header-mode" />
				</editor>	
			</xsl:when>
			<xsl:when test="@contrib-type='translator'">
				<editor xmlns="http://www.tei-c.org/ns/1.0" role="trl">
					<xsl:apply-templates select="*:name" mode="header-mode" />
					<xsl:apply-templates select="node() except *:name" mode="header-mode" />
				</editor>	
			</xsl:when>
			<xsl:otherwise />
		</xsl:choose>	
	</xsl:template>

	<xsl:template match="*:contrib/*:name" mode="header-mode">
		<persName xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="*:given-names" mode="header-mode" />
			<xsl:apply-templates select="*:surname" mode="header-mode" />
			<xsl:apply-templates select="node() except (*:given-names|*:surname)" mode="header-mode" />
		</persName>
	</xsl:template>
	
	<xsl:template match="*:given-names" mode="header-mode">
		<forename xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()" />
		</forename>
	</xsl:template>
	
	<xsl:template match="*:surname" mode="header-mode">
		<surname xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()" />
		</surname>
	</xsl:template>

	<xsl:template match="*:contrib/*:aff" mode="header-mode">
		<xsl:choose>
			<xsl:when test="*:xref">
				<xsl:apply-templates select="*:xref" mode="header-mode" />
			</xsl:when>
			<xsl:otherwise>
				<affiliation xmlns="http://www.tei-c.org/ns/1.0">
					<xsl:apply-templates mode="aff"/>
				</affiliation>	
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>

	<xsl:template match="*:contrib/*:bio" mode="header-mode">
		<ref xmlns="http://www.tei-c.org/ns/1.0" target="{concat('#bio', count(preceding::*:bio) +1)}" type="biography"/>
	</xsl:template>
	
	<xsl:template match="*:contrib/*:email" mode="header-mode">
		<email xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()" />
		</email>
	</xsl:template>
	
	<xsl:template match="*:contrib/*:contrib-id" mode="header-mode">
		<idno xmlns="http://www.tei-c.org/ns/1.0" type="{@contrib-id-type}">
			<xsl:value-of select="." />
		</idno>
	</xsl:template>

	<xsl:template match="*:contrib-group/*:aff" mode="header-mode front-mode"/>
	
	<!-- TODO: peut-être ne pas faire de value-of (possibilité d‘enrichissement typo ?) -->
	<xsl:template match="*:xref[@ref-type='aff']" mode="header-mode">
		<xsl:variable name="refAff" select="@rid" />
		<xsl:if test="following::*:aff[@id=$refAff]/node()[not(self::*:email)]">
			<affiliation xmlns="http://www.tei-c.org/ns/1.0">
				<xsl:apply-templates select="following::*:aff[@id=$refAff]/node()" mode="aff"/>
			</affiliation>		
		</xsl:if>
		<xsl:if test="following::*:aff[@id=$refAff]//*:email">
			<email xmlns="http://www.tei-c.org/ns/1.0">
				<xsl:apply-templates select="following::*:aff[@id=$refAff]/*:email/node()" />
			</email>		
		</xsl:if>
	</xsl:template>

	<xsl:template match="*:xref[@ref-type='corresp']" mode="header-mode">
		<xsl:variable name="refCorresp" select="@rid" />
		<xsl:if test="following::*:corresp[@id=$refCorresp]//*:email">
			<email xmlns="http://www.tei-c.org/ns/1.0">
				<xsl:apply-templates select="following::*:corresp[@id=$refCorresp]//*:email" />
			</email>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="*:xref[@ref-type='*:bio']" mode="header-mode">
		<xsl:variable name="refBio" select="@rid" />
		<ref xmlns="http://www.tei-c.org/ns/1.0" target="{concat('#', $refBio)}" type="biography"/>
	</xsl:template>
	
	<!-- TODO: if faudrait p-ê faire ça pour tous les enfants de aff ? -->
	<xsl:template match="*:aff/*:institution" mode="aff">
		<orgName xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates mode="aff" />
		</orgName>
	</xsl:template>
	
	<xsl:template match="*:addr-line | *:city | *:country | *:fax | *:institution-wrap | *:phone | *:postal-code | *:state" mode="aff">
		<xsl:apply-templates mode="aff" />
	</xsl:template>
	
	<xsl:template match="*:email" mode="aff" />
	
	<!-- TODO: système de numérotation différent pour ces notes-ci ? -->
	<!--<xsl:template match="*:contrib/*:xref[@ref-type='fn']" mode="header-mode">
		
	</xsl:template>-->

	<xsl:template match="*:permissions">
		<availability xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="*:copyright-statement|*:license" />
		</availability>
	</xsl:template>	

	<xsl:template match="*:copyright-statement|*:license">
		<licence xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:if test="@xlink:href">
				<xsl:attribute name="target" select="@xlink:href" />
			</xsl:if>
			<xsl:apply-templates select="node()" />
        </licence>	
	</xsl:template>
	
	<xsl:template match="*:license-p">
		<p xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()" />
		</p>
	</xsl:template>

	
	<!--       -->
	<!-- FRONT -->
	<!--       -->
	
	<!-- TODO: partenaires -->
	<xsl:template name="text-front">
		<front xmlns="http://www.tei-c.org/ns/1.0">
			<div type="titlePage">
				<xsl:apply-templates select="//*:article-meta/*:title-group/element()|//*:article-meta/*:contrib-group/element()" mode="front-mode"/>
			</div>
			<xsl:apply-templates select="//*:article-meta/*:abstract" />
			<xsl:apply-templates select="//*:article-meta/*:kwd-group[@kwd-group-type='author-keywords'][not(@xml:lang) or @xml:lang=$lang]" />
			<xsl:for-each select="//*:article-meta/*:trans-abstract">
				<xsl:variable name="trans-lang" select="@xml:lang" />
				<xsl:apply-templates select=".|//*:article-meta/*:kwd-group[@kwd-group-type='author-keywords'][@xml:lang=$trans-lang]" />
			</xsl:for-each>
			<!-- TODO: finir front : NdlA et NdlE/R, remerciements, etc… -->
			<xsl:apply-templates select="//*:author-notes|//*:ack" />
		</front>	
	</xsl:template>
	
	<xsl:template match="*:trans-title-group" mode="front-mode">
        <xsl:apply-templates select="*:trans-title" mode="front-mode"/>
	</xsl:template>
	
	<xsl:template match="*:article-title|*:subtitle|*:alt-title|*:trans-title" mode="front-mode">
		<p xmlns="http://www.tei-c.org/ns/1.0" rend="title-main">
			<xsl:attribute name="rend" select="
				if(local-name()='article-title')
					then('title-main')
				else if(local-name()='subtitle')
					then('title-sub')
				else if(local-name()='trans-title')
					then('title-trl')
				else ('???')
			"/>
			<xsl:if test="parent::*:trans-title-group">
				<xsl:attribute name="xml:lang" select="parent::*:trans-title-group/@xml:lang"/>
			</xsl:if>
			<xsl:apply-templates select="node()" />
		</p>
	</xsl:template>

	<!-- TODO: liste des rôles à compléter -->
	<xsl:template match="*:contrib" mode="front-mode">
		<p xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:attribute name="rend" select="
				if(@contrib-type='author')
					then('author-aut')
				else if(@contrib-type='editor')
					then('editor-edt')
				else if(@contrib-type='translator')
					then('editor-trl')
				else('???')
			" />
			<xsl:apply-templates select="*:name/*:given-names/node()" />
			<xsl:text> </xsl:text>
			<xsl:apply-templates select="*:name/*:surname/node()" />
			<xsl:apply-templates select="*:name/node() except (*:name/*:given-names|*:name/*:surname)" />
		</p>		
		<xsl:if test="*:email">
			<p xmlns="http://www.tei-c.org/ns/1.0" rend="authority-mail"><xsl:apply-templates select="*:email/node()" /></p>
		</xsl:if>
		<xsl:if test="descendant::*:xref[@ref-type='aff']">
			<xsl:variable name="refAff" select="descendant::*:xref[@ref-type='aff']/@rid" />
			<p xmlns="http://www.tei-c.org/ns/1.0" rend="authority_affiliation"><xsl:value-of select="normalize-space(//*:aff[@id=$refAff])" /></p>
		</xsl:if>		
	</xsl:template>
	
	<xsl:template match="*:article-meta/*:abstract|*:article-meta/*:trans-abstract">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="abstract">
			<xsl:if test="@xml:lang">
				<xsl:attribute name="xml:lang" select="@xml:lang"/>
			</xsl:if>
			<xsl:apply-templates select="*:p" />
		</div>
	</xsl:template>
	
	<xsl:template match="*:article-meta/*:kwd-group[@kwd-group-type='author-keywords']">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="keywords">
			<xsl:if test="@xml:lang">
				<xsl:attribute name="xml:lang" select="@xml:lang"/>
			</xsl:if>
			<p><xsl:value-of select="string-join(*:kwd, ', ')" /></p>
		</div>
	</xsl:template>
	
	<xsl:template match="*:kwd">
		<item xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()" />
		</item>
	</xsl:template>

	<xsl:template match="*:author-notes">
		<xsl:for-each select="*:fn">
			<note xmlns="http://www.tei-c.org/ns/1.0" type="aut">
				<xsl:apply-templates select="node()" />
			</note>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="*:ack">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="ack">
			<xsl:apply-templates select="node()" />
		</div>
	</xsl:template>		
	
	<!--        -->
	<!--  BODY  -->
	<!--        -->
	<!-- TODO: préciser les autres cas pour @type ; autres attributs ? -->
	<xsl:template match="*:body">
		<body xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</body>		
	</xsl:template>
	
	<xsl:template match="*:sec|*:app">
		<div xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:attribute name="type" select="concat('section', count(ancestor-or-self::*:sec) + count(ancestor-or-self::*:app))" />
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<xsl:apply-templates />
		</div>		
	</xsl:template>

	<xsl:template match="*:sec/*:title|*:caption/*:title|*:app-group/*:title|*:app/*:label">
		<head xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</head>
	</xsl:template>
	
	<xsl:template match="*:p">
		<p xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</p>
	</xsl:template>
	
	<!-- TODO: et si j’ai un para qui en contient plusieurs…?
	<xsl:template match="*:p[(*:disp-formula or *:fig or *:disp-quote) and (count(element()) = 1)]">
		<xsl:apply-templates />
	</xsl:template>	 -->

	<xsl:template match="*:p[child::element() and not(child::node()[not(self::*:disp-quote or self::*:disp-formula or self::*:fig)])]">
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="comment()">
		<xsl:if test=".='There should be a line-break here.'">
			<lb xmlns="http://www.tei-c.org/ns/1.0"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="*:fig">
		<figure xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<xsl:apply-templates select="*:graphic"/>
			<xsl:apply-templates select="node() except *:graphic" />		
		</figure>
	</xsl:template>
	
	<xsl:template match="*:inline-graphic|*:graphic[not(parent::*:fig)]">
		<figure xmlns="http://www.tei-c.org/ns/1.0" rend="inline">
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<graphic rend="inline" url="{@xlink:href}">
				<xsl:apply-templates />
			</graphic>
		</figure>
	</xsl:template>
	
	<xsl:template match="*:graphic">
		<graphic xmlns="http://www.tei-c.org/ns/1.0" url="{@xlink:href}">
			<xsl:apply-templates />
		</graphic>	
	</xsl:template>
	
	<xsl:template match="*:fig/*:label">
		<head xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</head>
	</xsl:template>
	
	<xsl:template match="*:fig/*:caption">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="*:fig/*:caption/*:p">
		<p xmlns="http://www.tei-c.org/ns/1.0" rend="caption">
			<xsl:apply-templates />
		</p>
	</xsl:template>

	<xsl:template match="*:fig/*:attrib">
		<p xmlns="http://www.tei-c.org/ns/1.0" rend="credits">
			<xsl:apply-templates />
		</p>
	</xsl:template>

	<!-- Tableaux -->
	<xsl:template match="*:table-wrap">
		<xsl:variable name="nextNOTCaption" select="following-sibling::*[not(@content-type='table-caption')][1]/generate-id()" />
		<xsl:variable name="nextNOTLegendOrCredits" select="following-sibling::*[not(@content-type='table-legend' or @content-type='table-credits')][1]/generate-id()" />
		<figure xmlns="http://www.tei-c.org/ns/1.0">			
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<xsl:if test="*:label or *:caption or following-sibling::*[following::node()/generate-id()=$nextNOTCaption][not(@content-type='table-legend' or @content-type='table-credits')]">
				<head>
					<xsl:for-each select="*:label|*:caption|following-sibling::*[following::node()/generate-id()=$nextNOTCaption][not(@content-type='table-legend' or @content-type='table-credits')]">
						<xsl:apply-templates select="." mode="tableHead"/>
						<xsl:if test="position()!=last()">
							<xsl:text> </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</head>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
			<xsl:apply-templates select="following-sibling::*[following::node()/generate-id()=$nextNOTLegendOrCredits][not(@content-type='table-caption')]" mode="inTag"/>
		</figure>
	</xsl:template>
	
	<xsl:template match="*:table">
		<table xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<xsl:apply-templates />
		</table>
	</xsl:template>
	
	<xsl:template match="*:tbody">
		<xsl:apply-templates />
	</xsl:template>	
	
	<xsl:template match="*:tr">
		<row xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:if test="*:th">
				<xsl:attribute name="role" select="'label'" />
			</xsl:if>
			<xsl:apply-templates />
		</row>
	</xsl:template>
	
	<xsl:template match="*:th|*:td">
		<cell xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:if test="@colspan">
				<xsl:attribute name="cols" select="@colspan" />
			</xsl:if>
			<xsl:if test="@rowspan">
				<xsl:attribute name="rows" select="@rowspan" />
			</xsl:if>
			<xsl:apply-templates />
		</cell>
	</xsl:template>
	
	<xsl:template match="*:label|*:caption|*:p[@content-type='table-caption']" mode="tableHead">
		<xsl:apply-templates />
	</xsl:template>	

	<xsl:template match="*:p[@content-type='table-legend']" mode="inTag">
		<p xmlns="http://www.tei-c.org/ns/1.0" rend="caption">
			<xsl:apply-templates />
		</p>
	</xsl:template>	
	
	<xsl:template match="*:p[@content-type='table-credits']" mode="inTag">
		<p xmlns="http://www.tei-c.org/ns/1.0" rend="credits">
			<xsl:apply-templates />
		</p>
	</xsl:template>
	
	<xsl:template match="*:p[@content-type='table-caption']|*:p[@content-type='table-legend']|*:p[@content-type='table-credits']" />

	<xsl:template match="*:disp-formula|*:inline-formula">
		<figure xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<xsl:if test="local-name()='inline-formula'">
				<xsl:attribute name="rend" select="'inline'" />
			</xsl:if>
			<formula>
				<xsl:attribute name="notation" select="substring-after(@content-type, 'math/')" />
				<xsl:apply-templates select="*:tex-math/node()|*:math" mode="math"/>
			</formula>
		</figure>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="math">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="math" />
		</xsl:copy>
	</xsl:template>

	<!-- TODO: Je ne me rappelle pas où est l’attribut @lang dans COMMONS
			   Enfin: revoir pour les citations imbriquées
	-->
	<xsl:template match="*:disp-quote[*:p/@content-type='epigraph']">		
		<epigraph xmlns="http://www.tei-c.org/ns/1.0">
			<cit>
				<xsl:if test="@id">
					<xsl:attribute name="xml:id" select="@id" />
				</xsl:if>
				<xsl:apply-templates />
			</cit>
		</epigraph>
	</xsl:template>

	<xsl:template match="*:disp-quote">		
		<cit xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<xsl:apply-templates />
		</cit>
	</xsl:template>
	
	<xsl:template match="*:disp-quote/*:p">
		<quote xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</quote>
	</xsl:template>	
	
	<xsl:template match="*:named-content[@content-type='inline_quotation']">
		<quote xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</quote>
	</xsl:template>

	<!-- Listes -->
	<xsl:template match="*:list">
		<list xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:attribute name="rendition" select="
				if(@list-type='ordered')
					then('#list-decimal')
				else if(@list-type='unordered')
					then('#list-disc')
				else ('##')
			" />
			<xsl:if test="@id">
				<xsl:attribute name="xml:id" select="@id" />
			</xsl:if>
			<xsl:if test="@list-type">
				<xsl:attribute name="type" select="@list-type" />
			</xsl:if>
			<xsl:apply-templates />
		</list>
	</xsl:template>

	<!-- TODO: oui mais si on veut *vraiment* des p dans nos item ? -->
	<xsl:template match="*:list-item">
		<item xmlns="http://www.tei-c.org/ns/1.0">
        	<xsl:apply-templates select="*:p/node()|*:list"/>
		</item>
	</xsl:template>

	<!-- Poésie -->	
	<xsl:template match="*:verse-group">
		<lg xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</lg>
	</xsl:template>

	<xsl:template match="*:verse-line">
		<l xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates />
		</l>
	</xsl:template>

	<!-- Encadrés -->
	<xsl:template match="*:boxed-text">
		<floatingText xmlns="http://www.tei-c.org/ns/1.0">
			<body>
				<xsl:apply-templates/>
			</body>
		</floatingText>
	</xsl:template>

	<xsl:template match="*:boxed-text/*:caption">
		<xsl:apply-templates />
	</xsl:template>

	<!-- Code -->
	<xsl:template match="*:sec/*:code">
		<p xmlns="http://www.tei-c.org/ns/1.0">
			<code>
				<xsl:apply-templates/>
			</code>
		</p>		
	</xsl:template>

	<xsl:template match="*:code">
		<code xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates/>
		</code>
	</xsl:template>

	
	<!-- Notes et liens -->
	<xsl:template match="*:xref[@ref-type='fn']" mode="header-mode #default">
		<xsl:variable name="note-ref" select="@rid" />
		<!--<note xmlns="http://www.tei-c.org/ns/1.0" place="foot" n="{count(preceding::*:xref[@ref-type='fn']) + 1}" xml:id="{concat('ftn', count(preceding::*:xref[@ref-type='fn']) + 1)}">-->
		<note xmlns="http://www.tei-c.org/ns/1.0" place="foot" n="{count(preceding::*:xref[@ref-type='fn']) + 1}" xml:id="{if(starts-with(@rid, '#')) then(substring-after(@rid, '#')) else(@rid)}">
			<xsl:apply-templates select="following::*:fn[@id=$note-ref]/(node() except *:label[1])" />
		</note>
	</xsl:template>
	
	<xsl:template match="*:xref[not(@ref-type='fn')]">
		<ref xmlns="http://www.tei-c.org/ns/1.0" target="{concat('#',@rid)}">
			<xsl:if test="@ref-type='bibr'">
				<xsl:attribute name="type" select="'bibl'" />
			</xsl:if>
			<xsl:apply-templates select="node()" />
		</ref>		
	</xsl:template>
	
	<xsl:template match="*:ext-link">
		<ref xmlns="http://www.tei-c.org/ns/1.0" target="{@xlink:href}">
			<xsl:apply-templates select="node()" />
		</ref>		
	</xsl:template>


	<!--        -->
	<!--  BACK  -->
	<!--        -->
	<xsl:template match="//*:back/*:app-group">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="appendix" xml:id="appendix">
			<xsl:apply-templates select="node()" />
		</div>	
	</xsl:template>

	<xsl:template match="//*:back/*:ref-list">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="bibliography" xml:id="bibliography">
			<xsl:apply-templates select="node()" mode="bibliography"/>
		</div>	
	</xsl:template>
	
	<xsl:template match="*:title" mode="bibliography">
		<head xmlns="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="node()" />
		</head>
	</xsl:template>	
	
	<xsl:template match="*:ref" mode="bibliography">
		<xsl:variable name="pos" select="string(count(preceding::*:ref[ancestor::*:ref-list]) + 1)" />
		<xsl:variable name="cleanPos" select="
			if(string-length($pos) eq 1)
				then(concat('00', $pos))
			else if(string-length($pos) eq 2)
				then(concat('0', $pos))
			else($pos)
		" />
		<bibl xmlns="http://www.tei-c.org/ns/1.0" type="input_file">
			<xsl:attribute name="xml:id" select="
				if(@id)
					then(@id)
				else(concat('bibl', $cleanPos))
			" />
			<xsl:apply-templates select="node()" mode="bibliography"/>
		</bibl>
	</xsl:template>
	
	<xsl:template match="*:mixed-citation" mode="bibliography">
		<xsl:apply-templates select="node()" mode="bibliography"/>
	</xsl:template>

	<xsl:template match="*:bio">
		<div xmlns="http://www.tei-c.org/ns/1.0" type="biography">
			<xsl:attribute name="xml:id" select="
				if(@id)
					then(@id)
				else(concat('bio', count(preceding::*:bio) +1))
			" />
			<xsl:apply-templates select="node()" />
		</div>	
	</xsl:template>

	
	<!-- TYPO -->
	<xsl:template match="*:bold" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="bold"><xsl:apply-templates select="node()" /></hi>
	</xsl:template>

	<xsl:template match="*:italic" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="italic"><xsl:apply-templates select="node()" /></hi>
	</xsl:template>
	
	<xsl:template match="*:underline" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="underline"><xsl:apply-templates select="node()" /></hi>
	</xsl:template>

	<!-- pas d’équivalent dans COMMONS ? -->
	<xsl:template match="*:overline" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="???"><xsl:apply-templates select="node()" /></hi>
	</xsl:template>

	<xsl:template match="*:sc" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="small-caps"><xsl:apply-templates select="node()" /></hi>
	</xsl:template>
	
	<xsl:template match="*:sup" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="sup"><xsl:apply-templates select="node()" /></hi>
	</xsl:template>	

	<xsl:template match="*:sub" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="sub"><xsl:apply-templates select="node()" /></hi>
	</xsl:template>	
	
	<!-- TODO: je me limite aux 4 combinaisons de typo dans tei2nlm mais on en voudra peut-être d’autres… 
		Je pourrai faire en 2 passes : une liste d’élément que je converti en un seul, puis ajout @rend qui fait bien selon combinaison
	-->
	<xsl:template match="*:italic[*:bold and not(text())]|*:bold[*:italic and not(text())]" mode="bibliography #default">
		<hi xmlns="http://www.tei-c.org/ns/1.0" rend="bold italic"><xsl:apply-templates select="element()/node()" /></hi>
	</xsl:template>	
	
	<xsl:template match="*:italic[*:sc and not(text())]|*:sc[*:italic and not(text())]" mode="bibliography #default">
    	<hi xmlns="http://www.tei-c.org/ns/1.0" rend="small-caps italic"><xsl:apply-templates select="element()/node()" /></hi>
  	</xsl:template>
  	
	<xsl:template match="*:italic[*:sup and not(text())]|*:sup[*:italic and not(text())]" mode="bibliography #default">
    	<hi xmlns="http://www.tei-c.org/ns/1.0" rend="sup italic"><xsl:apply-templates select="element()/node()" /></hi>
  	</xsl:template> 

	<xsl:template match="*:italic[*:sub and not(text())]|*:sub[*:italic and not(text())]" mode="bibliography #default">
    	<hi xmlns="http://www.tei-c.org/ns/1.0" rend="sub italic"><xsl:apply-templates select="element()/node()" /></hi>
	</xsl:template>


</xsl:stylesheet>
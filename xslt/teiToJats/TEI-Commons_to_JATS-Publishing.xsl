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
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:mml="http://www.w3.org/1998/Math/MathML"
exclude-result-prefixes="tei xsl xlink xi mml">

<!-- à mettre dans les xsl d’import ?-->
<xsl:output method="xml" indent="no" xpath-default-namespace=""  doctype-public="-//NLM//DTD JATS (Z39.96) Journal Publishing DTD v1.3 20210610//EN" doctype-system="https://jats.nlm.nih.gov/publishing/1.3/JATS-journalpublishing1-3.dtd" />

    <xsl:param name="directory"/>
		
    <!-- TODO:
    	 - valider namespaces
    	 - valider @specific-use="ojs-display", @article-type="research-article"
     -->
	
	<xsl:template match="/">
		<article dtd-version="1.3"
			xmlns:mml="http://www.w3.org/1998/Math/MathML"
			xmlns:xlink="http://www.w3.org/1999/xlink"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			specific-use="ojs-display"
			article-type="research-article">
      		<xsl:if test="//*:profileDesc/*:langUsage/*:language/@ident">
				<xsl:attribute name="xml:lang" select="substring-before(//*:profileDesc/*:langUsage/*:language/@ident,'-')"/>
			</xsl:if>	
    	
    		<front>
    			<xsl:call-template name="journal-meta" />
    			<xsl:call-template name="article-meta" />
    		</front>
    		
    		<xsl:if test="//*:text/*:body">
    			<xsl:call-template name="body" />
    		</xsl:if>    		
    		
    		<!--
    		CUPS:
    		<xsl:if test="descendant::note or TEI/text/back/div[@type='appendix' or 'annexe'] or TEI/text/back/div[@type='bibliographie']">…
    		
    		OVP: je garde l’idée du "if…" mais je suis moins spécifique
    		
    		-->
    		<xsl:if test="descendant::*:note or *:TEI/*:text/*:back/*:div">
    			<xsl:call-template name="back" />
    		</xsl:if>

    	</article>	
	</xsl:template>
	
	<xsl:template name="journal-meta">
		<journal-meta>
			<journal-id  journal-id-type="publisher">
						
			</journal-id>
			<issn>
				<xsl:value-of select="//*:fileDesc/*:seriesStmt/*:idno[@type='issn']"/>
			</issn>			
			<xsl:apply-templates select="//*:publicationStmt/*:ab[@type='expression']/*:bibl/*:publisher" />			
		</journal-meta>
	</xsl:template>	

	<xsl:template match="*:publicationStmt/*:ab[@type='expression']/*:bibl/*:publisher">
		<publisher>
			<publisher-name>
				<xsl:value-of select="
					if(*:choice/*:abbr)
						then(concat(*:choice/*:abbr,' (', *:choice/*:expan, ')'))
					else(.)
				"/>
			</publisher-name>
		</publisher>
	</xsl:template>
	
	<!-- template: article-meta -->
	<xsl:template name="article-meta">
		<article-meta>
			<article-id>
				<!-- @pub-id-type="##" -->
				<xsl:value-of select="*:TEI/@xml:id" />
			</article-id>

			<article-categories>
				<subj-group subj-group-type="##">
					<subject>Research article</subject>
				</subj-group>
			</article-categories>

			<title-group>
				<xsl:apply-templates select="//*:fileDesc/*:titleStmt/*:title" />
			</title-group>
		
			<contrib-group>
				<!-- CUPS:
					@content-type="authors"
				-->
				<xsl:apply-templates select="//*:fileDesc/*:titleStmt/*:author|//*:fileDesc/*:titleStmt/*:editor" />
 				<xsl:apply-templates select="//*:fileDesc/*:titleStmt/*:author/*:affiliation|//*:fileDesc/*:titleStmt/*:editor/*:affiliation" mode="affGroup"/>
			
			</contrib-group>

			<xsl:apply-templates select="//*:fileDesc/*:seriesStmt/*:respStmt"/>

			<!--
			CUPS :
			<xsl:if test="//div[@type='prelim']">
				<author-notes>
					<fn id="afn1">
						<label>*</label>
						<xsl:apply-templates select="//div[@type='prelim']/p"/>
					</fn>
				</author-notes>
			</xsl:if>
			
			OVP: générique ?
			
			-->

			<pub-date>
				<xsl:variable name="pubDate" select="//*:ab[@type='digital_online' and @subtype='HTML']/*:date[@type='publishing']/@when" />
				<xsl:variable name="day" select="substring($pubDate,9,10)" />
				<xsl:variable name="month" select="substring($pubDate,6,7)" />
				<xsl:variable name="year" select="substring($pubDate,1,4)" />
				<xsl:if test="$day!=''">
					<day><xsl:value-of select="$day"/></day>
				</xsl:if>
				<xsl:if test="$month!=''">
					<month><xsl:value-of select="$month"/></month>
				</xsl:if>
				<year><xsl:value-of select="$year"/></year>
			</pub-date>

			<!-- TODO: cas avec plusieurs paginations (ex. : book + epub)--> 		
			
			<xsl:if test="//*:dim[@type='pagination'] != ''">
				<fpage><xsl:value-of select="substring-before(/descendant::*:dim[@type='pagination'][1],'-')"/></fpage>
				<lpage><xsl:value-of select="substring-after(/descendant::*:dim[@type='pagination'][1],'-')"/></lpage>
			</xsl:if>

			<xsl:apply-templates select="//*:ab[@type='editorial_workflow']" />
			
			<!-- NLM
			<xsl:if test="//date[@type='received'] or //date[@type='accepted']">
				<history>
					<xsl:for-each select="//date[@type='received']|//date[@type='accepted']">
						<date date-type="{@type}">
							<day><xsl:value-of select="substring(@when,9,10)"/></day>
							<month><xsl:value-of select="substring(@when,6,7)"/></month>
							<year><xsl:value-of select="substring(@when,1,4)"/></year>
						</date>
					</xsl:for-each>
				</history>
			</xsl:if>
			-->
		
			<!-- CUPS
			<xsl:if test="document($volPath)//tei:group[child::xi:include[contains(@href,$filename)]][@type='review']">
				<product product-type="book">
					<xsl:apply-templates select="//div[@type='recension']/bibl" mode="article-meta"/>
				</product>
			</xsl:if>
			<permissions>
				<copyright-statement>© Éditions de l’EHESS<xsl:if test="$doctype='UEFV'"><xsl:text> </xsl:text><xsl:value-of select="substring(TEI/teiHeader/fileDesc/publicationStmt/ab[@type='CUP']/date,7,4)"/></xsl:if></copyright-statement>
				<copyright-year>
					<xsl:choose>
						<xsl:when test="TEI/teiHeader/fileDesc/publicationStmt/ab[@type='CUP']/date">
							  <xsl:value-of select="substring(TEI/teiHeader/fileDesc/publicationStmt/ab[@type='CUP']/date,7,4)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="substring(document($volPath)//ab[@type='papier']/date[@type='publication'],7,4)"/>
						</xsl:otherwise>
					</xsl:choose>
				</copyright-year>
				<copyright-holder>Éditions de l’EHESS</copyright-holder>
			</permissions> 
			-->	

			<xsl:apply-templates select="//*:ab[@type='expression']/*:bibl/*:availability" />			
			
			<xsl:if test="//*:div[@type='abstract']">
				<xsl:call-template name="resume" />
			</xsl:if>

			<xsl:apply-templates select="*:TEI/*:teiHeader/*:profileDesc" />

			<xsl:if test="//*:titleStmt/*:funder">					
				<funding-group>
					<xsl:apply-templates select="//*:titleStmt/*:funder" />
				</funding-group>
			</xsl:if>		

		</article-meta>
	</xsl:template> 
	
	<xsl:template match="*:TEI/*:teiHeader/*:fileDesc/*:titleStmt/*:title[@type='sup' or @type='short']" />
	
	<xsl:template match="*:TEI/*:teiHeader/*:fileDesc/*:titleStmt/*:title[@type='main']">
		<article-title>
			<xsl:apply-templates select="node()" />
		</article-title>
	</xsl:template>
				
	<xsl:template match="*:TEI/*:teiHeader/*:fileDesc/*:titleStmt/*:title[@type='sub']">
		<subtitle>
			<xsl:apply-templates select="node()" />
		</subtitle>
	</xsl:template>
	
	<xsl:template match="*:TEI/*:teiHeader/*:fileDesc/*:titleStmt/*:title[@type='trl']">
		<trans-title-group xml:lang="{@xml:lang}">
			<trans-title>
				<xsl:apply-templates select="node()"/>
			</trans-title>
		</trans-title-group>
	</xsl:template>

	<xsl:template match="//*:fileDesc/*:titleStmt/*:author|//*:fileDesc/*:titleStmt/*:editor">		
        <contrib>
        	<xsl:attribute name="contrib-type" select="@role" />
        	<xsl:if test="@role='aut rcp'">
        		<xsl:attribute name="corresp" select="'yes'" />
        	</xsl:if>
			<xsl:apply-templates select="*:idno|*:persName/*:idno" />
			<xsl:apply-templates select="*:persName" />
			<role>
				<xsl:value-of select='
        			if(@role="aut")
        				then("Auteur")
        			else if(@role="edt")
        				then("Éditeur scientifique")
        			else if(@role="trl")
        				then("Traducteur")
        			else if(@role="pht")
        				then("Photographe")
        			else if(@role="ill")
        				then("Illustrateur")
        			else if(@role="drm")
        				then("Dessinateur")
        			else if(@role="fld")
        				then("Directeur d’opération")
        			else("##")			
				'/>
			</role>
			<xsl:apply-templates select="*:affiliation|*:email|*:ref" />
		</contrib>
	</xsl:template>	

	<xsl:template match="*:author/*:idno|*:author/*:persName/*:idno|*:editor/*:idno|*:editor/*:persName/*:idno">
		<contrib-id contrib-id-type="{@type}">
			<xsl:value-of select="."/>
		</contrib-id>
	</xsl:template>
	
	<xsl:template match="*:persName">
		<name>
			<xsl:apply-templates select="*:surname" />
			<xsl:apply-templates select="*:forename" />
		</name>
	</xsl:template>

	<xsl:template match="*:surname">
		<surname>
			<xsl:apply-templates select="node()" />
		</surname>
	</xsl:template>
		
	<xsl:template match="*:forename">
		<given-names>
			<xsl:apply-templates select="node()" />
		</given-names>
	</xsl:template>

	<xsl:template match="*:titleStmt//*:affiliation">
		<xsl:variable name="numAff">
			<xsl:text>aff</xsl:text>
			<xsl:if test="(count(preceding::*:affiliation) + 1 ) eq 1">
				<xsl:text>0</xsl:text>
			</xsl:if>
			<xsl:value-of select="count(preceding::*:affiliation) + 1"/>
		</xsl:variable>	
		<aff>
			<xref ref-type="aff" rid="{$numAff}" />
		</aff>		
	</xsl:template>

	<xsl:template match="*:affiliation" mode="affGroup">
		<xsl:variable name="numAff">
			<xsl:text>aff</xsl:text>
			<xsl:if test="(count(preceding::*:affiliation) + 1 ) eq 1">
				<xsl:text>0</xsl:text>
			</xsl:if>
			<xsl:value-of select="count(preceding::*:affiliation) + 1"/>
		</xsl:variable>	
		<aff id="{$numAff}">
			<xsl:choose>
				<xsl:when test="text()[normalize-space(.)]">
					<xsl:apply-templates/>						
				</xsl:when>
				<xsl:when test="*:orgName and not(element()[not(self::*:orgName)])">
					<xsl:apply-templates select="*:orgName" />					
				</xsl:when>
				<xsl:otherwise>
				<institution-wrap>
					<xsl:apply-templates select="*:orgName|*:idno"/>
				</institution-wrap>				
				</xsl:otherwise>
			</xsl:choose>
		</aff>
	</xsl:template>

	<xsl:template match="*:ref[@type='biography']">
		<xsl:variable name="targetBio" select="substring-after(@target, '#')" />
		<bio>
			<xsl:apply-templates select="//*:div[@type='biography' and @xml:id=$targetBio]/node()"/>
		</bio>
	</xsl:template>
	
	<xsl:template match="*:email">
		<email>
			<xsl:apply-templates select="node()" />
		</email>
	</xsl:template>
	
	<!-- OVP: what ? Je ne comprends pas comment ça peut marcher -->
	<xsl:template match="*:TEI/*:teiHeader/*:fileDesc/*:seriesStmt[1]/*:respStmt">
		<contrib-group>
			<xsl:for-each select="name">
                <contrib contrib-type="{../resp}">
					<xsl:apply-templates select="." />
                </contrib>
			</xsl:for-each>
		</contrib-group>
	</xsl:template>

	<xsl:template match="//*:ab[@type='editorial_workflow']">
		<history>
			<xsl:apply-templates select="*:date"/>
		</history>
	</xsl:template>

	<xsl:template match="//*:ab[@type='editorial_workflow']/*:date">
		<date date-type="{@type}">
			<day><xsl:value-of select="replace(., '\d{4}-\d{2}-(\d{2})', '$1')"/></day>
			<month><xsl:value-of select="replace(., '\d{4}-(\d{2})-\d{2}', '$1')"/></month>
			<year><xsl:value-of select="replace(., '(\d{4})-\d{2}-\d{2}', '$1')"/></year>
		</date>
	</xsl:template>

	<xsl:template match="//*:ab[@type='expression']/*:bibl/*:availability">
		<permissions>
			<xsl:apply-templates select="*:licence" />
		</permissions>
	</xsl:template>

	<xsl:template match="//*:ab[@type='expression']/*:bibl/*:availability/*:licence">
		<license xlink:href="{@target}">
			<xsl:apply-templates select="*:p" />
		</license>
	</xsl:template>
	
	<xsl:template match="//*:ab[@type='expression']/*:bibl/*:availability/*:licence/*:p">
		<license-p>
			<xsl:apply-templates select="node()" />
		</license-p>
	</xsl:template>

	<xsl:template name="resume">
		<xsl:variable name="mainLang" select="substring-before(//*:langUsage/*:language/@ident, '-')" />
		<abstract>
 			<!-- CUPS
 			abstract-type="normal">
            <title>
        	    <xsl:value-of select="
        	    	if(//language/@ident='en-EN')
						then('Abstract')
					else('Résumé')
				"/>
            </title>
			-->
			<xsl:apply-templates select="//*:div[@type='abstract' and (@xml:lang=$mainLang or not(@xml:lang))]/node()" />
		</abstract>
		<xsl:for-each select="//*:div[@type='abstract' and @xml:lang and @xml:lang!=$mainLang]">
			<trans-abstract xml:lang="{@xml:lang}">
				<xsl:apply-templates select="node()" />
			</trans-abstract>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="*:profileDesc"><xsl:apply-templates /></xsl:template>
	<xsl:template match="*:textClass"><xsl:apply-templates /></xsl:template>
	<xsl:template match="*:keywords">
    	<kwd-group kwd-group-type="author-keywords">
			<xsl:if test="@xml:lang">
				<xsl:attribute name="xml:lang" select="@xml:lang" />
			</xsl:if>
			<xsl:for-each select="*:list/*:item">
				<kwd>
					<xsl:apply-templates select="node()" />
				</kwd>
			</xsl:for-each>
		</kwd-group>
	</xsl:template>

	<xsl:template match="*:funder">
		<award-group>
			<funding-source>
				<institution-wrap>
					<xsl:apply-templates select="*:orgName|*:idno[@type='funder_registry']"/>
				</institution-wrap>
			</funding-source>
			<xsl:if test="*:idno[@type='awardnumber']">
				<award-id>
					<xsl:apply-templates select="*:idno[@type='awardnumber']/node()"/>
				</award-id>
			</xsl:if>
		</award-group>
	</xsl:template>

	<xsl:template match="*:orgName">
		<institution>
			<xsl:apply-templates select="node()" />
		</institution>
	</xsl:template>

	<xsl:template match="*:affiliation/*:idno|*:funder/*:idno[@type='funder_registry']">
		<institution-id institution-id-type="{@type}">
			<xsl:apply-templates select="node()" />
		</institution-id>	
	</xsl:template>

	<!--      -->
	<!-- BODY -->
	<!--      -->
	<xsl:template name="body">
		<body>	
			<xsl:apply-templates select="//*:front/*[not(@type='titlePage' or @type='abstract' or @type='keywords')]" />			
			<xsl:apply-templates select="*:TEI/*:text/*:body/node()" />
		</body>
	</xsl:template>

	<xsl:template match="
		*:note[@type='pbl']
		|*:note[@type='aut']
		|*:note[@type='trl']
		|*:div[@type='correction']
		|*:div[@type='dedication']
		|*:div[@type='ack']
		|*:argument
		|*:div[@type='inst-partner']
		|*:div[@type='data']
		|*:div[@type='publication']">
		<xsl:variable name="content-type" select="
			if(@type)
				then(@type)
			else('argument')"/>
		<xsl:apply-templates select="*:p" mode="front">
			<xsl:with-param name="content-type" select="$content-type" />
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="*:p" mode="front">
		<xsl:param name="content-type" />
		<p content-type="{$content-type}">
			<xsl:apply-templates select="node()" />
		</p>
	</xsl:template>
	
	<xsl:template match="*:epigraph">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- je crois que je n’ai rien oublié ? -->
	<xsl:template match="*:div[not(
		@xml:id='mainDiv'
		or @type='prelim'
		or @type='encadre'
		or @type='appendix'
		or @type='annexe'
		or @type='bibliographie'
		or @type='bibliography'
	)]">
		<!-- CUPS
		<xsl:variable name="count">
			<xsl:number count="div[contains(@type,'section')]" level="any" from="/"/> 
		</xsl:variable>
		-->
		<xsl:element name="sec">
			<!-- CUPS
			<xsl:attribute name="id">
				<xsl:value-of select="concat('sec',$count)"/>
			</xsl:attribute>
			<xsl:attribute name="sec-type">other</xsl:attribute>
			-->
			<xsl:if test="not(child::*:head)"><title></title></xsl:if>
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>

	<xsl:template match="*:div/*:head|*:listBibl/*:head">
    	<xsl:choose>
        	<xsl:when test="ancestor::*:floatingText">
            	<caption>
                	<title>
                    	<xsl:apply-templates/>
                	</title>
            	</caption>
        	</xsl:when>
        	<xsl:otherwise>
            	<title>
            		<xsl:apply-templates />
            	</title>
        	</xsl:otherwise>
    	</xsl:choose>
	</xsl:template>

	<xsl:template match="*:p | *:ab">
    	<xsl:choose>
<!-- 
        	<xsl:when test="parent::div[@type='resume_motscles']">     
            	<xsl:apply-templates/>
        	</xsl:when>
 -->
        	<xsl:when test="child::*:code">
            	<xsl:apply-templates/>
        	</xsl:when>
        	<xsl:when test="parent::*:sp">
            	<xsl:apply-templates/>
        	</xsl:when>
        	<xsl:otherwise>
            	<xsl:element name="p">
            		<xsl:apply-templates />
				</xsl:element>
        	</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*:list">
    	<list>
    		<xsl:if test="@type">
        		<xsl:attribute name="list-type" select="@type" />
      		</xsl:if>
      		<xsl:apply-templates />
    	</list>
  	</xsl:template>

	<xsl:template match="*:list/*:item">
    	<list-item>
    		<p>
        		<xsl:apply-templates />
      		</p>
    	</list-item>
	</xsl:template>



	<!--							-->
	<!--	figures, tables, etc…	-->
	<!--							-->
	
	<!-- TODO:
			- images block
			- images inline
			- tableaux: ok
			- formules block
			- formules inline
	-->


	<!-- images -->		
	<xsl:template match="*:figure[@rend='inline'][not(*:formula)]">
		<inline-graphic>
			<xsl:if test="@xml:id">
				<xsl:attribute name="id" select="@xml:id" />
			</xsl:if>
			<xsl:attribute name="xlink:href" select="concat('data/', substring-after(*:graphic/@url, '/br/'))" />
			<xsl:apply-templates select="*:figDesc" />
		</inline-graphic>
	</xsl:template>	
	
	<xsl:template match="*:figure[not(@rend='inline')][not(*:formula) and not(*:table)]">
		<fig>
			<xsl:if test="@xml:id">
				<xsl:attribute name="id" select="@xml:id" />
			</xsl:if>
			<xsl:if test="*:head or *:p[@rend='caption']">
				<caption>
					<xsl:apply-templates select="*:head|*:p[@rend='caption']" />
				</caption>
			</xsl:if>
			<xsl:apply-templates select="*:figDesc" />
			<xsl:apply-templates select="*:graphic" />
			<xsl:apply-templates select="*:p[@rend='credits']" />
		</fig>
	</xsl:template>	

	<!-- tableaux	
	TODO: graphic pour image du tableau ?
	-->
	<!-- NLM
	<xsl:template match="*:figure[*:table]">
		<xsl:apply-templates select="*:table" />
		<xsl:apply-templates select="*:head|*:p" />
	</xsl:template>

    <xsl:template match="*:table">
		<table-wrap>
        	<xsl:if test="@rend">
          		<xsl:attribute name="specific-use" select="@rend"/>
        	</xsl:if>
          	<xsl:if test="@xml:id">
          		<xsl:attribute name="id" select="concat('tab',count(preceding::*:table)+1)" />
          	</xsl:if>
        	<table>
            	<xsl:apply-templates/>
        	</table>
      	</table-wrap>
    </xsl:template>
	-->

	<xsl:template match="*:figure[*:table]">
		<table-wrap>
            <xsl:if test="@xml:id">
				<xsl:attribute name="id" select="@xml:id" />
			</xsl:if>
            <xsl:if test="*:head or *:p[@rend='caption']">
				<caption>
					<xsl:apply-templates select="*:head|*:p[@rend='caption']" />
				</caption>
			</xsl:if>
			<xsl:apply-templates select="*:figDesc" />
			<xsl:apply-templates select="*:table" />
			<xsl:apply-templates select="*:p[@rend='credits']" />
      	</table-wrap>		
	</xsl:template>

    <xsl:template match="*:table">
		<table>
            <xsl:apply-templates select="node()" />
        </table>
    </xsl:template>

	<xsl:template match="*:table/*:row">
		<tr>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>
    
	<xsl:template match="*:table/*:row/*:cell">
		<xsl:choose>
        	<xsl:when test="parent::*:row/@role='label'">
       			<th>
					<xsl:apply-templates />
				</th>
			</xsl:when>
			<xsl:otherwise>
        		<td>
            		<xsl:if test="@rows">
                		<xsl:attribute name="rowspan" select="@rows"/>
              		</xsl:if>
              		<xsl:if test="@cols">
                  		<xsl:attribute name="colspan" select="@cols"/>
              		</xsl:if>
            		<xsl:apply-templates />
          		</td>
        	</xsl:otherwise>
      	</xsl:choose>
	</xsl:template>

	<xsl:template match="*:figure/*:head">
		<!-- NLM
		<p content-type="table-caption">
			<xsl:apply-templates select="node()" />
		</p>
		-->
		<title>
			<xsl:apply-templates select="node()" />
		</title>
	</xsl:template>
	
	<xsl:template match="*:figure/*:p[@rend='caption']">
		<!-- NLM
		<p content-type="table-legend">
			<xsl:apply-templates select="node()" />
		</p>
		-->
		<p>
			<xsl:apply-templates select="node()" />
		</p>
	</xsl:template>
	
	<!-- TODO: desc et bibl ?
	<p rend="credits">Surletoit - <desc>Créditslicence Creative Commons by-nc-sa</desc> - <bibl>sources</bibl></p>	
	-->
	<xsl:template match="*:figure/*:p[@rend='credits']">
		<!-- NLM
		<p content-type="table-credits">
			<xsl:apply-templates select="node()" />
		</p>
		-->
		<attrib>
			<xsl:apply-templates select="node()" />		
		</attrib>
	</xsl:template>

	<xsl:template match="*:figDesc">
		<alt-text>
			<xsl:apply-templates select="node()" />
		</alt-text>
	</xsl:template>

	<xsl:template match="*:graphic">
		<xsl:variable name="url" select="concat('data/', substring-after(@url, '/br/'))"/>
		<graphic xlink:href="{$url}" />
	</xsl:template>	

	<!-- maths -->
	<xsl:template match="*:figure[*:formula]">
		<xsl:variable name="notation" select="
			if(*:formula/@notation='latex' or *:formula/@notation='tex')
				then('math/tex')
			else if(*:formula/@notation='mathml' or *:formula/@notation='mml')
				then('math/mathml')
			else('##')"
		/>
		<xsl:choose>
			<xsl:when test="@rend='inline'">
				<inline-formula>
           	 		<xsl:attribute name="content-type" select="$notation"/>
           	 		<alternatives>
           	 			<xsl:apply-templates select="node()" />
           	 		</alternatives>
            	</inline-formula>
			</xsl:when>
			<xsl:otherwise>
				<disp-formula>
					<xsl:attribute name="content-type" select="$notation"/>
           	 		<alternatives>
           	 			<xsl:apply-templates select="node()" />
           	 		</alternatives>
				</disp-formula>
			</xsl:otherwise>
		</xsl:choose>		
	</xsl:template>	
	
	<xsl:template match="*:formula[@notation='latex' or @notation='tex']">
		<tex-math>
           	 <xsl:apply-templates select="node()" />
        </tex-math>	
	</xsl:template>	

	<xsl:template match="*:formula[@notation='mathml' or @notation='mml']">
        <xsl:apply-templates select="node()" />
	</xsl:template>	
	
	<xsl:template match="*:formula//element()">
		<xsl:copy-of select="." />
	</xsl:template>
	
	<xsl:template match="*:figure[@rend='inline']/*:formula/*:graphic">
		<xsl:variable name="url" select="concat('data/', substring-after(@url, '/br/'))"/>
		<inline-graphic xlink:href="{$url}" />
	</xsl:template>
	

	
	<!--<xsl:template match="@*">
		<xsl:copy-of select="." />
	</xsl:template>-->

	<xsl:template match="@xml:id"><xsl:attribute name="id" select="." /></xsl:template>

	<xsl:template match="@xml:lang"><xsl:copy-of select="." /></xsl:template>

	<xsl:template match="*:cit">
		<xsl:apply-templates select="node()" />
	</xsl:template>

	<xsl:template match="*:quote">
		<xsl:choose>
			<xsl:when test="ancestor::*:p">
				<named-content content-type="inline_quotation">
					<xsl:apply-templates />
				</named-content>
        	</xsl:when>
        	<xsl:when test="parent::*:epigraph">
    			<disp-quote>
					<p>
						<xsl:attribute name="content-type">epigraph</xsl:attribute>
						<xsl:apply-templates />
					</p>
				</disp-quote>
			</xsl:when>
			<xsl:otherwise>
				<disp-quote>
					<xsl:if test="parent::*:cit/@type">
						<xsl:attribute name="specific-use" select="parent::*:cit/@type" />
					</xsl:if>
					<xsl:if test="@type">
						<xsl:attribute name="specific-use" select="@type" />
					</xsl:if>
					<xsl:choose>
						<xsl:when test="text()[normalize-space(.)] or *:seg">
							<p>
								<xsl:apply-templates/>
							</p>						
						</xsl:when>
						<xsl:when test="count(*:label) gt 1">
							<xsl:for-each-group select="node()" group-starting-with="*:label">
								<disp-quote>
									<xsl:apply-templates select="current-group()" />
								</disp-quote>		
							</xsl:for-each-group>
						</xsl:when>
						<xsl:when test="count(*:num) gt 1">
							<xsl:for-each-group select="node()" group-starting-with="*:num">
								<disp-quote>
									<xsl:apply-templates select="current-group()" />
								</disp-quote>		
							</xsl:for-each-group>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates />
						</xsl:otherwise>
					</xsl:choose>
				</disp-quote>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*:gloss">
		<statement content-type="gloss">
			<p>
				<xsl:apply-templates select="node()" />
			</p>
		</statement>		
	</xsl:template>
	
	<xsl:template match="*:quote/*:label">
		<label>
			<xsl:apply-templates select="node()" />
		</label>
	</xsl:template>
	
	<xsl:template match="*:quote/*:num">
		<label>
			<xsl:apply-templates select="node()" />
			<xsl:if test="following-sibling::*[1][self::*:lang]">
				<xsl:text> </xsl:text>
				<xsl:apply-templates select="following-sibling::*[1][self::*:lang]/node()" />
			</xsl:if>
		</label>
	</xsl:template>
	
	<xsl:template match="*:quote/*:lang" />	
	
	<xsl:template match="*:quote/*:seg">
		<named-content content-type="seg">
			<xsl:apply-templates select="node()" />
		</named-content>
	</xsl:template>
	
	<xsl:template match="*:cit/*:bibl">
		<attrib>
			<xsl:apply-templates select="node()" />
		</attrib>
	</xsl:template>

	<xsl:template match="*:quote/*:bibl[@rend='inline']">
		<named-content content-type="attrib">
			<xsl:apply-templates select="node()" />
		</named-content>
	</xsl:template>

	<xsl:template match="*:ref">
		<xsl:choose>
			<!-- Internal reference. -->
			<xsl:when test="starts-with(@target, '#')">
				<xref>
					<xsl:variable name="targId" select="substring-after(@target, '#')" />
					<xsl:attribute name="rid" select="$targId" />
					<xsl:if test="@type='affiliation'">
						<xsl:attribute name="ref-type">aff</xsl:attribute>
					</xsl:if>
<!-- If it's a reference to a biblStruct element in the back matter, then it should
be given the recommended @ref-type. -->
					<xsl:if test="//back//biblStruct[@xml:id = $targId]">
						<xsl:attribute name="ref-type">bibr</xsl:attribute>
					</xsl:if>
<!-- lien ref. bibl -->
					<xsl:if test="@type='bibl'">
						<xsl:attribute name="ref-type">bibr</xsl:attribute>
					</xsl:if> 
				  	<!-- NLM
				  	<xsl:if test="@type='fig'">
						<xsl:attribute name="ref-type">fig</xsl:attribute>
				  	</xsl:if>
				  	-->
					<xsl:apply-templates />
				</xref>
			</xsl:when>
			<!-- External reference. -->
			<xsl:otherwise>
				<ext-link>
					<xsl:attribute name="xlink:href" select="@target" />
					<xsl:apply-templates />
				</ext-link>
    		</xsl:otherwise>
    	</xsl:choose>
	</xsl:template>

	<xsl:template match="*:choice[*:abbr]">
    	<xsl:apply-templates select="*:abbr" />
    </xsl:template>

	<xsl:template match="*:abbr">
    	<xsl:choose>
    		<xsl:when test="not(ancestor::*:ref)">
        		<abbrev>
        			<xsl:apply-templates />
        			<xsl:if test="preceding-sibling::*:expan">
        				<def>
        					<p>
        						<xsl:apply-templates select="preceding-sibling::*:expan[1]" />
        					</p>
        				</def>
        			</xsl:if>
        			<xsl:if test="following-sibling::*:expan">
        				<def>
        					<p>
        						<xsl:apply-templates select="following-sibling::*:expan[1]" />
        					</p>
        				</def>
        			</xsl:if>
				</abbrev>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="." />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*:name[@type='person' or not(@type)][not(ancestor::*:div)]">
    	<!-- TODO: euh, c’est quoi cette façon de séparer nom/prénom ?-->
    	<xsl:element name="name">
    		<surname><xsl:value-of select="substring-after(.,' ')" /></surname>
			<given-names><xsl:value-of select="substring-before(.,' ')" /></given-names>
		</xsl:element>
	</xsl:template>

	<xsl:template match="name[@type='person' or not(@type)][ancestor::div]">
		<xsl:element name="named-content">
			<xsl:attribute name="content-type">person</xsl:attribute>
			<xsl:value-of select="." />
		</xsl:element>
	</xsl:template>

	<xsl:template match="*:affiliation/name[@type='org']">
		<institution>
			<xsl:value-of select="." />
		</institution>
	</xsl:template>

	<xsl:template match="*:name[@type and not(@type='person')][ancestor::*:div]">
		<named-content>
			<xsl:attribute name="content-type" select="@type" />
			<xsl:apply-templates />
		</named-content>
	</xsl:template>
  	
  	<xsl:template match="*:note">
		<xsl:element name="xref">
    		<xsl:attribute name="ref-type"><xsl:text>fn</xsl:text></xsl:attribute>
			<xsl:attribute name="rid">
				<xsl:value-of select="concat('fn',substring-after(@xml:id,'ftn'))"/>
			</xsl:attribute>
			<!-- CUPS
			xsl:element name="sup"-->
			<xsl:value-of select="substring-after(@xml:id,'ftn')"/>
			<!--/xsl:element-->
		</xsl:element>
	</xsl:template>	

	<xsl:template match="*:lg">
    	<verse-group>
    		<xsl:apply-templates />
    	</verse-group>
	</xsl:template>

	<xsl:template match="*:l">
    	<verse-line>
    		<xsl:apply-templates />
    	</verse-line>
	</xsl:template>

	
	<!--      -->
	<!-- BACK -->
	<!--      -->
	<xsl:template name="back">
		<back>
			<xsl:if test="//*:note">
				<xsl:call-template name="footnotesGroup" />
			</xsl:if>
			<!-- TODO: je suppose que l’ordre est contraint ? Sinon un seul back/div… -->
			<xsl:apply-templates select="*:TEI/*:text/*:back/*:div[@type='appendix' or @type='annexe']" />
			<xsl:apply-templates select="*:TEI/*:text/*:back/*:div[@type='bibliography' or @type='bibliographie']" />  		
		</back>
	</xsl:template>

	<!-- Notes de fin -->
	<xsl:template name="footnotesGroup">
		<fn-group>
			<xsl:apply-templates select="//*:note[not(
				@type='aut'
				or @type='pbl'
				or @type='trl')]" mode="back" />
		</fn-group>
	</xsl:template>

	<xsl:template match="*:note" mode="back">
    	<fn fn-type="other">
			<xsl:attribute name="id">
        		<xsl:value-of select="concat('fn',substring-after(@xml:id,'ftn'))"/>
      		</xsl:attribute>
			<xsl:element name="label">
				<xsl:value-of select="substring-after(@xml:id,'ftn')"/>
			</xsl:element>
			<xsl:choose>
				<xsl:when test="not(child::*:p)">
          			<p>
            			<xsl:apply-templates />
          			</p>
        		</xsl:when>
        		<xsl:otherwise>
          			<xsl:apply-templates />
        		</xsl:otherwise>
      		</xsl:choose>
    	</fn>
  	</xsl:template>

	<!-- WAD ?-->
	<xsl:template match="//*:back/*:div[@type='appendix' or @type='annexe']">
		<app-group>
			<xsl:apply-templates select="node()" />
	  	</app-group>
	</xsl:template>

	<xsl:template match="//*:back/*:div[@type='appendix' or @type='annexe']/*:div">
		<app>
			<xsl:if test="@xml:id">
				<xsl:attribute name="id" select="@xml:id" />
			</xsl:if>
			<xsl:apply-templates select="node()" />
  		</app>	
	</xsl:template>
	
	<xsl:template match="*:div[@type='appendix' or @type='annexe']/*:floatingText|*:div[@type='appendix' or @type='annexe']/*:floatingText/*:group">
		<xsl:apply-templates select="node()" />
	</xsl:template>
	
	<xsl:template match="*:div[@type='appendix' or @type='annexe']//xi:include">
		<xsl:variable name="ref" select="@href"/>
        <xsl:variable name="pathtoInclude" select="concat($directory,'/',$ref)"/>
        <app>
			<label>
				<xsl:apply-templates select="document($pathtoInclude)//*:titleStmt/*:title[@type='main']/node()"/>
			</label>
			<xsl:apply-templates select="document($pathtoInclude)//*:body/node()"/>
		</app>
	</xsl:template>

	<xsl:template match="//*:back/*:div[@type='bibliographie' or @type='bibliography']">
		<ref-list>
			<title><xsl:apply-templates select="*:head/node()" /></title>
			<xsl:apply-templates select="*:listBibl|*:bibl" />
	  	</ref-list>
	</xsl:template> 

	<xsl:template match="*:listBibl[*:head]">
		<ref-list>
			<xsl:apply-templates select="node()" />
	  	</ref-list>
	</xsl:template> 	

	<xsl:template match="*:listBibl[not(*:head)]">
		<xsl:apply-templates select="node()" />
	</xsl:template> 
	
	<!-- Bibliographies -->
	<xsl:template match="*:div[@type='bibliographie' or @type='bibliography']//*:bibl">
		<ref id="{@xml:id}">
			<mixed-citation><xsl:apply-templates select="node()" /></mixed-citation>
		</ref>
	</xsl:template>

	<xsl:template match="*:listBibl/*:biblStruct">
    	<ref id="{@xml:id}">
			<element-citation publication-type="{@type}">
				<xsl:if test="analytic">
					<person-group person-group-type="author">
            			<!-- TODO: hum ? -->
            			<xsl:for-each select="*:analytic/*:author/*:name">
              				<name>
                				<surname><xsl:apply-templates select="*:surname" /></surname>
                				<given-names><xsl:apply-templates select="*:forename" /></given-names>
              				</name>
            			</xsl:for-each>
          			</person-group>
					<xsl:choose>
						<xsl:when test="@type='book'">
							<chapter-title>
								<xsl:apply-templates select="*:analytic/*:title" />
							</chapter-title>
						</xsl:when>
            			<xsl:otherwise>
            				<article-title>
            					<xsl:apply-templates select="*:analytic/*:title" />
            				</article-title>
            			</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<xsl:if test="*:monogr">
					<xsl:for-each select="*:monogr/*:title[@level='m' or @level='u' or @level='j']">
            			<source><xsl:value-of select="." /></source>
					</xsl:for-each>
					<xsl:for-each select="*:monogr/*:title[@level='s']">
            			<series><xsl:value-of select="." /></series>
					</xsl:for-each>
					<xsl:if test="*:monogr/*:author">
						<person-group person-group-type="author">
             				<xsl:for-each select="*:monogr/*:author/*:name">
                				<name>
                  					<surname><xsl:apply-templates select="*:surname" /></surname>
                  					<given-names><xsl:apply-templates select="*:forename" /></given-names>
                				</name>
              				</xsl:for-each>
            			</person-group>
          			</xsl:if>
          			<xsl:if test="*:monogr/*:editor">
            			<person-group person-group-type="editor">
              				<xsl:for-each select="*:monogr/*:editor/*:name">
                				<name>
                  					<surname><xsl:apply-templates select="*:surname" /></surname>
                  					<given-names><xsl:apply-templates select="*:forename" /></given-names>
                				</name>
              				</xsl:for-each>
            			</person-group>
            			<xsl:if test="*:edition">
              				<edition><xsl:apply-templates select="node()" /></edition>
            			</xsl:if>
          			</xsl:if>
					<xsl:for-each select="*:monogr/*:idno">
            			<xsl:choose>
              				<xsl:when test="@type='ISSN'">
                				<issn><xsl:value-of select="." /></issn>
              				</xsl:when>
              				<xsl:when test="@type='ISBN'">
                				<isbn><xsl:value-of select="." /></isbn>
              				</xsl:when>
            			</xsl:choose>
          			</xsl:for-each>
					<xsl:apply-templates select="*:monogr/*:imprint" />
				</xsl:if>
				<xsl:apply-templates select="descendant::*:respStmt" />
			</element-citation>
		</ref>
	</xsl:template>

	<xsl:template match="*:biblStruct/*:monogr/*:imprint">
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="*:publisher">
		<publisher-name>
			<xsl:apply-templates />
		</publisher-name>
	</xsl:template>

	<xsl:template match="*:pubPlace">
    	<publisher-loc>
    		<xsl:apply-templates />
    	</publisher-loc>
	</xsl:template>

	<xsl:template match="*:biblStruct/*:monogr/*:imprint/*:date">
    	<year><xsl:value-of select="substring(@when, 1, 4)" /></year>
		<xsl:if test="string-length(@when) gt 6">
      		<month><xsl:value-of select="substring(@when, 6, 2)" /></month>
      		<xsl:if test="string-length(@when) gt 9">
        		<day><xsl:value-of select="substring(@when, 9, 2)" /></day>
      		</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template match="*:biblStruct/*:monogr/*:imprint/*:biblScope">
    	<xsl:choose>
    		<xsl:when test="@type='vol'">
        		<volume><xsl:value-of select="." /></volume>
      		</xsl:when>
      		<xsl:when test="@type='issue'">
        		<issue><xsl:value-of select="." /></issue>
      		</xsl:when>
      		<xsl:when test="@type='pp'">
        		<fpage><xsl:value-of select="substring-before(., '-')"/></fpage>
        		<lpage><xsl:value-of select="substring-after(., '-')"/></lpage>
			</xsl:when>
			<xsl:otherwise>
				<comment><xsl:value-of select="." /></comment>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*:biblStruct//*:note">
		<comment><xsl:value-of select="." /></comment>
	</xsl:template>

	<xsl:template match="*:respStmt[ancestor::biblStruct]">
    	<person-group person-group-type="{resp}">
			<xsl:for-each select="name">
				<name>
                	<surname><xsl:apply-templates select="surname" /></surname>
                	<given-names><xsl:apply-templates select="forename" /></given-names>
                </name>
			</xsl:for-each>
		</person-group>
	</xsl:template>

	<xsl:template match="*:soCalled">
		<styled-content style-type="scare quotes" style="::before: content(open-quote); ::after: content(close-quote);">
			<xsl:apply-templates />
		</styled-content>
	</xsl:template>

	<xsl:template match="*:mentioned">
		<styled-content style-type="mentioned" style="font-style: italic;">
			<xsl:apply-templates />
		</styled-content>
	</xsl:template>

	<xsl:template match="*:tag">
		<styled-content style-type="XML tag" style="::before: content(&lt;); ::after: content(&gt;); font-family: monospace;">
      		<xsl:apply-templates />
		</styled-content>
	</xsl:template>
	
	<xsl:template match="*:term">		
		<!-- NLM
		<index-term>
			<xsl:choose>
				<xsl:when test="contains(parent::index/@indexName,':')">
					<term>
						<xsl:value-of select="substring-before(parent::index/@indexName,':')"/>
						<index-term>
							<term><xsl:value-of select="substring-after(parent::index/@indexName,':')"/></term>
						</index-term>
					</term>
				</xsl:when>
				<xsl:otherwise>
					<term><xsl:value-of select="parent::index/@indexName"/></term>
				</xsl:otherwise>
			</xsl:choose>
			<index-term>
				<term><xsl:value-of select="."/></term>
			</index-term>
		</index-term>
		-->

		<!-- CUPS
    	<styled-content style-type="term" style="font-style: italic;">
    		<xsl:apply-templates />
    	</styled-content>
		-->				
	</xsl:template>	
	

	<!-- 				-->
	<!-- Métopes custom -->
	<!-- 				-->    
	<xsl:template match="*:floatingText">
    	<boxed-text>
        	<xsl:apply-templates/>
    	</boxed-text>
	</xsl:template>

	<xsl:template match="*:floatingText//xi:include">
		<xsl:variable name="ref" select="@href"/>
        <xsl:variable name="pathtoInclude" select="concat($directory,'/',$ref)"/>
        <label>
			<xsl:apply-templates select="document($pathtoInclude)//*:titleStmt/*:title[@type='main']/node()"/>
		</label>
		<xsl:apply-templates select="document($pathtoInclude)//*:body/node()"/>
	</xsl:template>

	<xsl:template match="*:code">
    	<code>
        	<xsl:apply-templates/>
    	</code>
	</xsl:template>

	<xsl:template match="*:sp">
    	<p>
    		<xsl:if test="@rend">
    			<xsl:attribute name="content-type" select="@rend"/>
    		</xsl:if>
        	<xsl:apply-templates/>
    	</p>
	</xsl:template>

	<xsl:template match="*:speaker">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- TODO: voir quoi décommenter -->
	<!--
	<xsl:template match="tei:p[@style='txt_Resume']"/>
	<xsl:template match="tei:p[@style='txt_Resume_italique']"/>
	<xsl:template match="tei:p[@style='txt_resume_inv']"/>
	<xsl:template match="tei:p[@style='txt_Motclef']"/>
	<xsl:template match="tei:p[@style='txt_Motclef_italique']"/>
	<xsl:template match="tei:p[@style='txt_Keywords']"/>
	<xsl:template match="tei:p[@style='txt_motscles_inv']"/>
	-->


<!-- Line breaks are equivalent to <break/>, but cannot appear in paragraphs
     What nonsense. -->
	<xsl:template match="*:lb">
		<xsl:comment>There should be a line-break here.</xsl:comment>
	</xsl:template>

	<xsl:template match="*:title[not(ancestor::*:biblStruct) and not(ancestor::*:teiHeader)]">
		<named-content content-type="title_level_{@level}">
			<xsl:choose>
				<xsl:when test="@level='m' or @level='j'">
					<italic><xsl:apply-templates /></italic>
				</xsl:when>
				<xsl:when test="@level='a'">
					&quot;<xsl:apply-templates />&quot;
				</xsl:when>
			</xsl:choose>
		</named-content>
	</xsl:template>

	<xsl:template match="*:hi[@rend='bold']">
		<xsl:element name="bold"><xsl:apply-templates /></xsl:element>
	</xsl:template>

	<xsl:template match="*:hi[@rend='italic bold']">
		<xsl:element name="italic">
			<xsl:element name="bold"><xsl:apply-templates /></xsl:element>
		</xsl:element>
	</xsl:template>

	<xsl:template match="*:hi[@rend='italic']">
    	<xsl:element name="italic"><xsl:apply-templates /></xsl:element>
	</xsl:template>
	
	<xsl:template match="*:hi[@rend='underline']">
    	<xsl:element name="underline"><xsl:apply-templates /></xsl:element>
	</xsl:template>
	
	<xsl:template match="*:hi[@rend='overline']">
    	<xsl:element name="overline"><xsl:apply-templates /></xsl:element>
	</xsl:template>

	<xsl:template match="*:hi[@rend='small-caps']">
    	<xsl:element name="sc"><xsl:apply-templates /></xsl:element>
	</xsl:template>

	<xsl:template match="*:hi[@rend='small-caps italic']">
    	<xsl:element name="sc">
    		<xsl:element name="italic"><xsl:apply-templates /></xsl:element>
    	</xsl:element>
	</xsl:template>

	<xsl:template match="*:hi[@rend='sup']">
    	<xsl:element name="sup"><xsl:apply-templates /></xsl:element>
	</xsl:template>

	<xsl:template match="*:hi[@rend='sup italic']">
    	<xsl:element name="sup">
    		<xsl:element name="italic"><xsl:apply-templates /></xsl:element>
    	</xsl:element>
	</xsl:template> 
	
	<xsl:template match="*:hi[@rend='sub']">
    	<xsl:element name="sub"><xsl:apply-templates /></xsl:element>
	</xsl:template>
	
	<xsl:template match="*:hi[@rend='sub italic']">
    	<xsl:element name="italic">
    		<xsl:element name="sub"><xsl:apply-templates /></xsl:element>
    	</xsl:element>
	</xsl:template>


  	<xsl:function name="tei:resolveURI" as="xs:string">
    	<xsl:param name="context"/>
    	<xsl:param name="target"/>
    	<xsl:analyze-string select="normalize-space($target)" regex="^(\w+):(.+)$">
      		<xsl:matching-substring>
        		<xsl:variable name="prefix" select="regex-group(1)"/>
        		<xsl:variable name="value" select="regex-group(2)"/>
        		<xsl:choose>
          			<xsl:when test="$context/ancestor::*/tei:teiHeader/tei:encodingDesc/tei:listPrefixDef/tei:prefixDef[@ident=$prefix]">
            			<xsl:variable name="result">
              				<xsl:for-each select="($context/ancestor::*/tei:teiHeader/tei:encodingDesc/tei:listPrefixDef/tei:prefixDef[@ident=$prefix])[1]">
                				<xsl:sequence select="replace($value,@matchPattern,@replacementPattern)"/>
              				</xsl:for-each>
            			</xsl:variable>
            			<xsl:choose>
              				<xsl:when test="$result=''">
                				<xsl:message terminate="yes">prefix pattern/replacement applied to <xsl:value-of select="$value"/> returns an empty result</xsl:message>
              				</xsl:when>
              				<xsl:otherwise>
                				<xsl:sequence select="$result"/>
              				</xsl:otherwise>
            			</xsl:choose>
          			</xsl:when>
          			<xsl:otherwise>
            			<xsl:sequence select="."/>
          			</xsl:otherwise>
        		</xsl:choose>
      		</xsl:matching-substring>
      		<xsl:non-matching-substring>
				<xsl:variable name="base" select="$context/ancestor-or-self::*[@xml:base][1]/@xml:base"/>
        		<xsl:sequence select="
        			if (starts-with($base,'file:'))
        				then $target
        			else concat($base,$target)
        		"/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:function>

</xsl:stylesheet>
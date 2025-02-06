<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Code source sous licence CECILL-C. Veuillez vous référer au fichier LICENSE.txt pour plus d'informations
Source code under CECILL-C licence. Please refer to the LICENSE.txt file for more information.
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

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:template>
	
	<!-- TODO: à quelle div commence-t-on à compter ? quelle cit (epigraph compte ?)
		-> dans le body
	Attention pour les listes, il y en a dans le header -->
	<xsl:template match="*:body//*:div|*:back//*:div|*:figure|*:table|*:cit|*:text//*:list">
		<xsl:variable name="nodeType" select="local-name()" />
		<xsl:variable name="order" select="count(preceding::*[local-name()=$nodeType][not(ancestor::*:front or ancestor::*:teiHeader)]) + count(ancestor::*[local-name()=$nodeType]) + 1" />
		<xsl:copy>
			<xsl:attribute name="xml:id" select="
				if(@xml:id)
					then(@xml:id)
				else(concat($nodeType, $order))
			" />
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>
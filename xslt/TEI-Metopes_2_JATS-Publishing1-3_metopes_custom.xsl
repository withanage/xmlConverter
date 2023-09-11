<?xml version="1.0" encoding="utf-8"?>

<!-- 
Code source sous licence CECILL-C. Veuillez vous référer au fichier LICENSE.txt pour plus d'informations
Source code under CECILL-C licence. Please refer to the LICENSE.txt file for more information.
 -->

<xsl:stylesheet version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns="" xpath-default-namespace="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="#all">

<xsl:template match="formula">
<xsl:variable name="nbFormula" select="count(preceding::formula)+1"/>
  <xsl:choose>
    <!-- traitement des formules block-->
    <xsl:when test="parent::tei:p[@rend='block']">
  <xsl:choose>
        <xsl:when test="@notation='mathml' or @notation='mml'">
          <disp-formula content-type="math/mathml">
          	<xsl:attribute name="id">
          	 <xsl:value-of select="concat('equ',$nbFormula)"/>
          	 </xsl:attribute>
        <xsl:copy-of select="child::*"/>
      </disp-formula>
    </xsl:when>
        <xsl:when test="@notation='tex'">
          <disp-formula content-type="math/tex">
          	<xsl:attribute name="id">
          	 <xsl:value-of select="concat('equ',$nbFormula)"/>
          	 </xsl:attribute>
          	<tex-math>
           	 <xsl:copy-of select="text()"/>
            </tex-math>
          </disp-formula>
        </xsl:when>
        <xsl:otherwise>unknown notation</xsl:otherwise>
  </xsl:choose>
    </xsl:when>
    <!-- traitement des formules inline-->
    <xsl:when test="@rend='inline'">
      <xsl:choose>
        <xsl:when test="@notation='tex'">
          <inline-formula content-type="math/tex">
            <tex-math>
              <xsl:copy-of select="text()"/>
            </tex-math>
          </inline-formula>
        </xsl:when>
        <xsl:when test="@notation='mathml' or @notation='mml'">
          <inline-formula content-type="math/mathml">
            <xsl:copy-of select="child::*"/>
          </inline-formula>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:when>
    <!-- traitement inconnu -->
    <xsl:otherwise>unknown notation</xsl:otherwise>
  </xsl:choose>
</xsl:template>
    
<!-- Encadrés -->
<xsl:template match="floatingText">
    <boxed-text>
        <xsl:apply-templates/>
    </boxed-text>
</xsl:template>

<!-- Code -->
<xsl:template match="code">
    <code>
        <xsl:apply-templates/>
    </code>
</xsl:template>

<!-- Entretien -->
<xsl:template match="sp">
    <p>
    	<xsl:attribute name="content-type" select="child::tei:p/@rend"/>
        <xsl:apply-templates/>
    </p>
</xsl:template>

<xsl:template match="speaker">
	<!--<name-content>-->
		<xsl:apply-templates/>
	<!--</name-content>-->
</xsl:template>

<xsl:template match="tei:p[@style='txt_Resume']"/>
<xsl:template match="tei:p[@style='txt_Resume_italique']"/>
<xsl:template match="tei:p[@style='txt_resume_inv']"/>
<xsl:template match="tei:p[@style='txt_Motclef']"/>
<xsl:template match="tei:p[@style='txt_Motclef_italique']"/>
<xsl:template match="tei:p[@style='txt_Keywords']"/>
<xsl:template match="tei:p[@style='txt_motscles_inv']"/>

</xsl:stylesheet>

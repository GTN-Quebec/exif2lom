<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xslout="http://www.w3.org/1999/XSL/Transform/Out"
  xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  >
<xsl:namespace-alias stylesheet-prefix="xslout" result-prefix="xsl"/>
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
<xsl:template match="/">
<xslout:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >
  <xsl:apply-templates/>
</xslout:stylesheet>
</xsl:template>

<xsl:template match="value">
  <xslout:variable>
    <xsl:attribute name="name">
      <xsl:value-of select="@ns" />
      <xsl:text>_</xsl:text>
      <xsl:value-of select="@tag" />
    </xsl:attribute>
    <xslout:choose>
      <xsl:apply-templates/>
    </xslout:choose>
  </xslout:variable>
</xsl:template>

<xsl:template match="source[@valid != 'false']">
  <xsl:choose>
    <xsl:when test="@ns">
      <xsl:variable name="nsid" select="generate-id()"/>
      <xslout:when>
        <xsl:attribute name="test">
          <xsl:text>//rdf:RDF/rdf:Description/*[local-name()='</xsl:text>
          <xsl:value-of select="@exif"/>
          <xsl:text>' and namespace-uri(.)='</xsl:text>
          <xsl:value-of select="@ns"/>
          <xsl:text>']</xsl:text>
        </xsl:attribute>
        <xslout:value-of>
          <xsl:attribute name="select">
            <xsl:text>//rdf:RDF/rdf:Description/*[local-name()='</xsl:text>
            <xsl:value-of select="@exif"/>
            <xsl:text>' and namespace-uri(.)='</xsl:text>
            <xsl:value-of select="@ns"/>
            <xsl:text>']/text()</xsl:text>
          </xsl:attribute>
        </xslout:value-of>
      </xslout:when>
    </xsl:when>
    <xsl:otherwise>
      <xslout:when>
        <xsl:attribute name="test">
          <xsl:text>//rdf:RDF/rdf:Description/*[local-name()='</xsl:text>
          <xsl:value-of select="@exif"/>
          <xsl:text>']</xsl:text>
        </xsl:attribute>
        <xslout:value-of>
          <xsl:attribute name="select">
            <xsl:text>//rdf:RDF/rdf:Description/*[local-name()='</xsl:text>
            <xsl:value-of select="@exif"/>
            <xsl:text>']/text()</xsl:text>
          </xsl:attribute>
        </xslout:value-of>
      </xslout:when>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="*">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="text()" />

</xsl:stylesheet>
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
      <xsl:if test="@default">
        <xslout:otherwise>
          <xsl:value-of select="@default" />
        </xslout:otherwise>
      </xsl:if>
    </xslout:choose>
  </xslout:variable>
</xsl:template>

<!-- TODO
Cas spécial à ajouter: Les valeurs séquentielles. Eg
 <XMP-meta:User-definedName>Personnalise_texte</XMP-meta:User-definedName>
 <XMP-meta:User-defined>la valeur</XMP-meta:User-defined>
 <XMP-meta:User-definedName>Personnalise_bool</XMP-meta:User-definedName>
 <XMP-meta:User-definedValue-type>boolean</XMP-meta:User-definedValue-type>
 <XMP-meta:User-defined>true</XMP-meta:User-defined>

 -->

<xsl:template match="source[@valid != 'false']">
  <xsl:choose>
    <xsl:when test="@ns">
      <xslout:when>
        <xsl:attribute name="test">
          <xsl:text>key('exif_full','</xsl:text>
          <xsl:value-of select="@ns"/>
          <xsl:text>:</xsl:text>
          <xsl:value-of select="@exif"/>
          <xsl:text>')</xsl:text>
        </xsl:attribute>
        <xslout:apply-templates>
          <xsl:attribute name="mode">
            <xsl:choose>
              <xsl:when test="@operation">
                <xsl:value-of select="@operation"/>
              </xsl:when>
              <xsl:otherwise>decode</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="select">
            <xsl:text>key('exif_full','</xsl:text>
            <xsl:value-of select="@ns"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="@exif"/>
            <xsl:text>')[1]</xsl:text>
          </xsl:attribute>
        </xslout:apply-templates>
      </xslout:when>
    </xsl:when>
    <xsl:when test="exception">
      <xslout:when>
        <xsl:attribute name="test">
          <xsl:text>key('exif_local','</xsl:text>
          <xsl:value-of select="@exif"/>
          <xsl:text>')[</xsl:text>
            <xsl:apply-templates/>
          <xsl:text>]</xsl:text>
        </xsl:attribute>
        <xslout:apply-templates>
          <xsl:attribute name="mode">
            <xsl:choose>
              <xsl:when test="@operation">
                <xsl:value-of select="@operation"/>
              </xsl:when>
              <xsl:otherwise>decode</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="select">
            <xsl:text>key('exif_local','</xsl:text>
            <xsl:value-of select="@exif"/>
            <xsl:text>')[</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>][1]</xsl:text>
          </xsl:attribute>
        </xslout:apply-templates>
      </xslout:when>
    </xsl:when>
    <xsl:otherwise>
      <xslout:when>
        <xsl:attribute name="test">
          <xsl:text>key('exif_local','</xsl:text>
          <xsl:value-of select="@exif"/>
          <xsl:text>')</xsl:text>
        </xsl:attribute>
        <xslout:apply-templates>
          <xsl:attribute name="mode">
            <xsl:choose>
              <xsl:when test="@operation">
                <xsl:value-of select="@operation"/>
              </xsl:when>
              <xsl:otherwise>decode</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="select">
            <xsl:text>key('exif_local','</xsl:text>
            <xsl:value-of select="@exif"/>
            <xsl:text>')[1]</xsl:text>
          </xsl:attribute>
        </xslout:apply-templates>
      </xslout:when>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="exception">
  <xsl:if test="position() &gt; 2">
    <xsl:text> and </xsl:text>
  </xsl:if>
  <xsl:text>namespace-uri() != '</xsl:text>
  <xsl:value-of select="@ns"/>
  <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template match="*">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="text()" />

</xsl:stylesheet>
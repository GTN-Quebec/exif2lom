<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns:str="http://exslt.org/strings"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  extension-element-prefixes="regexp str"
  >
<xsl:import href="translation.xsl"/>
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
<xsl:param name="location" />
<xsl:key name="exif_full" match="//rdf:RDF/rdf:Description/*" use="concat(namespace-uri(),':',local-name())"/>
<xsl:key name="exif_local" match="//rdf:RDF/rdf:Description/*" use="local-name()"/>

<xsl:template mode="decode" match="*">
<xsl:choose>
  <xsl:when test="rdf:Bag">
    <xsl:apply-templates mode="decode" select="rdf:Bag/rdf:li[1]"/>
  </xsl:when>
  <xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#base64Binary'">
    <xsl:value-of xmlns:ntic="http://ntic.org/" select="ntic:decode(text())"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="text()"/>
  </xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template mode="lang" match="*">
  <xsl:value-of select="substring(text(),1,2)"/>
</xsl:template>

<xsl:template mode="string" match="text()">
  <lom:string >
    <xsl:attribute name="language">
      <xsl:value-of select="$lom_language"/>
    </xsl:attribute>
    <xsl:value-of select="."/>
  </lom:string>
</xsl:template>

<xsl:template name="date">
  <xsl:param name="date" />
    <xsl:variable name="normzone">
      <!-- remove textual timezones -->
      <xsl:choose>
        <xsl:when test="regexp:test($date,'^[-:0-9]+T[0-9:]{8}Z?[A-Z]{3}$')">
          <xsl:value-of select="concat(substring-before($date,'T'),'T',substring(substring-after($date,'T'),1, 8))"/>
        </xsl:when>
        <xsl:when test="regexp:test($date,'^[-:0-9]+ [0-9:]{8}Z?[A-Z]{3}$')">
          <xsl:value-of select="concat(substring-before($date,' '),'T',substring(substring-after($date,' '),1, 8))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$date"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="normcolon">
      <!-- colon often used as date separator... also correct ' ' as a date-time separator. -->
      <xsl:choose>
        <xsl:when test="regexp:test($normzone,'^[0-9:]+ [0-9:]+(Z|[-\+][0-9:]+)?$')">
          <xsl:value-of select="concat(translate(substring-before($normzone,' '),':','-'),'T',substring-after($normzone,' '))"/>
        </xsl:when>
        <xsl:when test="regexp:test($normzone,'^[0-9:]+T[0-9:]+(Z|[-\+][0-9:]+)?$')">
          <xsl:value-of select="concat(translate(substring-before($normzone,'T'),':','-'),'T',substring-after($normzone,'T'))"/>
        </xsl:when>
        <xsl:when test="regexp:test($normzone,'^[0-9:]+Z?$')">
          <xsl:value-of select="translate($normzone,':','-')"/>
        </xsl:when>
        <xsl:when test="regexp:test($normzone,'^[0-9:]+\+[0-9:]+$')">
          <xsl:value-of select="concat(translate(substring-before($normzone,'+'),':','-'),'+',substring-after($normzone,'+'))"/>
        </xsl:when>
        <xsl:when test="regexp:test($normzone,'^[0-9]+:[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}$')">
          <xsl:value-of select="concat(translate(substring-before($normzone,'-'),':','-'),'-',substring-after($normzone,'-'))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$normzone"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="regexp:test($normcolon,'^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2})?(Z|[-\+][0-9]{2}:[0-9]{2})?$')">
        <lom:dateTime><xsl:value-of select="$normcolon"/></lom:dateTime>
      </xsl:when>
      <xsl:otherwise>
        <lom:description>
          <lom:string>
            <xsl:attribute name="language">
              <xsl:value-of select="$lom_language"/>
            </xsl:attribute>
            <xsl:value-of select="$date"/>
          </lom:string>
        </lom:description>
      </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template name="duration">
  <xsl:param name="duration" />
  <xsl:choose>
    <xsl:when test="regexp:test($duration,'^[0-9]{1,2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$')">
      <xsl:variable name="hours">
        <xsl:value-of select="substring-before($duration,':')" />
      </xsl:variable>
      <xsl:variable name="minutes">
        <xsl:value-of select="substring-before(substring-after($duration,':'),':')" />
      </xsl:variable>
      <xsl:variable name="seconds">
        <xsl:value-of select="substring-after(substring-after($duration,':'),':')" />
      </xsl:variable>
      <xsl:value-of select="concat('P',$hours,'H',$minutes,'M',$seconds,'S')" />
    </xsl:when>
    <xsl:when test="regexp:test($duration,'^[0-9]?[0-9]:[0-9]{2}$')">
      <xsl:variable name="hours">
        <xsl:value-of select="substring-before($duration,':')" />
      </xsl:variable>
      <xsl:variable name="minutes">
        <xsl:value-of select="substring-after($duration,':')" />
      </xsl:variable>
      <xsl:value-of select="concat('P',$hours,'H',$minutes,'M')" />
    </xsl:when>
    <xsl:when test="regexp:test($duration,'^P?T[0-9][0-9]H([0-9][0-9]M([0-9][0-9]S(\.[0-9]+)?)?)?$')">
      <xsl:variable name="duration2">
        <xsl:value-of select="substring-after($duration,'T')" />
      </xsl:variable>
      <xsl:value-of select="concat('P',$duration2,7,2)" />
    </xsl:when>
    <xsl:when test="regexp:test($duration,'^[0-9]+[\.,][0-9]+( s(ec)?)?\.?$')">
      <xsl:value-of select="translate(concat('P',substring-before(concat($duration,' '),' '),'S'),',','.')" />
    </xsl:when>
    <xsl:otherwise>
      <lom:description>
        <lom:string>
          <xsl:attribute name="language">
            <xsl:value-of select="$lom_language"/>
          </xsl:attribute>
          <xsl:value-of select="$duration"/>
        </lom:string>
      </lom:description>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="contribution">
  <xsl:param name="role" />
  <xsl:param name="fn" />
  <xsl:param name="date" />
  <lom:contribute>
     <lom:role>
        <lom:source>LOMv1.0</lom:source>
        <lom:value><xsl:value-of select="$role"/></lom:value>
     </lom:role>
     <lom:entity>BEGIN: vCard
FN: <xsl:value-of select="$fn"/>
<xsl:if test="$vcard_ORG">
ORG: <xsl:value-of select="$vcard_ORG"/>
</xsl:if>
<xsl:if test="$vcard_COUNTRY != '' or $vcard_CITY != '' or $vcard_STATE != ''">
ADR:;;;<xsl:value-of select="$vcard_CITY"/>;<xsl:value-of select="$vcard_STATE"/>;;<xsl:value-of select="$vcard_COUNTRY"/>
</xsl:if>
END: vCard
    </lom:entity>
     <lom:date>
        <xsl:choose>
          <xsl:when test="$date != ''">
            <xsl:call-template name="date">
              <xsl:with-param name="date" select="$date" />
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:comment>obligatoire</xsl:comment>
          </xsl:otherwise>
        </xsl:choose>
     </lom:date>
  </lom:contribute>
</xsl:template>

<xsl:template match="/">
  <lom:lom>
     <lom:general>
        <lom:identifier>
           <lom:catalog><xsl:comment>recommandé</xsl:comment></lom:catalog>
           <lom:entry><xsl:comment>recommandé</xsl:comment></lom:entry>
        </lom:identifier>
        <lom:title>
           <lom:string >
            <xsl:attribute name="language">
                <xsl:value-of select="$lom_language"/>
            </xsl:attribute>
            <xsl:choose>
              <xsl:when test="$lom_title != ''">
                <xsl:value-of select="$lom_title"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:comment>obligatoire</xsl:comment>
              </xsl:otherwise>
            </xsl:choose>
           </lom:string>
        </lom:title>
        <lom:language>
            <xsl:value-of select="$lom_language"/>
        </lom:language>
        <lom:description>
           <lom:string >
            <xsl:attribute name="language">
              <xsl:value-of select="$lom_language"/>
            </xsl:attribute>
            <xsl:choose>
              <xsl:when test="$lom_description != ''">
                <xsl:value-of select="$lom_description"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:comment>obligatoire</xsl:comment>
              </xsl:otherwise>
            </xsl:choose>
           </lom:string>
        </lom:description>
        <lom:keyword>
          <xsl:choose>
            <xsl:when test="$lom_keyword != ''">
              <xsl:apply-templates mode="string" select="str:split($lom_keyword,',')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>obligatoire</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </lom:keyword>
        <lom:coverage>
          <xsl:comment>facultatif</xsl:comment>
        </lom:coverage>
        <lom:structure>
          <xsl:comment>facultatif</xsl:comment>
        </lom:structure>
        <lom:aggregationLevel>
          <xsl:comment>facultatif</xsl:comment>
        </lom:aggregationLevel>
     </lom:general>
     <lom:lifeCycle>
        <lom:version>
            <lom:string language="fr"><xsl:comment>obligatoire</xsl:comment></lom:string>
        </lom:version>
        <lom:status>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>recommandé</xsl:comment></lom:value>
        </lom:status>

        <xsl:if test="$vcard_FN_author != ''">
          <xsl:call-template name="contribution">
            <xsl:with-param name="role" select="'author'"/>
            <xsl:with-param name="fn" select="$vcard_FN_author"/>
            <xsl:with-param name="date" select="$lom_create_date"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="$vcard_FN_lastauthor != '' and ($vcard_FN_lastauthor != $vcard_FN_author)">
          <xsl:call-template name="contribution">
            <xsl:with-param name="role" select="'author'"/>
            <xsl:with-param name="fn" select="$vcard_FN_lastauthor"/>
            <xsl:with-param name="date" select="$lom_modify_date"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="$vcard_FN_contributor != '' and ($vcard_FN_lastauthor != $vcard_FN_contributor) and ($vcard_FN_contributor != $vcard_FN_author)">
          <xsl:call-template name="contribution">
            <xsl:with-param name="role" select="'author'"/>
            <xsl:with-param name="fn" select="$vcard_FN_contributor"/>
            <xsl:with-param name="date" select="$lom_modify_date"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="($vcard_FN_contributor = '') and ($vcard_FN_lastauthor = '') and ($vcard_FN_author = '')">
          <lom:contribute>
            <xsl:comment>facultatif</xsl:comment>
          </lom:contribute>
        </xsl:if>
     </lom:lifeCycle>
     <lom:metaMetadata>
        <lom:identifier>
            <lom:catalog><xsl:comment>obligatoire</xsl:comment></lom:catalog>
            <lom:entry><xsl:comment>obligatoire</xsl:comment></lom:entry>
        </lom:identifier>
        <lom:contribute>
          <xsl:choose>
            <xsl:when test="$lom_metadata_date != ''">
               <lom:role>
                  <lom:source>LOMv1.0</lom:source>
                  <lom:value>author</lom:value>
               </lom:role>
               <lom:date>
                  <lom:dateTime>
                    <xsl:call-template name="date">
                      <xsl:with-param name="date" select="$lom_metadata_date" />
                    </xsl:call-template>
                  </lom:dateTime>
               </lom:date>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>facultatif</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </lom:contribute>
        <lom:metadataSchema>LOMv1.0</lom:metadataSchema>
        <lom:language>fr-CA</lom:language>
     </lom:metaMetadata>
     <lom:technical>
        <lom:format>
          <xsl:choose>
            <xsl:when test="$lom_format != ''">
              <xsl:value-of select="$lom_format"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>obligatoire</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </lom:format>
        <lom:size>
          <xsl:choose>
            <xsl:when test="$lom_size != ''">
              <xsl:variable name="num">
                <xsl:value-of select="substring-before($lom_size,' ')" />
              </xsl:variable>
              <xsl:variable name="unit">
                <xsl:value-of select="translate(substring-after($lom_size,' '), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')" />
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$unit = 'gb'">
                    <xsl:value-of select="round(number($num)*1024*1024*1024)" />
                </xsl:when>
                <xsl:when test="$unit = 'gigabyte'">
                    <xsl:value-of select="round(number($num)*1024*1024*1024)" />
                </xsl:when>
                <xsl:when test="$unit = 'mb'">
                    <xsl:value-of select="round(number($num)*1024*1024)" />
                </xsl:when>
                <xsl:when test="$unit = 'megabyte'">
                    <xsl:value-of select="round(number($num)*1024*1024)" />
                </xsl:when>
                <xsl:when test="$unit = 'kb'">
                    <xsl:value-of select="round(number($num)*1024)" />
                </xsl:when>
                <xsl:when test="$unit = 'kilobyte'">
                    <xsl:value-of select="round(number($num)*1024)" />
                </xsl:when>
                <xsl:when test="$unit = 'byte'">
                    <xsl:value-of select="round(number($num))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$lom_size " />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>recommandé</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </lom:size>
        <lom:location>
          <xsl:choose>
            <xsl:when test="$location != ''">
              <xsl:value-of select="$location" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>obligatoire</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </lom:location>
        <lom:requirement>
          <xsl:comment>facultatif</xsl:comment>
        </lom:requirement>
        <lom:installationRemarks><xsl:comment>recommandé</xsl:comment></lom:installationRemarks>
        <lom:otherPlatformRequirements><xsl:comment>recommandé</xsl:comment></lom:otherPlatformRequirements>
        <lom:duration>
          <xsl:choose>
            <xsl:when test="$lom_duration != ''">
              <xsl:call-template name="duration">
                <xsl:with-param name="duration" select="$lom_duration" />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>facultatif</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </lom:duration>
     </lom:technical>
     <lom:educational>
        <lom:interactivityType>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>facultatif</xsl:comment></lom:value>
        </lom:interactivityType>
        <lom:learningResourceType>
              <xsl:comment>obligatoire</xsl:comment>
        </lom:learningResourceType>
        <lom:interactivityLevel>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>facultatif</xsl:comment></lom:value>
        </lom:interactivityLevel>
        <lom:semanticDensity>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>facultatif</xsl:comment></lom:value>
        </lom:semanticDensity>
        <lom:intendedEndUserRole>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>recommandé</xsl:comment></lom:value>
        </lom:intendedEndUserRole>
        <lom:context>
              <xsl:comment>obligatoire</xsl:comment>
        </lom:context>
        <lom:typicalAgeRange>
          <lom:string language="fr"><xsl:comment>recommandé</xsl:comment></lom:string>
        </lom:typicalAgeRange>
        <lom:difficulty>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>facultatif</xsl:comment></lom:value>
        </lom:difficulty>
        <lom:typicalLearningTime>
          <lom:duration><xsl:comment>recommandé</xsl:comment></lom:duration>
        </lom:typicalLearningTime>
        <lom:description>
          <lom:string language="fr"><xsl:comment>facultatif</xsl:comment></lom:string>
        </lom:description>
        <lom:language>
          <xsl:value-of select="$lom_language" />
        </lom:language>
    </lom:educational>
     <lom:rights>
        <lom:cost>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>obligatoire</xsl:comment></lom:value>
        </lom:cost>
        <lom:copyrightAndOtherRestrictions>
            <lom:source>LOMv1.0</lom:source>
            <lom:value><xsl:comment>obligatoire</xsl:comment></lom:value>
        </lom:copyrightAndOtherRestrictions>
        <lom:description>
           <lom:string>
            <xsl:attribute name="language">
              <xsl:value-of select="$lom_language"/>
            </xsl:attribute>
            <xsl:choose>
            <xsl:when test="$lom_copydescription != ''">
              <xsl:value-of select="$lom_copydescription"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>obligatoire</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
           </lom:string>
         </lom:description>
     </lom:rights>
    <lom:relation>
    <lom:kind>
      <lom:source>LOMv1.0</lom:source>
      <lom:value><xsl:comment>recommandé</xsl:comment></lom:value>
    </lom:kind>
    <lom:resource>
      <lom:identifier>
        <lom:catalog><xsl:comment>facultatif</xsl:comment></lom:catalog>
        <lom:entry><xsl:comment>facultatif</xsl:comment></lom:entry>
      </lom:identifier>
      <lom:description><xsl:comment>facultatif</xsl:comment></lom:description>
    </lom:resource>
    </lom:relation>
    <lom:annotation>
      <xsl:comment>facultatif</xsl:comment>
    </lom:annotation>
     <lom:classification>
        <lom:purpose>
          <lom:source>LOMv1.0</lom:source>
          <lom:value><xsl:comment>obligatoire</xsl:comment></lom:value>
        </lom:purpose>
        <lom:taxonPath>
          <lom:source>
            <lom:string language="fr">
              <xsl:comment>obligatoire</xsl:comment>
            </lom:string>
          </lom:source>
          <lom:taxon>
            <lom:id>
              <xsl:comment>obligatoire</xsl:comment>
            </lom:id>
            <lom:entry>
              <lom:string language="fr">
                <xsl:comment>obligatoire</xsl:comment>
              </lom:string>
            </lom:entry>
          </lom:taxon>
      </lom:taxonPath>
      <lom:description>
        <lom:string language="fr"><xsl:comment>facultatif</xsl:comment></lom:string>
      </lom:description>
      <lom:keyword>
        <lom:string language="fr"><xsl:comment>facultatif</xsl:comment></lom:string>
      </lom:keyword>
     </lom:classification>
  </lom:lom>
</xsl:template>

</xsl:stylesheet>
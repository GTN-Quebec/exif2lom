<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lom="http://ltsc.ieee.org/xsd/LOM"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  >
<xsl:import href="translation.xsl"/>
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
<xsl:key name="exif_full" match="//rdf:RDF/rdf:Description/*" use="concat(namespace-uri(),':',localpart())"/>
<xsl:key name="exif_local" match="//rdf:RDF/rdf:Description/*" use="localpart()"/>
<xsl:template match="/">
  <lom:lom>
     <lom:general>
        <!-- lom:identifier>
           <lom:catalog>URI</lom:catalog>
           <lom:entry></lom:entry>
        </lom:identifier -->
        <lom:title>
           <lom:string language="fr">
            <xsl:value-of select="$lom_title"/>
           </lom:string>
        </lom:title>
        <lom:description>
           <lom:string language="fr">
            <xsl:value-of select="$lom_description"/>
           </lom:string>
        </lom:description>
     </lom:general>
     <lom:lifeCycle>
        <lom:contribute>
           <lom:role>
              <lom:source>LOMv1.0</lom:source>
              <lom:value>publisher</lom:value>
           </lom:role>
           <lom:entity>BEGIN: vCard
  ORG: Algonquin College
  END: vCard
  				</lom:entity>
           <lom:date>
              <lom:dateTime>2001-02-01</lom:dateTime>
           </lom:date>
        </lom:contribute>
     </lom:lifeCycle>
     <lom:metaMetadata>
        <lom:contribute>
           <lom:role>
              <lom:source>LOMv1.0</lom:source>
              <lom:value>creator</lom:value>
           </lom:role>
           <lom:entity>BEGIN:vCard
  FN: <xsl:value-of select="$vcard_FN"/>
  END:vCard
  				</lom:entity>
        </lom:contribute>
        <lom:contribute>
           <lom:role>
              <lom:source>LOMv1.0</lom:source>
              <lom:value>validator</lom:value>
           </lom:role>
           <lom:entity>BEGIN: vCard
  ORG: POOL Project
  END: vCard
  				</lom:entity>
           <lom:date>
              <lom:dateTime>2001-02-01</lom:dateTime>
           </lom:date>
        </lom:contribute>
        <lom:metadataSchema>IEEE LOM 1.0</lom:metadataSchema>
        <lom:language>en</lom:language>
     </lom:metaMetadata>
     <lom:technical>
        <lom:format>
              <xsl:value-of select="$lom_format"/>
        </lom:format>
        <!-- lom:location>http://www.algonquincollege.com/distance/certfs.html</lom:location -->
     </lom:technical>
     <lom:rights>
        <lom:description>
           <lom:string language="fr">
            <xsl:value-of select="$lom_copydescription"/>
           </lom:string>
        </lom:description>
     </lom:rights>
     <lom:classification>
        <lom:purpose>
           <lom:source>LOMv1.0</lom:source>
           <lom:value>discipline</lom:value>
        </lom:purpose>
        <lom:taxonPath>
           <lom:taxon>
              <lom:entry>
                 <lom:string language="fr">Human Resources</lom:string>
              </lom:entry>
           </lom:taxon>
           <lom:taxon>
              <lom:entry>
                 <lom:string language="fr">Management</lom:string>
              </lom:entry>
           </lom:taxon>
           <lom:source>
              <lom:string language="fr">Eric</lom:string>
           </lom:source>
        </lom:taxonPath>
     </lom:classification>
     <lom:classification>
        <lom:purpose>
           <lom:source>LOMv1.0</lom:source>
           <lom:value>educational objective</lom:value>
        </lom:purpose>
        <lom:taxonPath>
           <lom:taxon>
              <lom:entry>
                 <lom:string language="fr">Course</lom:string>
              </lom:entry>
           </lom:taxon>
           <lom:source>
              <lom:string language="x-none">CanCore</lom:string>
           </lom:source>
        </lom:taxonPath>
     </lom:classification>
  </lom:lom>
</xsl:template>

</xsl:stylesheet>
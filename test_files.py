#!/usr/bin/env python2.7

from utils import example_files
from lxml import etree

ns={
'rdf':'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
}

if __name__ == '__main__':
	trans = etree.parse('translations.xml')
	values = trans.xpath('//value')
	matches_by_tag = { value.attrib['tag'] : set() for value in values }
	matches_by_file_by_tag = { value.attrib['tag'] : {} for value in values }
	for filename in example_files:
		exif = etree.parse(filename+'.exif.xml')
		for value in values:
			all_matches = []
			for source in value.findall('source'):
				if 'ns' in source.attrib:
					xpath = "//rdf:RDF/rdf:Description/*[local-name()='%s' and namespace-uri(.)='%s']" % \
						(source.attrib["exif"],source.attrib["ns"])
				else:
					xpath = "//rdf:RDF/rdf:Description/*[local-name()='%s']" % \
						(source.attrib["exif"],)
				matches = exif.xpath(xpath, namespaces=ns)
				all_matches.extend([(n.tag,n.text) for n in matches])
			matches_by_file_by_tag[value.attrib['tag']][filename] = all_matches
			matches_by_tag[value.attrib['tag']].update(all_matches)
	for value, sources in matches_by_tag.viewitems():
		print "--- %s ---"%(value,)
		sourceTags = list({x[0] for x in sources})
		sourceTags.sort()
		for tag in sourceTags:
			print ' ',tag
		print
	for value, file_tags in matches_by_file_by_tag.viewitems():
		print "--- %s ---"%(value,)
		for filename, sources in file_tags.viewitems():
			if sources:
				print '* '+filename
				sources.sort()
				for source, val in sources:
					print (u"   %s : '%s'" % (source, val)).encode("utf-8")
				print
		print
		
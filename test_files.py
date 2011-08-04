#!/usr/bin/env python2.7

from utils import example_files
from lxml import etree
from os.path import basename
import argparse

namespaces={
'rdf':'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
}

def print_tag2tag(args):
	for value, sources in args.matches_by_tag.viewitems():
		print "--- %s ---"%(value,)
		sourceTags = list({x[2] for x in sources})
		sourceTags.sort()
		for tag in sourceTags:
			print ' ',tag
		print

def print_tag2file2tag(args):
	for value, file_tags in args.matches_by_file_by_tag.viewitems():
		print "--- %s ---"%(value,)
		for filename, sources in file_tags.viewitems():
			if len(sources) >= args.minLen:
				if args.onlyConflicts:
					vals = {s[3] for s in sources}
					if len(vals) == 1:
						continue
					if not reduce(lambda a,b: a or b, (s[0] is None for s in sources), False):
						continue
				print '* '+filename
				sources.sort()
				for num, filename, source, val, valid in sources:
					print (u"   %s : '%s'" % (source, val)).encode("utf-8")
				print
		print

def print_validation_file(args):
	root = etree.Element("validation")
	for value, tags_files in args.matches_by_tag_by_file.viewitems():
		valueEl = etree.Element("value")
		valueEl.attrib["name"] = value
		root.append(valueEl)
		for tag, examples in tags_files.viewitems():
			tagEl = etree.Element("tag")
			valueEl.append(tagEl)
			tagEl.attrib["name"]=tag
			tagEl.attrib["valid"]=""
			for num, filename, ns, val, valid in examples:
				egEl = etree.Element("example")
				tagEl.append(egEl)
				egEl.attrib["ns"]=ns
				egEl.attrib["file"]=basename(filename)
				egEl.attrib["valid"] = valid
				egEl.text = val
	print etree.tounicode(root, pretty_print=True).encode('utf-8')

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Check the translations against the test files.')
	subparsers = parser.add_subparsers(title='subcommands',
	                                   description='valid subcommands')
	tags_command = subparsers.add_parser('tags')
	matches_command = subparsers.add_parser('matches')
	matches_command.add_argument('-minLen', type=int, default=1)
	matches_command.add_argument('-onlyConflicts', type=bool, default=False)
	validation_command = subparsers.add_parser('validation')
	trans = etree.parse('translations.xml')
	values = trans.xpath('//value')
	matches_by_tag = { value.attrib['tag'] : set() for value in values }
	matches_by_file_by_tag = { value.attrib['tag'] : {} for value in values }
	matches_by_tag_by_file = { value.attrib['tag'] : {} for value in values }
	tags_command.set_defaults(func=print_tag2tag, matches_by_tag=matches_by_tag)
	matches_command.set_defaults(func=print_tag2file2tag, matches_by_file_by_tag=matches_by_file_by_tag)
	validation_command.set_defaults(func=print_validation_file, matches_by_tag_by_file=matches_by_tag_by_file)
	args = parser.parse_args()
	for filename in example_files:
		exif = etree.parse(filename+'.exif.xml')
		for value in values:
			all_matches = []
			invalids = set()
			for num, source in enumerate(value.findall('source')):
				valid = source.attrib["valid"]
				if 'ordered' not in source.attrib:
					num = None
				if valid is "false":
					if ns in source.attrib:
						invalids.append("{%s}%s"%(source.attrib['ns'],source.attrib['exif']))
					else:
						invalids.append(source.attrib['exif'])
					continue
				if 'ns' in source.attrib:
					xpath = "//rdf:RDF/rdf:Description/*[local-name()='%s' and namespace-uri(.)='%s']" % \
						(source.attrib["exif"],source.attrib["ns"])
				else:
					xpath = "//rdf:RDF/rdf:Description/*[local-name()='%s']" % \
						(source.attrib["exif"],)
				matches = exif.xpath(xpath, namespaces=namespaces)
				all_matches.extend([(num, filename, n.tag, n.text, valid) for n in matches if n.tag not in invalids])
			tag = value.attrib['tag']
			matches_by_tag[tag].update(all_matches)
			matches_by_file_by_tag[tag][filename] = all_matches
			for (num, filename, exiftag, text, valid) in all_matches:
				exifns,exiftag = exiftag.split('}')
				exifns=exifns[1:]
				if exiftag not in matches_by_tag_by_file[tag]:
					matches_by_tag_by_file[tag][exiftag] = []
				matches_by_tag_by_file[tag][exiftag].append((num, filename, exifns, text, valid))
	args.func(args)
	#print_tag2tag(matches_by_tag)
	#print_tag2file2tag(matches_by_file_by_tag, 2, True)
	#print print_validation_file(matches_by_tag_by_file).encode('utf-8')

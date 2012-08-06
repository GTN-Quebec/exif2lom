#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

from utils import getExampleFiles, base64decode, getExifXml
from lxml import etree
from os.path import basename
import argparse

namespaces={
	'rdf':'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
}

operations = {
	'date': lambda x: x.xpath("substring-before(concat(text(),' '), ' ')"),
	'lang': lambda x: x.xpath("substring(text(),1,2)")
}

tags = ["title", "language", "description", "keyword", "create_date", "modify_date", "metadata_date",
		 "FN_lastauthor", "FN_author", "FN_contributor", "COUNTRY", "CITY", "STATE", "ORG", "size",
		 "format", "duration", "copydescription"]
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
				if args.allConflicts or args.mainConflicts:
					vals = {s[3] for s in sources}
					if len(vals) == 1:
						continue
					nums = {s[0] for s in sources}
					if None not in nums:
						valdic = {tuple(int(x) for x in num.split('.')):set() for num in nums}
						for num, filename, source, val, valid in sources:
							valdic[tuple(int(x) for x in num.split('.'))].add(val)
						if args.verbose:
							print valdic
						nums = valdic.keys()
						nums.sort()
						if args.mainConflicts and len(set(valdic[nums[0]])) == 1:
							continue
						if args.allConflicts and max(len(x) for x in set(valdic.viewvalues())) == 1:
							continue
				print '* '+filename
				sources.sort()
				for num, filename, source, val, valid in sources:
					print (u"   %s %s : '%s'" % (num, source, val)).encode("utf-8")
				print
		print

def extractText(node):
	if node.attrib.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}datatype') == 'http://www.w3.org/2001/XMLSchema#base64Binary':
		return base64decode(node.text)
	else:
		return node.text
	

def print_validation_file(args):
	root = etree.Element("validation")
	for value, tags_files in args.matches_by_exiftag.viewitems():
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

def get_ns(tag):
	if '}' in tag:
		return tag.split('}')[0][1:]

def dedup(arr, *keys):
	keys = [k for k in keys if k in arr]
	vals = set()
	for k in keys:
		if arr[k] in vals:
			del arr[k]
		else:
			vals.add(arr[k])

def print_numtags(args):
	print '|Fichier| ','|'.join(tags),'|Total'
	spaces = max(len(basename(f)) for f in args.matches_by_file.viewkeys())+2
	print '|'+  ('-'*(spaces+1)) +'|---'*(len(tags)+1)+'|'
	for filename, all_results in args.matches_by_file.viewitems():
		print '|'+basename(filename)+' '*(spaces - len(basename(filename))),
		r = {k:v[0][3] for k,v in all_results.viewitems() if v}
		# special case equality
		dedup(r, 'FN_author', 'FN_lastauthor', 'FN_contributor')
		dedup(r, 'create_date', 'modify_date', 'metadata_date')
		for tag in tags:
			print '|',
			if tag in r:
				print 'x',
			else:
				print ' ',
		print '|', len(r)


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Check the translations against the test files.')
	parser.add_argument('--verbose', default=False, action='store_true')
	parser.add_argument('--exampledir', action='append')
	subparsers = parser.add_subparsers(title='subcommands',
	                                   description='valid subcommands')
	tags_command = subparsers.add_parser('tags')
	numtags_command = subparsers.add_parser('numtags')
	matches_command = subparsers.add_parser('matches')
	matches_command.add_argument('--minLen', type=int, default=1)
	matches_command.add_argument('--mainConflicts', default=False, action='store_true')
	matches_command.add_argument('--allConflicts', default=False, action='store_true')
	matches_command.add_argument('--noExceptions', default=False, action='store_true')
	validation_command = subparsers.add_parser('validation')
	trans = etree.parse('translations.xml')
	values = trans.xpath('//value')
	matches_by_tag = { value.attrib['tag'] : set() for value in values }
	matches_by_file_by_tag = { value.attrib['tag'] : {} for value in values }
	matches_by_exiftag = { value.attrib['tag'] : {} for value in values }
	matches_by_file = {}
	tags_command.set_defaults(func=print_tag2tag, matches_by_tag=matches_by_tag)
	matches_command.set_defaults(func=print_tag2file2tag, matches_by_file_by_tag=matches_by_file_by_tag)
	validation_command.set_defaults(func=print_validation_file, matches_by_exiftag=matches_by_exiftag)
	numtags_command.set_defaults(func=print_numtags, matches_by_file=matches_by_file)
	args = parser.parse_args()
	exceptions = []
	example_files = getExampleFiles(args.exampledir)
	for filename in example_files:
		exif = getExifXml(filename)
		matches_by_file[filename] = {}
		for value in values:
			all_matches = []
			for num, source in enumerate(value.getiterator('source')):
				valid = source.attrib["valid"]
				if valid == "false":
					continue
				parent = source.getparent()
				if parent.tag == 'priorityGroup':
					if 'ordered' in parent.attrib:
						num = '%s.%s'%(parent.getparent().index(parent),parent.index(source))
					else:
						num = str(parent.getparent().index(parent))
				else:
					num = None
				if 'ns' in source.attrib:
					xpath = "//rdf:RDF/rdf:Description/*[local-name()='%s' and namespace-uri(.)='%s']" % \
						(source.attrib["exif"],source.attrib["ns"])
				else:
					xpath = "//rdf:RDF/rdf:Description/*[local-name()='%s']" % \
						(source.attrib["exif"],)
				matches = exif.xpath(xpath, namespaces=namespaces)
				if args.func == print_tag2file2tag and not args.noExceptions:
					exceptions = [ex.attrib['ns'] for ex in source.findall('exception')]
				if 'operation' in source.attrib:
					op = operations[source.attrib['operation']]
				else:
					op = extractText
				all_matches.extend([(num, filename, n.tag, op(n), valid) for n in matches if get_ns(n.tag) not in exceptions])
			tag = value.attrib['tag']
			matches_by_tag[tag].update(all_matches)
			matches_by_file_by_tag[tag][filename] = all_matches
			matches_by_file[filename][tag] = all_matches
			for (num, filename, exiftag, text, valid) in all_matches:
				exifns,exiftag = exiftag.split('}')
				exifns=exifns[1:]
				if exiftag not in matches_by_exiftag[tag]:
					matches_by_exiftag[tag][exiftag] = []
				matches_by_exiftag[tag][exiftag].append((num, filename, exifns, text, valid))
	args.func(args)

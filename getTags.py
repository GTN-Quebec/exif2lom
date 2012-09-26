#!/usr/bin/env python2.7

import sys
from multiprocessing import Pool, cpu_count
from utils import getExampleFiles, getExifXml
try:
    from tags import tags as old_tags
except ImportError:
    old_tags = []

from namespaces import ns

setns = set(ns.values())


def nameElements(node):
    tag = node.tag
    if '}' in tag:
        if node.prefix not in ns:
            print "MISSING:" + node.prefix + ' ' + tag.split('}', 1)[0]
        return (node.prefix, tag.split('}', 1)[0][1:], tag.split('}', 1)[1])
    return (None, None, tag)


def getKeys(fname):
    content = getExifXml(fname)
    nodes = content.xpath('/rdf:RDF/rdf:Description/*', namespaces=ns)
    names = set([nameElements(node) for node in nodes])
    return names


def writeNames(old_tags, new_tags):
    with open('tags.py', 'w') as f:
        f.write("tags=[\n")
        for (pre, uri, local) in old_tags:
            f.write("('%s','%s','%s'),\n" % (pre, uri, local))
        if new_tags:
            print "--- New tags!"
            f.write("# new tags\n")
            for (pre, uri, local) in new_tags:
                print "('%s','%s','%s'),\n" % (pre, uri, local)
                f.write("('%s','%s','%s'),\n" % (pre, uri, local))
        f.write(']\n')


if __name__ == '__main__':
    pool = Pool(cpu_count())
    example_files = getExampleFiles(sys.argv[1:])
    tags = pool.map(getKeys, example_files)
    tags = reduce(set.union, tags, set())
    old_tags_set = set(old_tags)
    new_tags = [tag for tag in tags if tag not in old_tags_set]
    old_tags.sort()
    new_tags.sort()
    writeNames(old_tags, new_tags)

#!/usr/bin/env python2.7

from lxml import etree
from multiprocessing import Pool, cpu_count
from subprocess import check_call
from os.path import exists
from utils import example_files

from namespaces import ns

exifTestsImageDir = '/Users/maparent/OpenSource/Image-ExifTool-8.61/t/images/'

setns = set(ns.values())

def nameElements(node):
    tag = node.tag
    if '}' in tag:
        if node.prefix not in ns:
            print "MISSING:"+node.prefix+' '+tag.split('}',1)[0]
        return (node.prefix, tag.split('}',1)[0][1:], tag.split('}',1)[1])
    return (None, None, tag)

def getKeys(fname):
    fname2=fname+'.exif.xml'
    if not exists(fname2):
        check_call(['exiftool', '-X', '-w', '%d%f.%e.exif.xml', fname])
    content = etree.parse(fname2)
    nodes = content.xpath('/rdf:RDF/rdf:Description/*', namespaces=ns)
    names = set([nameElements(node) for node in nodes])
    return names

def writeNames(names):
    with open('tags.py','w') as f:
        f.write("tags=[\n")
        for (pre, uri, local) in names:
            f.write("('%s','%s','%s'),\n"%(pre, uri, local))
        f.write(']\n')

if __name__ == '__main__':
    pool = Pool(cpu_count())
    tags = pool.map(getKeys, example_files)
    names = reduce(set.union, tags, set())
    names = list(names)
    names.sort()
    writeNames(names)

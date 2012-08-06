from os import walk
from os.path import join, exists
from base64 import b64decode
from subprocess import check_call

from lxml import etree


def getExampleFiles(example_file_dirs):
    example_files = []
    endings = ['.exif.xml', '.results.txt']
    for example_file_dir in example_file_dirs:
        for root, dirs, files in walk(example_file_dir, True):
            dirs[:] = []  # do not recurse
            for a_file in files:
                skip = False
                for ending in endings:
                    if a_file.endswith(ending):
                        skip = True
                        break
                if not skip:
                    example_files.append(join(root, a_file))
    return example_files


def base64decode(s):
    try:
        b = b64decode(s.strip())
    except:
        return s
    for enc in ('utf-8', 'iso-8859-1'):
        try:
            return b.decode(enc)
        except:
            pass
    return b


def getExifXml(fname):
    fname2 = fname + '.exif.xml'
    if not exists(fname2):
        check_call(['exiftool', '-X', '-w', '%d%f.%e.exif.xml', fname])
    return etree.parse(fname2)

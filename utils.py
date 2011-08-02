from os import walk
from os.path import join

example_file_dirs = ['/Users/maparent/OpenSource/Image-ExifTool-8.61/t/images/',  'tests']
example_files = []
endings = ['.exif.xml', '.results.txt']

for example_file_dir in example_file_dirs:
	for root, dirs, files in walk(example_file_dir, True):
		dirs[:] = [] # do not recurse
		for a_file in files:
			skip = False
			for ending in endings:
				if a_file.endswith(ending):
					skip = True
					break
			if not skip:
				example_files.append(join(root,a_file))

all: conflicts.txt validation.xml results.txt translation.xsl

conflicts.txt: translations.xml
	test_files.py matches -onlyConflicts true > $@

validation.xml: translations.xml
	test_files.py validation > $@

results.txt: translations.xml
	test_files.py matches > $@

translation.xsl: translations.xml to_xsl.xsl
	xsltproc -o $@ to_xsl.xsl translations.xml

PATH := $(PATH):.

EXIF := /Users/maparent/OpenSource/Image-ExifTool-9.02
EXIF_IMG := $(EXIF)/t/images/
PERL_LIBS := /Library/Perl/5.12/
PERL_TYPE := darwin-thread-multi-2level
APP_R := Exif2LOM.app/Contents/Resources/

all: conflicts.txt validation.xml results.txt translation.xsl numtags.html

init:
	sudo cpan -i LWP::UserAgent MIME::Base64  MIME::Types File::Temp File::Spec XML::LibXML XML::LibXSLT Image::ExifTool
	sudo easy_install lxml

clean:
	rm conflicts.txt validation.xml results.txt translation.xsl

conflicts.txt: translations.xml tags.py $(EXIF_IMG)
	test_files.py --exampledir tests --exampledir $(EXIF_IMG) matches --mainConflicts > $@

validation.xml: translations.xml tags.py $(EXIF_IMG)
	test_files.py --exampledir tests --exampledir $(EXIF_IMG) validation > $@

results.txt: translations.xml tags.py $(EXIF_IMG)
	test_files.py --exampledir tests --exampledir $(EXIF_IMG) matches > $@

tags.py: getTags.py
	getTags.py $(EXIF_IMG) tests

translation.xsl: translations.xml to_xsl.xsl
	xsltproc -o $@ to_xsl.xsl translations.xml

%.html: %.mmd
	multimarkdown -o $@ $<

numtags.mmd: translations.xml
	test_files.py --exampledir tests --exampledir $(EXIF_IMG) numtags > $@

numtags.csv: translations.xml
	test_files.py --exampledir tests --exampledir $(EXIF_IMG) numtags_csv > $@

%.tex: %.mmd
	multimarkdown -t latex -o $@ $<

Exif2LOM.app: exif2lom.pl exif2lom.platypus
	platypus -P Exif2LOM.platypus -y Exif2LOM.app
	mkdir -p $(APP_R)Image $(APP_R)XML $(APP_R)File $(APP_R)$(PERL_TYPE)/auto/Image $(APP_R)$(PERL_TYPE)/XML $(APP_R)$(PERL_TYPE)/auto/XML
	cp -rf $(PERL_LIBS)/Image/ExifTool* $(APP_R)Image
	cp -rf $(PERL_LIBS)$(PERL_TYPE)/auto/Image/ExifTool $(APP_R)$(PERL_TYPE)/auto/Image
	cp -rf $(PERL_LIBS)/MIME $(APP_R)
	cp -rf $(PERL_LIBS)$(PERL_TYPE)/auto/MIME $(APP_R)$(PERL_TYPE)/auto
	cp -rf $(PERL_LIBS)/LWP/UserAgent.pm $(APP_R)LWP
	cp -rf $(PERL_LIBS)$(PERL_TYPE)/XML/LibX* $(APP_R)$(PERL_TYPE)/XML
	cp -rf $(PERL_LIBS)$(PERL_TYPE)/auto/XML/LibX* $(APP_R)$(PERL_TYPE)/auto/XML


Exif2LOM.dmg: Exif2LOM.app
	hdiutil create -ov -format UDZO -srcfolder Exif2LOM.app -volname exif2lom Exif2LOM.dmg

push: Exif2LOM.dmg
	scp Exif2LOM.dmg vteducation.org:/var/www/vteducation.org/html/docs/Exif2LOM.dmg

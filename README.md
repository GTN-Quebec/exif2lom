This is work-in-progress software for extracting LOM metadata from an arbitrary document or URL.
The perl script (`exif.pl`) can be used from the command-line, after installing the following prerequisites:

* `LWP::UserAgent`
* `MIME::Base64`
* `MIME::Types`
* `File::Temp`
* `File::Spec`
* `XML::LibXML`
* `XML::LibXSLT`
* `Image::ExifTool`

Note that you will also have to create the translation.xsl file, with the following command:

	`xsltproc -o $@ to_xsl.xsl translations.xml`

The makefile specifies this, as well as some tests, based on a ExifTool source install.

On MacOSX, the script can be packaged into a droplet. Building the droplet requries the [Platypus](http://sveinbjorn.org/platypus) sofware (with the command-line tool installed.)


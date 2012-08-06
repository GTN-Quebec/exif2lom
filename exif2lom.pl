#!/usr/bin/perl

BEGIN {
my $majorV = int($]);
my $minorV = int(1000*($] - $majorV));
$version = "$majorV.$minorV";
}
use lib $version;

use XML::LibXSLT;
use XML::LibXML;
use Image::ExifTool qw(:Public);
use Image::ExifTool::XMP;
use MIME::Base64 qw/ decode_base64 /;
use File::Temp qw/ tempfile tempdir /;
use File::Spec qw/ catpath splitpath /;
use LWP::UserAgent;
use MIME::Types qw( by_mediatype );

sub alert($) {
    my $msg = shift;
    `osascript -e 'tell application "System Events" to display alert("$msg")'`;
}

#------------------Taken from the main exiftool file --------------

$fileHeader = "<?xml version='1.0' encoding='UTF-8'?>\n" .
              "<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>\n";
$fileTrailer = "</rdf:RDF>\n";

sub CleanXML($)
{
    my $strPt = shift;
    # translate control characters that are invalid in XML
    $$strPt =~ tr/\0-\x08\x0b\x0c\x0e-\x1f/./;
    # fix malformed UTF-8 characters
    Image::ExifTool::XMP::FixUTF8($strPt) if $utf8;
    # escape necessary characters for XML
    $$strPt = Image::ExifTool::XMP::EscapeXML($$strPt);
}


#------------------------------------------------------------------------------
# Format value for XML output
# Inputs: 0) value, 1) indentation, 2) group
# Returns: formatted value
sub FormatXML($$$)
{
    local $_;
    my ($val, $ind, $grp) = @_;
    my $gt = '>';
    if (ref $val eq 'ARRAY') {
        # convert ARRAY into an rdf:Bag
        my $val2 = "\n$ind <rdf:Bag>";
        foreach (@$val) {
            $val2 .= "\n$ind  <rdf:li" . FormatXML($_, "$ind  ", $grp) . "</rdf:li>";
        }
        $val = "$val2\n$ind </rdf:Bag>\n$ind";
    } elsif (ref $val eq 'HASH') {
        $gt = " rdf:parseType='Resource'>";
        my $val2 = '';
        foreach (sort keys %$val) {
            my $tok = $grp . ':' . $_;
            $val2 .= "\n$ind <$tok" . FormatXML($$val{$_}, "$ind ", $grp) . "</$tok>";
        }
        $val = "$val2\n$ind";
    } else {
        # (note: SCALAR reference should have already been converted)
        my $enc = EncodeXML(\$val);
        $gt = " rdf:datatype='$enc'>\n" if $enc; #ATV
    }
    return $gt . $val;
}


#------------------------------------------------------------------------------
# Encode string for XML
# Inputs: 0) string ref
# Returns: encoding used (and input string is translated)
sub EncodeXML($)
{
    my $strPt = shift;
    if ($$strPt =~ /[\0-\x08\x0b\x0c\x0e-\x1f]/ or
        ($utf8 and Image::ExifTool::XMP::IsUTF8($strPt) < 0))
    {
        # encode binary data and non-UTF8 with special characters as base64
        $$strPt = Image::ExifTool::XMP::EncodeBase64($$strPt);
        return 'http://www.w3.org/2001/XMLSchema#base64Binary'; #ATV
    } else {
        $$strPt = Image::ExifTool::XMP::EscapeXML($$strPt);
    }
    return '';  # not encoded
}

#------------------------------------------------------------------------------
# Convert binary data (SCALAR references) for printing
# Inputs: 0) object reference
# Returns: converted object
sub ConvertBinary($)
{
    my $obj = shift;
    my ($key, $val);
    if (ref $obj eq 'HASH') {
        foreach $key (keys %$obj) {
            $$obj{$key} = ConvertBinary($$obj{$key}) if ref $$obj{$key};
        }
    } elsif (ref $obj eq 'ARRAY') {
        foreach $val (@$obj) {
            $val = ConvertBinary($val) if ref $val;
        }
    } elsif (ref $obj eq 'SCALAR') {
        # (binaryOutput flag is set to 0 for binary mode of XML output format)
        if (defined $binaryOutput) {
            $obj = $$obj;
        } else {
            # (-b is not valid for JSON or HTML output)
            my $bOpt = ($json or $html) ? '' : ', use -b option to extract';
            if ($$obj =~ /^Binary data/) {
                $obj = "($$obj$bOpt)";
            } else {
                $obj = '(Binary data ' . length($$obj) . " bytes$bOpt)";
            }
        }
    }
    return $obj;
}

# This code is taken from the main exiftool file, and somewhat simplified.
sub WriteXml($) {
    my $file = shift;
    my $exifTool = new Image::ExifTool;
    my @foundTags;
    $exifTool->Options(Duplicates => 1);
    $exifTool->Options(List => 1);
    $exifTool->ExtractInfo($file, \%options);
    $info = $exifTool->GetInfo(\@foundTags);
    # taken from the main script
    my $tempXml;
    open(my $fp, '>', \$tempXml);
    #$fp = \*STDOUT;
    if ($fileHeader) {
        print $fp $fileHeader;
        undef $fileHeader unless $textOut;
    }
    my $tag;
    my $f = $file;
    CleanXML(\$f);
    print $fp "\n<rdf:Description rdf:about='$f'";
    print $fp "\n  xmlns:et='http://ns.exiftool.ca/1.0/'";
    print $fp " et:toolkit='Image::ExifTool $Image::ExifTool::VERSION'";
    # define namespaces for all tag groups
    my %groups;
    foreach $tag (@foundTags) {
        my ($grp, $grp1) = $exifTool->GetGroup($tag);
        unless ($grp1) {
            next unless $forcePrint;
            $grp = $grp1 = 'Unknown';
        }
        next if $groups{$grp1};
        $groups{$grp1} = 1;
        # include family 0 and 1 groups in URI except for internal tags
        # (this will put internal tags in the "XML" group on readback)
        $grp .= "/$grp1" unless $grp eq $grp1 and
                                $grp =~ /^(ExifTool|File|Composite|Unknown)$/;
        print $fp "\n  xmlns:$grp1='http://ns.exiftool.ca/$grp/1.0/'";
    }
    print $fp '>';
    $ind = $outFormat >= 0 ? ' ' : '   ';
    # suppress duplicates manually in JSON and short XML output
    foreach $tag (@foundTags) {
        my $tagName = GetTagName($tag);
        my $group;
        # make sure this tag has a value
        my $val = $info->{$tag};
        if (ref $val) {
                # avoid extracting Protected binary tags (ie. data blocks) [insider information]
                next if $exifTool->{TAG_INFO}{$tag}{Protected};
                $val = ConvertBinary($val); # convert SCALAR references
                if (ref $val eq 'ARRAY') {
                    # join arrays of simple values (with newlines for binary output)
                    if ($binaryOutput) {
                        $val = join "\n", @$val;
                    } elsif ($joinLists) {
                        $val = join $listSep, @$val;
                    }
                }
        } elsif (not defined $val) {
            # ignore tags that weren't found unless necessary
            next;
        }
        $group = $exifTool->GetGroup($tag, 1);
        # look ahead to see if this tag may suppress a priority tag in
        # the same group, and if so suppress this tag instead
        $group = 'Unknown' if not $group;
        ++$lineCount;           # we are printing something meaningful
        my $desc = $tagName;

        # RDF/XML output format
        my $tok = "$group:$tagName";
        # manually un-do CR/LF conversion in Windows because output
        # is in text mode, which will re-convert newlines to CR/LF
        $isCRLF and $val =~ s/\x0d\x0a/\x0a/g;
        my $valNum;
        for ($valNum=0; $valNum<2; ++$valNum) {
            $val = FormatXML($val, $ind, $group);
            # normal output format (note: this will give
            # non-standard RDF/XML if there are any attributes)
            print $fp "\n <$tok$val</$tok>";
            last;
        }
        next;

        # translate unprintable chars in value and remove trailing spaces
        $val =~ tr/\x01-\x1f\x7f/./;
        $val =~ s/\x00//g;
        $val =~ s/\s+$//;

        my $buff = '';
        my $wid;
        my $len = 0;
        if (defined $group) {
            $buff = sprintf("%-15s ", "[$group]");
            $len = 16;
        }
        $wid = 32 - (length($buff) - $len);
        # pad description to a constant length
        # (get actual character length when using alternate languages
        # because these descriptions may contain UTF8-encoded characters)
        my $padLen = $wid - length($fixLen ? Encode::decode_utf8($desc) : $desc);
        $padLen = 0 if $padLen < 0;
        $buff .= $desc . (' ' x $padLen) . ": $val\n";
        print $fp $buff;
    }
    # close rdf:Description element
    print $fp $outFormat < 1 ? "\n</rdf:Description>\n" : "/>\n";
    print $fp $fileTrailer;
    close($fp);
    return $tempXml;
}

# --- end of Exiftool extracts


my $xslt = XML::LibXSLT->new();
sub test($$) {
    my ($s, $r) = @_;
    return $s =~ $r;
};
XML::LibXSLT->register_function('http://exslt.org/regular-expressions', 'test', \&test);
XML::LibXSLT->register_function('http://ntic.org/', 'decode', \&decode_base64);
if (!-e 'exif.xsl') {
    alert("not there");
}
my $style_doc = XML::LibXML->load_xml(location=>'exif.xsl', no_cdata=>1);
if (!$style_doc) {
    alert("hey!");
}
$stylesheet = $xslt->parse_stylesheet($style_doc);
my $browser;

foreach (@ARGV) {
    my $filename = $_;
    my $destdir, $volume, $basename, $fh, $tempfile, $url;
    $url = '';
    if ($filename =~ /^\file:\/\/(.*)/) {
        $filename = $1;
        ($volume,$destdir,$basename) = File::Spec->splitpath( $filename );
    } elsif ($filename =~ '^\w+://.*/([^/\.\?]*)(\.[^/\.\?]*)*(\?.*)?') {
        my $suffix = '';
        if (defined($1) && length($1)>0) {
            if (defined($2)) {
                $suffix = $2;
            }
            $basename = $1.$suffix;
        } else {
            $basename = "index.html";
            $suffix = ".html";
        }
        $url = $filename;
        $destdir = glob('~');
        if (!$browser) {
            $browser = LWP::UserAgent->new;
        }
        my $response = $browser->get( $filename );
        if (defined($response->content)) {
            if ($suffix == '') {
                my @suffixes = by_mediatype($response->content_type);
                if (length(@suffixes)) {
                    $suffix = $suffixes[0][0];
                } else {
                    $suffix = 'tmp';
                }
            } elsif ($suffix =~ /.*\.([^\.]+)$/) {
                $suffix = $1;
            }
            ($fh, $tempfile) = tempfile(SUFFIX=>'.'.$suffix);
            print $fh $response->content;
            close($fh);
            $filename = $tempfile;
        }
        close $fh;
    } else {
        ($volume,$destdir,$basename) = File::Spec->splitpath( $filename );
    }
    my $result = WriteXml($filename);
    my $fp;
    open($fp, '<', \$result);
    my $source = XML::LibXML->load_xml(IO => $fp);
    close($fp);
    $fn2 = File::Spec->catpath($volume, $destdir, $basename.".lom.xml");
    $index = 1;
    while (-e $fn2) {
        $fn2 = File::Spec->catpath($volume, $destdir, $basename."_".($index++).".lom.xml");
    }
    %vars = {'location'=>"'allo'"};
    $trans = $stylesheet->transform($source, 'location'=>"'$url'");
    open($fp, '>', $fn2);
    print $fp $stylesheet->output_as_bytes($trans);
    close($fp);
}

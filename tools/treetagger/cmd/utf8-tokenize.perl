#!/usr/bin/perl

########################################################################
#                                                                      #
#  tokenization script for tagger preprocessing                        #
#  Author: Helmut Schmid, IMS, University of Stuttgart                 #
#          Serge Sharoff, University of Leeds                          #
#  Description:                                                        #
#  - splits input text into tokens (one token per line)                #
#  - cuts off punctuation, parentheses etc.                            #
#  - disambiguates periods                                             #
#  - preserves SGML markup                                             #
#                                                                      #
########################################################################

use Getopt::Std;
use utf8;
use Encode;

getopts('hgfeiza:r');

# Modify the following lines in order to adapt the tokenizer to other
# types of text and/or languages

# characters which have to be cut off at the beginning of a word
my $PChar='[¿¡{\'\\`"‚„†‡‹‘’“”•–—›';

# characters which have to be cut off at the end of a word
my $FChar=']}\'\`\",;:\!\?\%‚„…†‡‰‹‘’“”•–—›';

# character sequences which have to be cut off at the beginning of a word
my $PClitic='';

# character sequences which have to be cut off at the end of a word
my $FClitic='';

if (defined($opt_r)) {
    # Romanian
    $PChar='[¿¡{\\`"‚„†‡‹‘’“”•–—›';
    $FChar=']}\`\",;:\!\?\%‚„…†‡‰‹‘’“”•–—›';
}
if (defined($opt_e)) {
    # English
    $FClitic = "['’´](s|re|ve|d|m|em|ll)|n['’´]t";
}
if (defined($opt_i)) {
    # Italian
    $PClitic = "(?:[dD][ae]ll|[nN]ell|[Aa]ll|[lLDd]|[Ss]ull|[Qq]uest|[Uu]n|[Ss]enz|[Tt]utt|[Cc]|[Ss])['´’]";
}
if (defined($opt_f)) {
    # French
    $PClitic = "?:([dcjlmnstDCJLNMST]|[Qq]u|[Jj]usqu|[Ll]orsqu)['’´]";
    $FClitic = "-t-elles?|-t-ils?|-t-on|-ce|-elles?|-ils?|-je|-la|-les?|-leur|-lui|-mmes?|-m['’´]|-moi|-nous|-on|-toi|-tu|-t['’´]|-vous|-en|-y|-ci|-là";
}
if (defined($opt_z)) {
    # Galician
    $FClitic = '-la|-las|-lo|-los|-nos';
}


### NO MODIFICATIONS REQUIRED BEYOND THIS LINE #########################

if (defined($opt_h)) {
    die "
Usage: utf8-tokenize.perl [ options ] ...files...

Options:
-e : English text 
-i : Italian text
-f : French text
-z : Galician text
-a <file>: <file> contains a list of words which are either abbreviations or
           words which should not be further split.
";
}

# Read the list of abbreviations and words
if (defined($opt_a)) {
    die "Can't read: $opt_a: $!\n"  unless (open(FILE, $opt_a));
    while (<FILE>) {
	$_ = decode('utf8',$_);
	s/^[ \t\r\n]+//;
	s/[ \t\r\n]+$//;
	next if (/^\#/ || /^\s$/);    # ignore comments
	$Token{$_} = 1;
    }
    close FILE;
}

#SS: main loop; 
my $first_line = 1;
while (<>) {
    $_ = decode('utf8',$_);
    # delete optional byte order markers (BOM)
    if ($first_line) {
	undef $first_line;
	s/^\x{FEFF}//;
    }

    # replace newlines and tab characters with blanks
    #tr/\n\t/  /;
	#s/[\n\t\p{XPosixCntrl}]/ /g;

    # replace blanks within SGML tags
    while (s/(<[^<> ]*) ([^<>]*>)/$1\377$2/g) {
    }
    #Separ: ÿþ

    # replace whitespace with a special character
    tr/ /\376/;

    # restore SGML tags
    tr/\377\376/ \377/;

    # prepare SGML-Tags for tokenization
    s/(<[^<>]*>)/\377$1\377/g;
    s/^\377//;
    s/\377$//;
    s/\377\377\377*/\377/g;

    @S = split("\377");
    for( $i=0; $i<=$#S; $i++) {
	$_ = $S[$i];
	
	if (/^<.*>$/) {
	    # SGML tag
	    print encode('utf8',"$_\n");
	} else {
	    # add a blank at the beginning and the end of each segment
	    $_ = " $_ ";
	    # insert missing blanks after punctuation
	    s/(\.\.\.)/ ... /g;
	    s/([;\!\?])([^ ])/$1 $2/g;
	    #s/([.,:])([^ 0-9.])/$1 $2/g;
	    
	    @F = split;
	    for ( $j=0; $j<=$#F; $j++) {
		my $suffix="";
		$_ = $F[$j];

		# separate punctuation and parentheses from words
		$finished = 0;
		while (!$finished) {

		    # preceding parentheses
		    if (s/^(\()([^\)]*)(.)$/$2$3/) {
			print "$1\n";
		    }
		    
		    # following preceding parentheses
		    elsif (s/^([^(]+)(\))$/$1/) {
			$suffix = "$2\n$suffix";
		    }

		    elsif (s/^([$PChar])(.)/$2/) {
			print encode('utf8',"$1\n");
		    }

		    # cut off preceding punctuation
		    elsif (s/^([$PChar])(.)/$2/) {
			print encode('utf8',"$1\n");
		    }

		    # cut off trailing punctuation
		    elsif (s/(.)([$FChar])$/$1/) {
			$suffix = "$2\n$suffix";
		    }

		    # cut off trailing periods if punctuation precedes
		    elsif (s/([$FChar])\.$//) { 
			$suffix = ".\n$suffix";
			if ($_ eq "") {
			    $_ = $1;
			} else {
			    $suffix = "$1\n$suffix";
			}
		    }

		    else {
			$finished = 1;
		    }
		}
                
		# handle explicitly listed tokens
		if (defined($Token{$_})) {
		    print encode('utf8',"$_\n$suffix");
		    next;
		}
                
		# abbreviations of the form A. or U.S.A.
		if (/^([A-Za-z-]\.)+$/) {
		    print encode('utf8',"$_\n$suffix");
		    next;
		}
		

		# disambiguate periods
		if (/^(..*)\.$/ && $_ ne "..." && !($opt_g && /^[0-9]+\.$/)) {
		    $_ = $1;
		    $suffix = ".\n$suffix";
		    if (defined($Token{$_})) {
			print encode('utf8',"$_\n$suffix");
			next;
		    }
		}
		
		# cut off clitics
		while (s/^(--)(.)/$2/) {
		    print encode('utf8',"$1\n");
		}
		if ($PClitic ne '') {
		    while (s/^($PClitic)(.)/$2/) {
			print encode('utf8',"$1\n");
		    }
		}

		while (s/(.)(--)$/$1/) {
		    $suffix = "$2\n$suffix";
		}
		if ($FClitic ne '') {
		    while (s/(.)($FClitic)$/$1/) {
			$suffix = "$2\n$suffix";
		    }
		}
		
		print encode('utf8',"$_\n$suffix");
	    }
	}
    }
}

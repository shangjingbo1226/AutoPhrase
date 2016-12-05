#!/usr/bin/perl

########################################################################
#                                                                      #
#  tokenization script for tagger preprocessing                        #
#  Author: Helmut Schmid, IMS, University of Stuttgart                 #
#                                                                      #
#  Description:                                                        #
#  - splits input text into tokens (one token per line)                #
#  - cuts off punctuation, parentheses etc.                            #
#  - cuts of clitics like n't in English                               #
#  - disambiguates periods                                             #
#  - preserves SGML markup                                             #
#  - reads the whole file at once and should therefore not be called   #
#    with very large files                                             #
#                                                                      #
########################################################################

use Getopt::Std;
getopts('hfeiza:w');

# Modify the following lines in order to adapt the tokenizer to other
# types of text and/or languages

# characters which have to be cut off at the beginning of a word
my $PChar='[{¿¡\'\`\´"»«\202\204\206\207\213\221\222\223\224\225\226\227\233';

# characters which have to be cut off at the end of a word
my $FChar=']}\'\`\´\",;:\!\?\%»«\202\204\205\206\207\211\213\221\222\223\224\225\226\227\233';

# character sequences which have to be cut off at the beginning of a word
my $PClitic;

# character sequences which have to be cut off at the end of a word
my $FClitic;

if (defined($opt_e)) {
    # English
    $FClitic = "['´](s|re|ve|d|m|em|ll)|n['´]t";
}
if (defined($opt_i)) {
    # Italian
    $PClitic = "(?:[dD][ae]ll|[nN]ell|[Aa]ll|[lLDd]|[Ss]ull|[Qq]uest|[Uu]n|[Ss]enz|[Tt]utt|[Cc]|[Ss])['´]";
}
if (defined($opt_f)) {
    # French
    $PClitic = "(?:[dcjlmnstDCJLNMST]|[Qq]u|[Jj]usqu|[Ll]orsqu)['´]";
    $FClitic = "-t-elles?|-t-ils?|-t-on|-ce|-elles?|-ils?|-je|-la|-les?|-leur|-lui|-mmes?|-m['´]|-moi|-nous|-on|-toi|-tu|-t['´]|-vous|-en|-y|-ci|-là";
}
if (defined($opt_z)) {
    # Galician
    $FClitic = '-la|-las|-lo|-los|-nos';
}


### NO MODIFICATIONS REQUIRED BEYOND THIS LINE #########################

if (defined($opt_h)) {
    die "
Usage: tokenize.perl [ options ] ...files...

Options:
-e        English text 
-f        French text
-i        Italian text
-a <file> <file> contains a list of words which are either abbreviations or
          words which should not be further split.
-w        replace whitespace by SGML tags
";
}

# Read the list of abbreviations and words
if (defined($opt_a)) {
    die "file not found: $opt_a\n"  unless (open(FILE, $opt_a));
    while (<FILE>) {
	s/^[ \t\r\n]+//;
	s/[ \t\r\n]+$//;
	next if (/^\#/ || /^\s$/);   # ignore comments
	$Token{$_} = 1;
    }
    close FILE;
}


###########################################################################
# read the file
###########################################################################

while (<>) {

    # delete \r
    s/[\r\p{XPosixCntrl}]//g;

    # replace blanks within SGML Tags
    while (s/(<[^<> ]*)[ \t]([^<>]*>)/$1\377$2/g) {
    }

    # replace whitespace by SGML-Tags
    if (defined $opt_w) {
	s/\n/<internal_NL>/g;
	s/\t/<internal_TAB>/g;
	s/ /<internal_BL>/g;
    }

    # restore SGML Tags
    tr/\377/ /;

    # put special characters around SGML Tags for tokenization
    s/(<[^<>]*>)/\377$1\377/g;
    s/(&[^; \t\n\r]*;)/\377$1\377/g;
    s/^\377//;
    s/\377$//;
    s/\377\377/\377/g;

    @S = split("\377");
    for ($i=0; $i<=$#S; $i++) {
	$_ = $S[$i];
	# skip lines with  only SGML tags
	if (/^<.*>$/) {
	    print $_,"\n";
	}
	# normal text
	else {
	    # put spaces at beginning and end
	    $_ = ' '.$_.' ';
	    # put spaces around punctuation
	    s/(\.\.\.)/ ... /g;
	    s/([;\!\?\/])([^ ])/$1 $2/g;
	    s/(,)([^ 0-9.])/$1 $2/g;
	    s/([a-zA-ZÀ-ÿ][a-zA-ZÀ-ÿ][.:])([A-ZÀ-Ý])/$1 $2/g;
	    
	    @F = split;
	    for ($j=0; $j<=$#F; $j++) {
		my $suffix="";
		$_ = $F[$j];
		# cut off punctuation and brackets
		my $finished = 0;
		while (!$finished && !defined($Token{$_})) {

		    # preceding parentheses
		    if (s/^(\()([^\)]*)(.)$/$2$3/) {
			print "$1\n";
		    }

		    # following preceding parentheses
		    elsif (s/^([^(]+)(\))$/$1/) {
			$suffix = "$2\n$suffix";
		    }

		    # other leading punctuation symbols
		    elsif (s/^([$PChar])(.)/$2/) {
			print $1,"\n";
		    }

		    # other following punctuation symbols
		    elsif (s/(.)([$FChar])$/$1/) {
			$suffix = "$2\n$suffix";
		    }

		    # cut off dot after punctuation etc.
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
		
		# deal with listed tokens
		if (defined($Token{$_})) {
		    print "$_\n$suffix";
		    next;
		}
		
		# deal with abbrevs like U.S.A.
		if (/^([A-Za-zÀ-ÿ]\.)+$/) {
		    print "$_\n$suffix";
		    next;
		}
		
		# ordinal numbers
		if (/^[0-9]+\.$/ && ! defined($opt_e)) {
		    print "$_\n$suffix";
		    next;
		}
		
		# deal with differnt types of dots
		if (/^(..*)\.$/ && $_ ne "...") {
		    $_ = $1;
		    $suffix = ".\n$suffix";
		    if (defined($Token{$_})) {
			print "$_\n$suffix";
			next;
		    }
		}
		
		# cut  clitics off
		while (s/^(--)(.)/$2/) {
		    print $1,"\n";
		}
		if (defined $PClitic) {
		    while (s/^($PClitic)(.)/$2/) {
			print $1,"\n";
		    }
		}

		while (s/(.)(--)$/$1/) {
		    $suffix = "$2\n$suffix";
		}
		if (defined $FClitic) {
		    while (s/(.)($FClitic)$/$1/) {
			$suffix = "$2\n$suffix";
		    }
		}

		print "$_\n$suffix";
	    }
	}
    }
}

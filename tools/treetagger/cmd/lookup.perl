#!/usr/bin/perl

# Usage: lookup.perl <file>*
# Perl script to be used prior to tagging

# It assigns sets of possible tags to selected word forms.
# The tag information is read from the first argument file.
# The format of this file is:
# <word form><tab>[<tag><whitespace>{<tag prob.><whitespace>}]*
# The word form which may contain blanks is followed by a tab character
# and a sequence of tags separated by whitespace. The tags are optionally
# followed by tag probability values in the range from 0.0 to 1.0.

$LEXICON = shift;
open(LEXICON);
while (<LEXICON>) {
  if (s/^(.*?)\t//) {
    $word = $1;
    s/\s*\t\s*/\t/g;
    s/ +/ /g;
    $tag{$word} = $_;
  }
}
close(LEXICON);

while (<>) { 
  chop();
  s/[ \t\n][ \t\n]*/ /go;
  s/^[ \t\n]*(.*[^ \t\n])[ \t\n]*$/$1/go;
  if (defined($tag{$_})) {
    print $_,"\t",$tag{$_};
  }
  else {
    print "$_\n";
  }
}

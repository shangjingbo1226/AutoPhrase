#!/usr/bin/perl 
#Serge Sharoff, University of Leeds

#use lib("/corpora/tools");
use segmenter;

$lexicon=shift;
$lexicon2=shift;
#$lexicon3=shift;
$spacetoken=shift;
die "A simple tokeniser for Chinese texts (C) Serge Sharoff\nUsage: $0 lexicon [bigrams] [s] <input >output\n" unless defined $lexicon;

init($lexicon,$lexicon2);

$outsepar=($spacetoken) ? ' ' : "\n";

binmode(STDIN,":utf8");
binmode(STDOUT,":utf8");

while (<STDIN>) {
    s/\s+$//;
    utf8::decode($_);
    print segmentline($_),"\n";
}


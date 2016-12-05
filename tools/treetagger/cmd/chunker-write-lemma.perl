#!/usr/bin/perl -w

###################################################################
###                                                             ###
###      File: chunker-write-lemma.perl                         ###
###    Author: Dennis Spohr (spohrds@ims.uni-stuttgart.de)      ###
###   Purpose: Bypass for obtaining lemmas with french chunker  ###
###            (see also chunker-read-lemma.perl)               ###
###   Created: Tue Feb 13 2007                                  ###
###                                                             ###
###################################################################

open(OUT,">lemmas.txt");

# flush filehandle for unbuffered output
my $ofh = select OUT;
$| = 1;
select $ofh;

while (<>) {

    chomp;
    (@F)=split("\t");

    # print token and tag/chunk to STDOUT
    # print lemma to lemma file
    if ($#F==0){
	print OUT "\n";
	print "$_\n";
    } else {
	print OUT "$F[2]\n";
	print "$F[0]-$F[1]\n";
    }

}

close(OUT);

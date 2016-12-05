#!/usr/bin/perl -w

###################################################################
###                                                             ###
###      File: chunker-read-lemma.perl                          ###
###    Author: Dennis Spohr (spohrds@ims.uni-stuttgart.de)      ###
###   Purpose: Bypass for obtaining lemmas with french chunker  ###
###            (see also chunker-write-lemma.perl)              ###
###   Created: Tue Feb 13 2007                                  ###
###                                                             ###
###################################################################

# wait for 5 seconds to ensure that a portion of the lemmas has been 
# written to the file before attempting to read from the file
sleep(5);

open(IN,"<lemmas.txt");

while (<>) {

    # print chunker output
    chomp;
    print;

    # attach lemma
    $in = <IN>;
    if (defined $in) {
      print "\t$in" if defined $in;
    } else {
      print "\n";
    }

}

close(IN);

# remove lemma file
system("rm lemmas.txt");

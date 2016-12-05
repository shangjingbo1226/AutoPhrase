#!/usr/bin/perl

###################################################################
###                                                             ###
###      File: filter-coordinate-output.perl                    ###
###    Author: Dennis Spohr (spohrds@ims.uni-stuttgart.de)      ###
###   Purpose: Combine coordinated NPs into larger NP (also if  ###
###            embedded in PP(s))                               ###
###   Created: Tue Feb 13 2007                                  ###
###                                                             ###
###################################################################

use strict;

# queue for storing the content of the NPs
my @queue = ();

# current line
my $line = "";

# (possible) closing PP tags
my $pps = "";

# flush STDOUT for unbuffered output
$| = 1;

while($line = <>) {

    # first NP is encountered
    np:if ($line =~ /^<NP>/) {

       push(@queue,$line);

       # read until closing NP tag
       until ($line =~ /^<\/NP>/) {
          $line = <> or last;
          push(@queue,$line);
       }
       unless (defined $line) {
	   print @queue;
	   last;
       }

       $line = <>;
       $pps = "";

       # read possible closing PP tags
       while ($line =~ /^<\/PP>/) {
          $pps .= $line;
          $line = <>;
       }

       # continue as long as <COORD>...</COORD><NP>...</NP>
       # are encountered
       my $continue = 1;

       # number of coordinated NPs
       my $coord_np = 0;

       # number of coordinations
       my $coord = 0;

       # has current line been pushed onto queue?
       my $pushed = 0;

       while ($continue) {

          # encountered COORD
          if ($line =~ /^<COORD>/) {

            push(@queue,$line);
            $pushed = 1;
            $coord++;

            until ($line =~ /^<\/COORD>/) {
               $line = <>;
               push(@queue,$line);
            }

            $line = <>;
            $pushed = 0;

            # encountered NP (immediately after closing COORD tag)
            if ($line =~ /^<NP>/) {

               push(@queue,$line);
               $pushed = 1;
               $coord_np++;

               until ($line =~ /^<\/NP>/) {
                  $line = <>;
                  push(@queue,$line);
               }

            # encountered COORD but no NP afterwards: stop
            } else {
               $continue = 0;
            }

          # encountered no COORD: stop
          } else {
            $continue = 0;
          }

       }

       # found as many COORDs as NPs: put <NP> and </NP>
       # around content and append possible closing PP tags
       if ($coord > 0 && $coord_np == $coord) {

          unshift(@queue,"<NP>\n");
          push(@queue,"</NP>\n");
          push(@queue,$pps) unless $pps eq "";

       # found at least one coordinated NP, but then one COORD
       # without NP, e.g. 
       # <NP>...</NP><COORD>...</COORD><NP>...</NP><COORD>...</COORD><VN>
       } elsif ($coord > 1) {

          unshift(@queue,"<NP>\n");

          # append </NP> and possible closing PP tags before the final COORD, since 
          # this isn't part of the coordinated NPs
          for (my $i = $#queue; $i >= 0; $i--) {

             if ($queue[$i] =~ /^<COORD>/) {
                $queue[$i] = "</NP>\n".$pps."<COORD>\n";
                last;
             }

          }

       # found only one COORD and no NPs
       } elsif ($coord == 1) {

          # append possible closing PP tags before COORD
          for (my $i = $#queue; $i >= 0; $i--) {

             if ($queue[$i] =~ /^<COORD>/) {
                $queue[$i] = $pps."<COORD>\n";
                last;
             }

          }

       # found no COORD at all (usual case for simple NPs)
       } else {
          push(@queue,$pps) unless $pps eq "";
       }

       # if current line is again an NP (which may in turn be
       # followed by COORDs), go to the start and process the NP
       # (i.e. don't read from STDIN first, but process current line);
       # this is e.g. the following case:
       # <NP>...</NP><COORD>...</COORD><NP>...</NP><NP>...</NP>
       if ($line =~ /^<NP>/) {

          print @queue;
          undef @queue;
          goto np;

       } else {

          push(@queue,$line) unless $pushed;
          print @queue;
          undef @queue;

       }

    # no opening NP tag
    } else {
       print $line;
    }
}

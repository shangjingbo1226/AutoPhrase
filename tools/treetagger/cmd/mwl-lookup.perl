#!/usr/bin/perl

use Getopt::Std;
getopt('dhf:');

# This perl script recognizes multi word units in the input stream
# and puts them on one line. Input must have one-word-per-line format.
# The multi word units are listed in the parameter file with POS tags.
# Each line contains one multi word unit where the individual words
# are separated by blanks followed by a tab character and the blank-
# separated list of POS tags.
# Author: Helmut Schmid, IMS, Uni Stuttgart

if (!defined($opt_f) || defined($opt_h)) {
  $0 =~ s/.*\///;
  printf "\nUsage: $0 [-d del] -f mwl-file ...files...\n";
  print "\nOptions:\n";
  print "-d del : Use del as delimiter rather than a blank\n\n";
  die
}

if (!open(FILE, $opt_f)) {
  die "\nCan't open mwl file: ",$opt_f,"\n";
}
if (defined($opt_d)) {
  $del = $opt_d;
} else {
  $del = " ";
}

$N=1;
while (<FILE>) {
  chomp();
  @G = split("\t");
  @F = split(/\s+/,$G[0]);
  $state = 0;
  for($i=0; $i<=$#F; $i++) {
    if (!exists($arc{$state,$F[$i]})) {
      $arc{$state,$F[$i]} = $N++;
    }
    $state = $arc{$state,$F[$i]};
   }
  $final{$state} = $G[1];
}
close(FILE);


$last = $match = $last_match = 0;
$state = 0;

for (;;) {
  if ($match == $last) {
    if (!($token[$last] = <>)) {
      if ($last_match > 0) {
	print $token[0];
	for ($i=1; $i<=$last_match; $i++) {
	  print $del,$token[$i];
	}
	print "\n";
      } else {
	$i=0;
      }
      for (; $i<$last; $i++) {
	print $token[$i],"\n";
      }
      last;
    }
    chomp($token[$last++]);
  }
  if (($s = $arc{$state, $token[$match]}) ||
      ($s = $arc{$state, lc($token[$match])}) ||
      ($s = $arc{$state, ucfirst(lc($token[$match]))})) {
    if (exists($final{$s})) {
      $last_match = $match;
      $last_tag = $final{$s};
    }
    $state = $s;
    $match++;
  } else {
    if ($last_match > 0) {
      print $token[0];
      for($i=1; $i<=$last_match; $i++) {
	print $del,$token[$i];
      }
      print "\t$last_tag\n";
    } else {
      print $token[0],"\n";
    }
    for($i=0,$k=$last_match+1; $k<$last; ) {
      $token[$i++] = $token[$k++];
    }
    $last = $last - $last_match - 1;
    $last_match = $match = 0;
    $state = 0;
  }
}

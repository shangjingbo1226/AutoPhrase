#!/usr/bin/perl

$Threshold = 10;

while (<>) {
  chomp;
  @F = split("\t");
  $count{$F[0]}++;
  $count2{"$F[0]\t$F[1]"}++;
  if ($F[0] =~ s/.*-//) {
    $count{$F[0]}++;
    $count2{"$F[0]\t$F[1]"}++;
  }
}

foreach $p (keys %count2) {
  my ($w,$t) = split("\t", $p);
  if ($count{$w} > $Threshold || $w !~ /-/) {
    $tags{$w} .= "\t$t #";
  }
}

foreach $w (sort keys %tags) {
  print $w,$tags{$w},"\n";
}

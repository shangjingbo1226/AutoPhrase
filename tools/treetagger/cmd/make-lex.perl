#!/usr/bin/perl

# use Getopt::Std;
# getopts('h');

while (<>) {
    next if $_ eq "\n";
    chomp;
    die "Error in line: $_" unless /^(.+?)\s*\t\s*(\S+)(\s+(.+?))?\s*$/;
    $w = $1;
    $t = $2;
    $l = (defined $4) ? $4 : "-";
    $lemma{"$w\t$t"} = $l;
}

foreach $p (sort keys %lemma) {
    my($w,$t) = split(/\t/,$p);
    $tags{$w} .= "\t$t $lemma{$p}";
}

foreach $w (sort keys %tags) {
    print $w,$tags{$w},"\n" unless $w =~ /^[0-9][0-9,.:;\/]+$/;
}

#!/usr/bin/perl

use warnings;
use strict;
use utf8::all;

my $filename = shift or die "Error: missing argument file!\n";
open(FILE,$filename) or die "Error: unable to open file \"$filename\"!\n";
my %exception;
while(<FILE>) {
    chomp;
    $exception{$_} = 1;
}

while (<>) {
    chomp;

    my $initial = '';
    my $final = '';

    if (s/^(şi)(-n)$/$1/i || s/^(mi)(-i)$/$1/i) {
	$final = "$2\n$final";
    }

    while (!exists $exception{lc $_} && 
	   s/^(.+)(-(n[ţtcvfgdşs]\p{L}*|m[bp]\p{L}*))$/$1/) {
	$final = "$2\n$final";
    }

    if (!exists $exception{lc $_} && 
	   s/^((\p{L}*ntr|şi|s|n|de|i|ţi|pe|te|mi|l|m|c|le|v|dac|ne|ş|parc|d|fii|dă)-)(.+)$/$3/i) {
	$initial = "$1\n";
    }

    while (!exists $exception{lc $_} && 
	   s/^(.+)(-(i|l|t|m|şi|ţi|o|se|mi|n|ului|te|un|ul|ai|mă|am|le|s|a|sa|urilor|ilor|astea|vă|aşa|ăla|al|ar|aici|eşte|au|t\'|m\'|mea|ăştia|napoi|ţ\'|aş|alea|aţi|ăsta))$/$1/) {
	$final = "$2\n$final";
    }

    while (!exists $exception{lc $_} && 
	   s/^(.+)(-(n[ţtcvfgdş]\p{L}*|m[bp]\p{L}*))$/$1/) {
	$final = "$2\n$final";
    }

    print "$initial$_\n$final";
}

#!/usr/bin/perl

use Getopt::Std;
getopts('t');

print doc_start();

$n = 0;
while (<>) {
  s/.-SBAR$/O/;

  if (/^(.*)-(.*)\t(.*)\/(.*)$/) {
    $token[$n] = $1;
    $tag[$n] = $2;
    $chunk[$n] = $4;
    if ($chunk[$n] =~ /^(.*)-(.*)$/) {
      $flag[$n] = $1;
      $chunk[$n] = $2;
    }
    else {
      undef $flag[$n];
      undef $chunk[$n];
    }
    print_sentence()  if $token[$n] eq '.';
    $n++;
  } 

  else {
    $markup[$n] .= $_;
  }
}

print_sentence();
print doc_end();


sub print_sentence {
  my($i,$chunk);

  for( $i=0; $i<=$n; $i++ ) {

    if ($flag[$i] eq 'I' && $chunk ne $chunk[$i]) {
      $flag[$i] = 'B';
    }

    if ($flag[$i] ne '' && $token[$i] eq '.') {
      delete $flag[$i];
      $chunk[$i] = '0';
    }

    if ($flag[$i] eq 'B') {
      if (defined $chunk) {
	if (($chunk eq 'PC' && $chunk[$i] eq 'NC') ||
	    ($chunk eq 'PP' && $chunk[$i] eq 'NP'))
	  {
	    $inPC = $chunk;
	  }
	else {
	  $cetags[$i-1] = end_tag($chunk);
	  if (defined $inPC) {
	    $cetags[$i-1] .= end_tag($inPC);
	    undef $inPC;
	  }
	}
      }
      $chunk = $chunk[$i];
      $cbtags[$i] .= start_tag($chunk[$i]);
    }

    elsif ($flag[$i] ne 'I' && defined $chunk) {
      $cetags[$i-1] = end_tag($chunk);
      undef $chunk;
      if (defined $inPC) {
	$cetags[$i-1] .= end_tag($inPC);
	undef $inPC;
      }
    }
  }

  for( $i=0; $i<=$n; $i++ ) {
    print $markup[$i];
    print $cbtags[$i];
    print token_and_tag($token[$i],$tag[$i]) if defined $token[$i];
    print $cetags[$i];
  }

  undef @token;
  undef @tag;
  undef @chunk;
  undef @cbtags;
  undef @cetags;
  undef @flag;
  undef @markup;
  $n = 0;
}

sub doc_start {
  return '' unless defined $opt_t;
  return "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n<corpus>\n";
}

sub doc_end {
  return '' unless defined $opt_t;
  return "</corpus>\n";
}

sub start_tag {
  my $t=shift;
  return "<$t>\n" unless defined $opt_t;
  return "  <phrase cat=\"$t\">\n";
}

sub end_tag {
  my $t=shift;
  return "</$t>\n" unless defined $opt_t;
  return "  </phrase>\n";
}

sub token_and_tag {
  my ($token,$tag)=@_;
  return "$token\t$tag\n" unless defined $opt_t;
  return "    <token word=\"$token\" pos=\"$tag\"/>\n";
}

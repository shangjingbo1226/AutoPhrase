#!/usr/bin/perl

###################################################################
###                                                             ###
###      File: filter-chunker-output.perl                       ###
###    Author: Michel Genereux                                  ###
###            (indicated modifications by Dennis Spohr (DS))   ###
###   Purpose: Filter chunker output and create XML-like markup ###
###   Created: Mon Feb 19 2007                                  ###
###                                                             ###
###################################################################

use Getopt::Std;
getopts('t');

$| = 1;

print doc_start();

### DS start: end-of-sentence marker
$eos = '[.?!;]';
$push = 1;
###

$n = 0;

while (<>) {
  s/.-SBAR$/O/;
  s/I-PC$/0/  if (/I-PC$/ && !$inside_pp);

  ### DS start: process lemma column
  if (($token[$n],$tag[$n],$tag,$chunk[$n],$lemma[$n]) = $_ =~ /^(.*)-(.*)\t(.*)\/(.*)\t(.*)$/) {
  ### DS end

    ### DS start: chunking error; some SENTs have e.g. I-NP although
    ###           they mark the end of a sentence; lead to omission 
    ###           of closing tags
    $push = 0;
    $chunk[$n] = 0 if ($tag eq 'SENT' && $chunk[$n] =~ /^(I|B)-/);
    ### DS end

    if ($chunk[$n] =~ /^(.*)-(.*)$/) {
      $flag[$n] = $1;
      $chunk[$n] = $2;
    } else {
      undef $flag[$n];
      undef $chunk[$n];
    }

    ### DS start: performance boost: set $n to 0 after printing
    ###           sentence; otherwise $n and arrays get too big 
    ###           and cause slowdown
    if ($token[$n] =~ /^$eos\s*$/ && $chunk[$n] == 0 && $tag[$n] eq 'SENT') {
      print_sentence(0);
      $n = 0;
      $start_markup = "";
    } else {
      $n++;
    }
    ### DS end

  ### DS start: keep markup already present in input data and insert
  ###           chunker markup correctly; if an element starting before
  ###           the sentence is closed before the sentence is closed
  ###           (e.g. headlines without sentence end markers), then
  ###           the sentence should also be closed, e.g. avoid cases like
  ###           <HEADLINE><s>Les résultats de jeudi</HEADLINE></s>
  } elsif (/^<([^\/]*?)(( |~).*)?>/ && $push) {
      push(@tag_stack,$1);
      $start_markup .= "$&\n";
  } elsif (/^<\/(.*?)>/ && $1 eq $tag_stack[$#tag_stack]) {
      $end_markup = "$&\n";
      print_sentence(1);
      $n = 0;
      $push = 1;
      $start_markup = "";
      $end_markup = "";
      pop(@tag_stack);
  ### DS end

  } else {
    $markup[$n] .= $_;
  }
}

print_sentence(1);
print doc_end();


sub print_sentence {

  ### DS start: indicate whether print_sentence is forced by
  ###           closing input markup
  my $forced = shift;
  ### DS end

  my($i,$chunk);

  for( $i=0; $i<=$n; $i++ ) {
    if ($flag[$i] eq 'I' && $chunk ne $chunk[$i]) {
      $flag[$i] = 'B';
    }
    if ($flag[$i] eq 'B') {
      if (defined $chunk) {
	$cetags[$i-1] .= end_tag($chunk);
      }
      if ($chunk[$i] eq 'PC') {
	for( $k=$i+1; $k<=$n; $k++ ) {
	  last if ($flag[$k] eq 'B');
	}
	for( $k++; $k<=$n; $k++ ) {
	  last if ($flag[$k] ne 'I');
	}
	if ($k <= $n && $flag[$k] eq 'E' && $chunk[$k] eq 'PC') {
	  $markup[$k+1] .= end_tag('PC');
	  undef $flag[$k];
	  undef $chunk[$k];

        ### DS start: $k may be greater than $n; add closing PC tag
        ###           to $markup[$n]; otherwise closing tags are
        ###           omitted
	} elsif ($k > $n && ($forced || $token[$n] =~ /^$eos\s*$/)) {
          $markup[$n] .= end_tag('PC');
        ### DS end

        } else {
	  $markup[$k] .= end_tag('PC');
	}
	undef $chunk;
      }
      else {
	$chunk = $chunk[$i];
      }
      $cbtags[$i] .= start_tag($chunk[$i]);
    }
    elsif ($flag[$i] eq 'E') {
      if ($chunk[$i] eq $chunk) {
	$cetags[$i] .= end_tag($chunk);
	undef $chunk;
      }
      elsif ($chunk[$i] eq 'PC') {
	$cetags[$i-1] .= end_tag($chunk) if defined $chunk;
	$cetags[$i] .= end_tag("PC");
	my $k;
	for( $k=$i; $k>=0; $k-- ) {
	  if ($flag[$k] eq 'B') {
	    $cbtags[$k] = start_tag("PC").$cbtags[$k];
	    last;
	  }
	}
	undef $chunk;
      }
      else {
	die;
      }
    }
    elsif ($flag[$i] ne 'I' && defined $chunk) {
      $cetags[$i-1] .= end_tag($chunk);
      undef $chunk;
    }
  }

  $printed = 0;# start_tag("s");

  ### DS start: print opening tags of input markup before sentence
  print $start_markup;
  print start_tag("s") if $n > 0;
  ### DS end

  for( $i=0; $i<=$n; $i++ ) {
    print $markup[$i];
    #unless ($printed) {
    #  print start_tag("s");
    #  $printed = 1;
    #}
    print $cbtags[$i];

    ### DS start: slightly renamed sub and added lemma parameter
    print token_and_tag_and_lemma($token[$i],$tag[$i],$lemma[$i]) if defined $token[$i];
    ### DS end

    print $cetags[$i];
  }

  ### DS start: print closing "s" tag and closing input markup if 
  ###           print_sentence had been forced
  print end_tag("s") if $n>0;
  print $end_markup if $forced;
  ### DS end

  undef @token;
  undef @tag;
  undef @chunk;
  undef @cbtags;
  undef @cetags;
  undef @flag;
  undef @markup;
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

### DS start: also process and output lemma parameter
sub token_and_tag_and_lemma {
  my ($token,$tag,$lemma)=@_;
  return "$token\t$tag\t$lemma\n" unless defined $opt_t;
  return "    <token word=\"$token\" lemma=\"$lemma\" pos=\"$tag\"/>\n";
}
### DS end


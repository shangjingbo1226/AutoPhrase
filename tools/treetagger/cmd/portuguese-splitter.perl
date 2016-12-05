#!/usr/bin/perl -w

#Splitter de procliticos e contraçoes para o Portugues

#author: Pablo Gamallo
#date: 18/11/2011
use utf8;
use Encode;

use locale;
use POSIX;
setlocale(LC_CTYPE,"pt_PT");

my $pron = "(me|te|mos|mas|mo|ma|tos|tas|to|ta|o|os|a|as|se|lhe|lhes|lho|lha|lhos|lhas|nos|vos|no-lo|no-los|no-la|no-las|vo-lo|vo-los|vo-la|vo-las|se-nos|se-vos|se-lhe|se-lhes|se-lho|se-lhos|se-lha|se-lhas)";


while ($line = <>) {
    $line = decode('UTF8', $line);
    chomp $line;

############separar ,...############
    $line =~ s/\,\.\.\./\, \.\.\./g;

###############Verbos + procliticos######################
    ##caso m-no -> m-o
    $line =~ s/m\-n([oa])\b/m\-$1/g;
    $line =~ s/m\-n([oa]s)\b/m\-$1/g; 

    ##separar cliticos compostos no-lo, vo-lo, se-nos...
    $line =~ s/([\-\W\s])(no|vo)-(l[oa]|l[oa]s)([\W\s])/$1$2s $3$4/g;
    $line =~ s/([\-\W\s])(no|vo)-(l[oa]|l[oa]s)$/$1$2s $3/g;
    $line =~ s/([\-\W\s])(se)-(n[oa]s|lh[eoa]s)([\W\s])/$1$2 $3$4/g;
    $line =~ s/([\-\W\s])(se)-(n[oa]s|lh[eoa]s)$/$1$2 $3/g;

  ##separar procliticos de verbos
  $line =~ s/([^\-\s]+)\-$pron([\W\s])/$1 $2$3/g;
    $line =~ s/([^\-\s]+)\-$pron$/$1 $2/g;

    ##separar cliticos compostos: mo, mos, to, tos, lho, lhos..
    $line =~ s/\bmo\b/me o/g;
    $line =~ s/\bmos\b/me os/g;
    $line =~ s/\bma\b/me a/g;
    # $line =~ s/\bmas\b/me as/g; AMBIGUO
    $line =~ s/\bto\b/te o/g;
    $line =~ s/\btos\b/te os/g;
    $line =~ s/\bta\b/te a/g;
    $line =~ s/\btas\b/te as/g;
    $line =~ s/\blhoo\b/lhe o/g;
    $line =~ s/\blhos\b/lhe os/g;
    $line =~ s/\blha\b/lhe a/g;
    $line =~ s/\blhas\b/lhe as/g;

    #$line =~ s/\bcho\b/che o/g;
    #$line =~ s/\bchos\b/che os/g;
    #$line =~ s/\bcha\b/che a/g;
    #$line =~ s/\bchas\b/che as/g;
##########################################################



###############separar contraçoes nao ambiguas###########

    #ao, à, aos, às
    $line =~ s/\bao([\s])/a o$1/g;
    $line =~ s/([\W\s])à([\s])/$1 a a$2/g;
    $line =~ s/\baos([\s])/a os$1/g;
    $line =~ s/([\W\s])às([\s])/$1 a as$2/g;

    #àquele(s), àquela(s). àquilo, aonde
    $line =~ s/([\W\s])àquele([\W\s])/$1 a aquel$2/g;
    $line =~ s/([\W\s])àqueles([\W\s])/$1 a aqueles$2/g;
    $line =~ s/([\W\s])àquela([\W\s])/$1 a aquela$2/g;
    $line =~ s/([\W\s])àquelas([\W\s])/$1 a aquelas$2/g;
    $line =~ s/([\W\s])àquilo([\W\s])/$1 a aquilo$2/g;
    
    $line =~ s/\baonde\b/a onde$1/g;

    #co(s), coa(s) /nao aparece no priberam nem no dico de freeling!
    # $line =~ s/\bco([\s])/com o$1/g;
    # $line =~ s/\bcoa([\s])/com a$1/g;
    # $line =~ s/\bcos([\s])/com os$1/g;
    # $line =~ s/\bcoas([\s])/com as$1/g;

    #do(s), da(s)
    $line =~ s/\bdo([\s])/de o$1/g;
    $line =~ s/\bdos([\s])/de os$1/g;
    $line =~ s/\bda([\s])/de a$1/g;
    $line =~ s/\bdas([\s])/de as$1/g;

    #dum(ns), duma(s)
    $line =~ s/\bdum([\s])/de um$1/g;
    $line =~ s/\bduns([\s])/de uns$1/g;
    $line =~ s/\bduma([\s])/de uma$1/g;
    $line =~ s/\bdumas([\s])/de umas$1/g;

    #dele(s), dela(s)
    $line =~ s/\bdele\b/de ele/g;
    $line =~ s/\bdeles\b/de eles/g;
    $line =~ s/\bdela\b/de ela/g;
    $line =~ s/\bdelas\b/de elas/g;

    #deste(s), desta(s), desse(s), dessa(s), daquele(s), daquela(s), disto, disso, daquilo
    #$line =~ s/([\W\s])deste([\W\s])/$1 de este$2/g; FORMA AMBIGUA
    # $line =~ s/\bdestes\b/de estes/g; FORMA AMBIGUA
    $line =~ s/\bdesta\b/de esta/g;
    $line =~ s/\bdestas\b/de estas/g;
    $line =~ s/\bdisto\b/de isto/g;
    #$line =~ s/\bdesse\b/de esse/g;  FORMA AMBIGUA
    #$line =~ s/\bdesses\b/de esses/g; FORMA AMBIGUA
    $line =~ s/\bdessa\b/de essa/g;
    $line =~ s/\bdessas\b/de essas/g;
    $line =~ s/\bdisso\b/de isso/g;
    $line =~ s/\bdaquele\b/de aquele/g;
    $line =~ s/\bdaquela\b/de aquela/g; ##em galego deveria ser ambigua (adverbio)
    $line =~ s/\bdaqueles\b/de aqueles/g;
    $line =~ s/\bdaquelas\b/de aquelas/g;
    $line =~ s/\bdaquilo\b/de aquilo/g;

    #daqui, daí, ali, acolá, donde, doutro(s), doutra(s)
    $line =~ s/\bdaqui\b/de aqui/g;
    $line =~ s/\bdaí\b/de aí/g; ##em galego deveria ser ambigua (adverbio)
    $line =~ s/\bdacolá\b/de acolá/g;
    $line =~ s/\bdonde\b/de onde/g;
    $line =~ s/\bdoutro\b/de outro/g;
    $line =~ s/\bdoutros\b/de outros/g;

    $line =~ s/\bdoutra\b/de outra/g;
    $line =~ s/\bdoutras\b/de outras/g;

    #no(s), na(s)
    $line =~ s/\bno([\s])/em o$1/g;
    #$line =~ s/\bnos([\s])/em os$1/g;
    $line =~ s/\bna([\s])/em a$1/g;
    $line =~ s/\bnas([\s])/em as$1/g;
    
    #dum(ns), duma(s)
    $line =~ s/\bnum([\s])/em um$1/g;
    $line =~ s/\bnuns([\s])/em uns$1/g;
    $line =~ s/\bnuma([\s])/em uma$1/g;
    $line =~ s/\bnumas([\s])/em umas$1/g;
    
    #nele(s)
    # $line =~ s/\bnele\b/em ele/g;
    $line =~ s/\bneles\b/em eles/g;

    #neste(s), nesta(s), nesse(s), nessa(s), naquele(s), naquela(s), nisto, nisso, naquilo
    $line =~ s/\bneste\b/em este/g; 
    $line =~ s/\bnestes\b/em estes/g;
    $line =~ s/\bnesta\b/em esta/g;
    $line =~ s/\bnestas\b/em estas/g;
    $line =~ s/\bnisto\b/em isto/g;
    $line =~ s/\bnesse\b/em esse/g;  
    $line =~ s/\bnesses\b/em esses/g; 
    $line =~ s/\bnessa\b/em essa/g;
    $line =~ s/\bnessas\b/em essas/g;
    $line =~ s/\bnisso\b/em isso/g;
    $line =~ s/\bnaquele\b/em aquele/g;
    $line =~ s/\bnaquela\b/em aquela/g; 
    $line =~ s/\bnaqueles\b/em aqueles/g;
    $line =~ s/\bnaquelas\b/em aquelas/g;
    $line =~ s/\bnaquilo\b/em aquilo/g;

    #pelo(a), polo(s)  TODOS AMBIGUOS!
    # $line =~ s/\bpelo([\s])/por o$1/g;
    # $line =~ s/\bpela([\s])/por a$1/g;
    # $line =~ s/\bpelos([\s])/por os$1/g;
    # $line =~ s/\bpelas([\s])/por as$1/g;

    # $line =~ s/\bpolo([\s])/por o$1/g;
    # $line =~ s/\bpola([\s])/por a$1/g;
    # $line =~ s/\bpolos([\s])/por os$1/g;
    # $line =~ s/\bpolas([\s])/por as$1/g;


    #dentre
    $line =~ s/\bdentre\b/de entre/g;
    
    #aqueloutro, essoutro, estoutro
    $line =~ s/\baqueloutro\b/aquele outro/g;
    $line =~ s/\baqueloutros\b/aqueles outros/g;
    $line =~ s/\baqueloutra\b/aquela outra/g; 
    $line =~ s/\baqueloutras\b/aquelas outras/g; 
    $line =~ s/\bessoutro\b/esse outro/g; 
    $line =~ s/\bessoutros\b/esses outros/g;
    $line =~ s/\bessoutra\b/essa outra/g; 
    $line =~ s/\bessoutras\b/esse outras/g; 
    $line =~ s/\bestoutro\b/este outro/g;  
    $line =~ s/\bestoutros\b/estes outros/g;  
    $line =~ s/\bestoutra\b/esta outra/g;
    $line =~ s/\bestoutra\b/este outra/g;    
    
    print encode('UTF8',$line),"\n";
} 


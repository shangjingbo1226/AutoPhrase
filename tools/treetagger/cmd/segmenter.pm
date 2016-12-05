#A simple tokeniser of Chinese texts
#Serge Sharoff, University of Leeds
#initially derived from a script of Erik Peterson, www.mandarintools.com
#the extended with the Viterbi frequency estimate

use Carp;
#use strict;

sub min {
    return ($_[0]<$_[1]) ? $_[0] : $_[1]
}
sub openfile {
    open(my $fh, "<:utf8", $_[0]) or croak "Cannot open $_[0]: $!";
    return $fh;
}

my $maxwordlength=8; #do not consider words longer than 8 characters

#my ($maxdlen,$cforeign,$cnumbers,$cnumbersonly,$numberdesc,$ctime,$wascii,$surname,$uncommonsurname,$notname,$cpunctuation);
$outsepar="\n";
#my (%cwords,%bothonechar,%contextbothonechar,%firstonechar);
sub init{
#parameters: unigrams, bigrams
    my ($wlist,$w2list)=@_;

#almost as in Erik's script

# Read in the lexicon
    my $wrdsfh=openfile($wlist);
    $maxdlen=0;
    while (<$wrdsfh>) {
	chomp;
	next if /^\%\%/; # for TnT-style comments
	if (/(\S+)\t([\d.-]+)/) { #报道\tlogfreq
	    my $l=length($1);
	    next if $l>$maxwordlength; #most of what is longer is garbage
	    $cwords{$1} = $2;
	    $maxdlen=$l if $l>$maxdlen;
	}
    }
    close($wrdsfh);
    if ($w2list) { # 就 是\tlogfreq bigrams
	$wrdsfh=openfile($w2list);
	while (<$wrdsfh>) {
	    chomp;
	    if (/(\S+? \S+?)\t([\d.-]+)/) {
		$bigrams{$1} = $2;
	    }
	}
    }

# Numbers
    $cnumbers  = "零○一二三四五六七八九十百千万亿０１２３４５６７８９第";  #Chinese nrs
    $cnumbersonly  = "零○二三四五六七八九十百千万亿";  #traditional Chinese nrs
    $numberdesc = $cnumbers."多半数几俩卅两壹贰叁肆伍陆柒捌玖拾伯仟％‰．点.-"; #and what can follow them
    utf8::decode($cnumbers);
    utf8::decode($cnumbersonly);
    utf8::decode($numberdesc);
    $NUMBERLOG=log(34298/1000000); #the log frequency of numbers according to LCMC
    @numberdesc{split //,$numberdesc.'0123456789'}=(); 
# Wide ASCII words
    $wascii =  "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ．";
    $wascii .= "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ－-";
    utf8::decode($wascii);

# Foreign name transliteration characters
#     $cforeign =  "阿克拉加内亚斯贝巴尔姆爱兰尤利西詹乔伊费杰罗纳布可夫福赫勒柯特";
#     $cforeign .= "劳伦坦史芬尼根登都伯林伍泰胥黎俄科索沃金森奥霍瓦茨普蒂塞维大利";
#     $cforeign .= "格莱德冈萨雷墨哥弗库澳马哈多兹戈乌奇切诺戴里诸塞吉基延科达塔博";
#     $cforeign .= "卡雅来莫波艾哈迈蓬安卢什比摩曼乃休合赖米那迪凯莱温帕桑佩蒙博托";
#     $cforeign .= "谢格泽洛及希卜鲁匹齐兹印古埃努烈达累法贾图喀土穆腓基冉休盖耶沙";
#     $cforeign .= "逊宾麦华万";
$cforeign  = "阿埃艾爱安奥澳巴保鲍贝本比宾波伯柏勃卜布茨达戴德登迪蒂丁都顿多俄厄恩尔法菲费芬";  #大博
$cforeign .= "夫福弗佛盖甘冈哥戈格根古哈海合赫胡华霍基吉加伽贾杰捷金喀卡凯柯科可克肯库拉"; #及
$cforeign .= "莱来赖兰劳勒雷累黎里利莉烈林琳卢鲁伦罗洛马玛麦迈曼梅蒙米摩莫墨默姆穆那娜纳乃";
$cforeign .= "内尼妮努诺帕佩裴蓬皮匹泼普奇齐乔切冉萨塞桑瑟森沙莎舍什史士斯丝舒索苏塔泰坦特图土托瓦万";
$cforeign .= "维温文沃乌伍西希谢辛休逊雅亚延耶伊印尤泽扎詹诸兹腓胥";
    utf8::decode($cforeign);
    @cforeign{split //,$cforeign}=(); 

#Chinese surnames
    $surname = "李王張张劉刘陳陈楊杨黃黄趙赵周吳吴徐孫孙朱馬马胡郭林何高梁鄭郑羅罗宋謝谢唐韓韩曹許许鄧邓蕭萧肖馮冯曾程蔡彭潘袁于董余蘇苏葉叶呂吕魏蔣蒋田杜丁沈姜范江傅鍾钟盧卢汪戴崔任陸陆廖姚方金邱夏譚谭韋韦賈贾鄒邹石熊孟秦閻阎薛侯雷白龍龙段郝孔邵史毛常萬万顧顾賴赖武康賀贺嚴严尹錢钱施牛洪龔龚佘麥麦莊庄路黎符邢倪陶葛"; #only the most common ones 
    # $surname  = "艾安敖白班包宝保鲍贝毕边卞柏卜蔡曹岑柴昌常陈成程迟池褚楚";
    # $surname .= "储淳崔戴刀邓狄刁丁董窦杜端段樊范方房斐丰封冯凤伏福傅盖甘";
    # $surname .= "高戈耿龚宫勾苟辜谷古顾官关管桂郭韩杭郝禾何贺赫衡洪侯胡花";
    # $surname .= "华黄霍稽姬吉纪季贾简翦姜江蒋焦晋金靳荆居康柯空孔匡邝况赖蓝";
    # $surname .= "郎朗劳乐雷冷黎李理厉利励连廉练良梁廖林凌刘柳隆龙楼娄卢吕鲁";
    # $surname .= "陆路伦罗洛骆麻马麦满茅毛梅孟米苗缪闵明莫牟穆倪聂牛钮农潘庞";
    # $surname .= "裴彭皮朴平蒲溥浦戚祁齐钱强乔秦丘邱仇裘屈瞿权冉饶任荣容阮";
    # $surname .= "瑞芮萨赛沙单商邵佘申沈盛石史寿舒斯宋苏孙邰谭谈汤唐陶滕";
    # $surname .= "田佟仝屠涂万汪王危韦魏卫蔚温闻翁巫邬伍武吴奚习夏鲜冼";
    # $surname .= "项萧解谢辛邢幸熊徐许宣薛荀颜阎言严彦晏燕杨阳姚叶蚁易殷银尹";
    # $surname .= "应英游尤於鱼虞俞余禹喻郁尉元袁岳云臧曾翟詹湛张章招赵甄";
    # $surname .= "郑钟周诸朱竺祝庄卓宗邹祖左";
    $uncommonsurname = "车成全韩赖连路明牛权时水文席应英于查费"; #to protect from errors caused by their treatment as names

    utf8::decode($surname);
    $NAMELOG=log(932/1000000); #the log frequency of names according to LCMC
    utf8::decode($uncommonsurname);

# Add in 2 character surnames; also add to lexicon so they'll be segmented as one unit
#     $csurname{"东郭"} = 1; $cwords{"东郭"} = 1;
#     $csurname{"公孙"} = 1; $cwords{"公孙"} = 1;
#     $csurname{"皇甫"} = 1; $cwords{"皇甫"} = 1;
#     $csurname{"慕容"} = 1; $cwords{"慕容"} = 1;
#     $csurname{"欧阳"} = 1; $cwords{"欧阳"} = 1;
#     $csurname{"单于"} = 1; $cwords{"单于"} = 1;
#     $csurname{"司空"} = 1; $cwords{"司空"} = 1;
#     $csurname{"司马"} = 1; $cwords{"司马"} = 1;
#     $csurname{"司徒"} = 1; $cwords{"司徒"} = 1;
#     $csurname{"澹台"} = 1; $cwords{"澹台"} = 1;
#     $csurname{"诸葛"} = 1; $cwords{"诸葛"} = 1;

#Not in name
    $notname  = "的说对在和是被最所那这有将会与於他为";
    utf8::decode($notname);
    $cpunctuation = "、：，。★〖〗（）⊙～【】―・？！“”　";
    utf8::decode($cpunctuation);

    $notname  .=$cpunctuation;

#dates (they combine with arabic digits)
    $ctime= "年月日";
    utf8::decode($ctime);

#    $outsepar="\n";

    return($maxdlen);
}

sub isChineseChar {
    my $c=ord($_[0]); #a list of cases when we know it's not Zh
    my $res= (($c<0x25CB) # or white circle is frequently used for zero
	    # ($c<0x2E80) #outside CJK
	    or ($c>0xFF00) #outside CJK, covers wascii as well
	    or (($c>=0x3000) and ($c<=0x301F)) #ideographic punctuation
	    or (($c>=0x3041) and ($c<=0x309F)) #hiragana
	    or (($c>=0x30A1) and ($c<=0x30FF))) #katakana
	? 0 : 1;
    return $res;
}

sub isChineseStr {
    my($cstr) = @_;
    for (my $i = 0; $i < length($cstr); $i++) {
	return 0 unless isChineseChar(substr($cstr, $i, 1))
    }
    return 1;
}

sub isChineseName { #it could be a name
    my $last2chars=substr($_[0],length($_[0])-2);
    return ($_[0]=~/[$notname]/) ? 0 : 
	((length($_[0]) <= 3) and ($_[0]=~/^[$surname]/) and
	(! exists $cwords{$last2chars})) ? 1 : 0;
}

sub checkchars {
    my ($s,$cref)=@_;
    foreach (split //,$s) {
	if (!exists(${$cref}{$_})) {
	    return 0;
	}
    }
    return 1;
}

sub segmentline {
    my($line) = @_;
    undef my @outlines;
    my $linelen = length($line);
    for (my $i = 0; $i < $linelen; $i++) {
	my $curwlen=1;
	my $char = substr($line, $i, 1);
	next if $char=~/\s/;
	my $nextchar;
	my $j;
	if (isChineseChar($char)) { #a Chinese string starts
	    my $next=$i;
	    while (($next<=$linelen) and #we'll find a Chinese only string
		   (isChineseChar(substr($line,$next++,1)))) {};
	    my ($p,$split)=segmentchinese(substr($line,$i,$next-$i-1));
	    push @outlines, split(' ',$split);
	    $i=$next-2; #we're already on the next char and it'll grow by 1
	} else {  #non-Chinese
	    if ($char eq '<') { #XML tags are copied till the first '>'
		if ((my $sgmlend=index($line,'>',$i+1)) > 0) {
		    $curwlen=$sgmlend+1-$i;
		}
	    } elsif ($char=~/\w/) { # non-chinese alphanumerics	    
		for ($j=$i+1; $j<$linelen; $j++) {
		    $nextchar=substr($line,$j,1);
		    last if isChineseChar($nextchar);
		    last unless $nextchar=~/[\w.:\/%$-]/;
		    #to cover 9.3%, multi-functional, http://
		};
		$j++ if ($nextchar=~/[$ctime]/) and 
		    (substr($line,$i,$j-$i)=~/^[\d$cnumbers-]+$/); # date
		$curwlen=$j-$i;
	    } else { # punctuation and ascii drawings
		for ($j=$i+1; $j<$linelen; $j++) {
		    $nextchar=substr($line,$j,1);
		    last if ($nextchar=~/\w/) or (isChineseChar($nextchar));
		};
		$curwlen=$j-$i;
	    }
	    push @outlines,substr($line,$i,$curwlen);
	    $i+=$curwlen-1;
	};

    }

    return join($outsepar,@outlines)
}

sub splits {
#we refrain from generating nonsensical splits
#1. the splits of Chinese chars are shorter than $maxdlen
#2. we take the numbers and dates into account
    my $cstr=shift;
    my $clen=length($cstr);
    undef my @out;
    for (my $i = 1; $i <= min($maxdlen,$clen); $i++) {
	my $first=substr($cstr,0,$i);
	my $rem=substr($cstr,$i);
	my $fc=substr($first,length($first)-1,1);
	my $rc=substr($rem,0,1);
	next if ((exists $numberdesc{$fc}) and (exists $numberdesc{$rc})) or
	    ((exists $cforeign{$fc}) and (exists $cforeign{$rc})) or
	    ((exists $numberdesc{$fc}) and ($rc=~/^[$ctime]/));
	
	push @out,[$first,$rem];
    }
    return @out;
}


sub cPw { #returns log of the conditional probability P(w|p)
    my ($w,$p)=@_;
    $p='' unless defined $p;
    my $r;
    if ((exists $bigrams{"$p $w"}) and (exists $cwords{$p})) {
	return ($bigrams{"$p $w"}-$cwords{$p});
    } else { 
	## backoff cases
	if (exists $cwords{$w}) {
	    $r=$cwords{$w};
	} elsif (isChineseName($w)) {
	    $r=$NAMELOG;
	} elsif ($w=~/^[$cforeign]+$/) {
	    $r=$NAMELOG-1;  # a bit arbitrary, but ..
	} elsif ($w=~/^[$numberdesc]+$/) {
	    $r=$NUMBERLOG;  
	} else {
	    $r=log(1/(1000000*10**(3*length($w))));
	};
	return $r
    }
}

sub segmentchinese{
#following segment2 in Peter Norvig's "Natural Language Corpus Data"
    my ($text,$prev)=@_;
    if (exists $knownsegs{$text}) {
	return $knownsegs{$text}->[0],$knownsegs{$text}->[1]
    };
    undef my %cs;
    my ($f,$p);
    if (length($text)>1) {
	my @out=splits($text);
	foreach (@out) {
	    $f=$_->[0];
	    $r=$_->[1];
	    ($p,$rsegment)=($r=~/\S/)? segmentchinese($r,$f) : (0,'');
	    $cs{"$f $rsegment"}=cPw($f,$prev)+$p;
#printf STDERR "%.2f %s<-%s\n",$cs{"$f $rsegment"},$f,$rsegment
	};
    } else {
	$f=$text;
	$rsegment='';
	$cs{"$f $rsegment"}=cPw($f,$prev);
    }
    my $bestkey="$f $rsegment";
    my $maxp=$cs{$bestkey};
    for (keys %cs) {
	if ($cs{$_}>$maxp) {
	    $maxp=$cs{$_};
	    $bestkey=$_;
	}
    }
    $knownsegs{$text}=[$maxp,$bestkey];
    return $maxp,$bestkey
}

1;


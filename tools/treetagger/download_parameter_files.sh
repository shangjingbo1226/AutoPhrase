CHINESE_URL="https://corpus.leeds.ac.uk/tools/zh/tt-lcmc.tgz"
ENGLISH_URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/english.par.gz"
FRENCH_URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/french-par-linux-3.2-utf8.bin.gz"
GERMAN_URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/german-par-linux-3.2-utf8.bin.gz"
ITALIAN_URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/italian-par-linux-3.2-utf8.bin.gz"
PORTUGUESE_URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/portuguese-par-linux-3.2-utf8.bin.gz"
RUSSIAN_URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/russian-par-linux-3.2-utf8.bin.gz"
SPANISH_URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/spanish-par-linux-3.2-utf8.bin.gz"

if [ $LANGUAGE == "CN" ] && [ ! -e tools/treetagger/lib/zh.par ];
then
    curl $CHINESE_URL --output tmp/chinese-par-linux-3.2-utf8.tgz
    tar zxf tmp/chinese-par-linux-3.2-utf8.tgz -C tools/treetagger/ lib/zh.par
    echo 'Chinese parameter file (Linux, UTF8) installed.'
    rm tmp/chinese-par-linux-3.2-utf8.tgz
fi

if [ $LANGUAGE == "DE" ] && [ ! -e tools/treetagger/lib/german-utf8.par ];
then
    curl $GERMAN_URL --output tmp/german-par-linux-3.2-utf8.bin.gz
    gzip -cd tmp/german-par-linux-3.2-utf8.bin.gz > tools/treetagger/lib/german-utf8.par
    echo 'German parameter file (Linux, UTF8) installed.'
    rm tmp/german-par-linux-3.2-utf8.bin.gz
fi

if [ $LANGUAGE == "EN" ] && [ ! -e tools/treetagger/lib/english-utf8.par ];
then
    curl $ENGLISH_URL --output tmp/english-par-linux-3.2-utf8.bin.gz
    gzip -cd tmp/english-par-linux-3.2-utf8.bin.gz > tools/treetagger/lib/english-utf8.par
    chmod 775 tools/treetagger/lib/english-utf8.par
    echo 'English parameter file (Linux, UTF8) installed.'
    rm tmp/english-par-linux-3.2-utf8.bin.gz
fi

if [ $LANGUAGE == "FR" ] && [ ! -e tools/treetagger/lib/french-utf8.par ];
then
    curl $FRENCH_URL --output tmp/french-par-linux-3.2-utf8.bin.gz
    gzip -cd tmp/french-par-linux-3.2-utf8.bin.gz > tools/treetagger/lib/french-utf8.par
    echo 'French parameter file (Linux, UTF8) installed.'
    rm tmp/french-par-linux-3.2-utf8.bin.gz
fi

if [ $LANGUAGE == "IT" ] && [ ! -e tools/treetagger/lib/italian-utf8.par ];
then
    curl $ITALIAN_URL --output tmp/italian-par-linux-3.2-utf8.bin.gz
    gzip -cd tmp/italian-par-linux-3.2-utf8.bin.gz > tools/treetagger/lib/italian-utf8.par
    echo 'Italian parameter file (Linux, UTF8) installed.'
    rm tmp/italian-par-linux-3.2-utf8.bin.gz
fi

if [ $LANGUAGE == "PT" ] && [ ! -e tools/treetagger/lib/portuguese-utf8.par ];
then
    curl $PORTUGUESE_URL --output tmp/portuguese-par-linux-3.2-utf8.bin.gz
    gzip -cd tmp/portuguese-par-linux-3.2-utf8.bin.gz > tools/treetagger/lib/portuguese-utf8.par
    echo 'Portuguese parameter file (Linux, UTF8) installed.'
    rm tmp/portuguese-par-linux-3.2-utf8.bin.gz
fi

if [ $LANGUAGE == "RU" ] && [ ! -e tools/treetagger/lib/russian-utf8.par ];
then
    curl $RUSSIAN_URL --output tmp/russian-par-linux-3.2-utf8.bin.gz
    gzip -cd tmp/russian-par-linux-3.2-utf8.bin.gz > tools/treetagger/lib/russian-utf8.par
    echo 'Russian parameter file (Linux, UTF8) installed.'
    rm tmp/russian-par-linux-3.2-utf8.bin.gz
fi

if [ $LANGUAGE == "ES" ] && [ ! -e tools/treetagger/lib/spanish-utf8.par ];
then
    curl $SPANISH_URL --output tmp/spanish-par-linux-3.2-utf8.bin.gz
    gzip -cd tmp/spanish-par-linux-3.2-utf8.bin.gz > tools/treetagger/lib/spanish-utf8.par
    echo 'Spanish parameter file (Linux, UTF8) installed.'
    rm tmp/spanish-par-linux-3.2-utf8.bin.gz
fi

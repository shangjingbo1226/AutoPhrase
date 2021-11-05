CHINESE_URL="https://corpus.leeds.ac.uk/tools/zh/tt-lcmc.tgz"

if [ $LANGUAGE == "CN" ] && [ ! -e tools/treetagger/lib/zh.par ];
then
    curl $CHINESE_URL --output tmp/chinese-par-linux-3.2-utf8.tgz
    tar zxf tmp/chinese-par-linux-3.2-utf8.tgz -C tools/treetagger/ lib/zh.par
    echo 'Chinese parameter file (Linux, UTF8) installed.'
    rm tmp/chinese-par-linux-3.2-utf8.tgz
fi


case $LANGUAGE in
    EN|FR|DE|IT|PT|RU|ES)
        if [ $LANGUAGE == "EN" ]; then EXT_LANGUAGE="english"; fi
        if [ $LANGUAGE == "FR" ]; then EXT_LANGUAGE="french"; fi
        if [ $LANGUAGE == "DE" ]; then EXT_LANGUAGE="german"; fi
        if [ $LANGUAGE == "IT" ]; then EXT_LANGUAGE="italian"; fi
        if [ $LANGUAGE == "PT" ]; then EXT_LANGUAGE="portuguese"; fi
        if [ $LANGUAGE == "RU" ]; then EXT_LANGUAGE="russian"; fi
        if [ $LANGUAGE == "ES" ]; then EXT_LANGUAGE="spanish"; fi
        # 
        COMPR_FILE=$EXT_LANGUAGE".par.gz"
        FINAL_FILE=$EXT_LANGUAGE"-utf8.par"
        URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/"$COMPR_FILE
        # 
        if [ ! -e "tools/treetagger/lib/"$FINAL_FILE ];
        then
            curl $URL --output "tmp/"$COMPR_FILE
            gzip -cd "tmp/"$COMPR_FILE > "tools/treetagger/lib/"$FINAL_FILE
            echo $EXT_LANGUAGE' parameter file (Linux, UTF8) installed.'
            rm "tmp/"$COMPR_FILE
        fi
    ;;
esac

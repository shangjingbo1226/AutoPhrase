#!/bin/bash
# In effect, the commands below check to see if we're running in a Docker container--in that case, the (default) 
# "data" and "models" directories will have been renamed, in order to avoid conflicts with mounted directories 
# with the same names.
#
# DATA_DIR is the default directory for reading data files.  Because this directory contains not only the default
# dataset, but also language-specific files and "BAD_POS_TAGS.TXT", in most cases it's a bad idea to change it.
# However, when this script is run from a Docker container, it's perfectly fine for the user to mount an external
# directory called "data" and read the corpus from there, since the directory holding the language-specific files
# and "BAD_POS_TAGS.txt" will have been renamed to "default_data".
if [ -d "default_data" ]; then
    DATA_DIR=${DATA_DIR:- default_data}
else
    DATA_DIR=${DATA_DIR:- data}
fi
# MODEL is the directory in which the resulting model will be saved.
if [ -d "models" ]; then
    MODELS_DIR=${MODELS_DIR:- models}
else
    MODELS_DIR=${MODELS_DIR:- default_models}
fi
MODEL=${MODEL:- ${MODELS_DIR}/DBLP}
# RAW_TRAIN is the input of AutoPhrase, where each line is a single document.
DEFAULT_TRAIN=${DATA_DIR}/EN/DBLP.txt
RAW_TRAIN=${RAW_TRAIN:- $DEFAULT_TRAIN}
# When FIRST_RUN is set to 1, AutoPhrase will run all preprocessing. 
# Otherwise, AutoPhrase directly starts from the current preprocessed data in the tmp/ folder.
FIRST_RUN=${FIRST_RUN:- 1}
# POS_TAGGING_MODE: 0, a simple length penalty mode as the same as SegPhrase will be used.
#                   1, AutoPhrase will automatically POS tag your text.
#                   2, AutoPhrase expects an alreaedy tokenized and POS tagged text.
POS_TAGGING_MODE=${POS_TAGGING_MODE:- 1}
# A hard threshold of raw frequency is specified for frequent phrase mining, which will generate a candidate set.
MIN_SUP=${MIN_SUP:- 10}
# You can also specify how many threads can be used for AutoPhrase
THREAD=${THREAD:- 10}
COMPILE=${COMPILE:- 1}
### Begin: Suggested Parameters ###
MAX_POSITIVES=-1
LABEL_METHOD=DPDN
RAW_LABEL_FILE=${RAW_LABEL_FILE:-""}
### End: Suggested Parameters ###

green=`tput setaf 2`
reset=`tput sgr0`

if [ $COMPILE -eq 1 ]; then
    echo ${green}===Compilation===${reset}
    bash compile.sh
fi

mkdir -p tmp
mkdir -p ${MODEL}

if [ $RAW_TRAIN == $DEFAULT_TRAIN ] && [ ! -e $DEFAULT_TRAIN ]; then
    echo ${green}===Downloading Toy Dataset===${reset}
    curl http://dmserv2.cs.illinois.edu/data/DBLP.txt.gz --output ${DEFAULT_TRAIN}.gz
    gzip -d ${DEFAULT_TRAIN}.gz -f
fi

### END Compilation###

TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer"
#TOKENIZER="-cp .;tools/tokenizer/lib/*;tools/tokenizer/resources/;tools/tokenizer/build/ Tokenizer"
TOKEN_MAPPING=tmp/token_mapping.txt

if [ $FIRST_RUN -eq 1 ]; then
    echo ${green}===Tokenization===${reset}
    TOKENIZED_TRAIN=tmp/tokenized_train.txt
#    CASE=tmp/case_tokenized_train.txt
    echo -ne "Current step: Tokenizing input file...\033[0K\r"
    if [ $POS_TAGGING_MODE -eq 2 ]; then
        time java $TOKENIZER -m train -i $RAW_TRAIN -o $TOKENIZED_TRAIN -t $TOKEN_MAPPING -c N -thread $THREAD -delimiters " "
    else
        time java $TOKENIZER -m train -i $RAW_TRAIN -o $TOKENIZED_TRAIN -t $TOKEN_MAPPING -c N -thread $THREAD
    fi    
fi

LANGUAGE=`cat tmp/language.txt`
LABEL_FILE=tmp/labels.txt

if [ $FIRST_RUN -eq 1 ]; then
    echo -ne "Detected Language: $LANGUAGE\033[0K\n"
    TOKENIZED_STOPWORDS=tmp/tokenized_stopwords.txt
    TOKENIZED_ALL=tmp/tokenized_all.txt
    TOKENIZED_QUALITY=tmp/tokenized_quality.txt
    STOPWORDS=$DATA_DIR/$LANGUAGE/stopwords.txt
    ALL_WIKI_ENTITIES=$DATA_DIR/$LANGUAGE/wiki_all.txt
    QUALITY_WIKI_ENTITIES=$DATA_DIR/$LANGUAGE/wiki_quality.txt
    echo -ne "Current step: Tokenizing stopword file...\033[0K\r"
    java $TOKENIZER -m test -i $STOPWORDS -o $TOKENIZED_STOPWORDS -t $TOKEN_MAPPING -c N -thread $THREAD
    echo -ne "Current step: Tokenizing wikipedia phrases...\033[0K\n"
    java $TOKENIZER -m test -i $ALL_WIKI_ENTITIES -o $TOKENIZED_ALL -t $TOKEN_MAPPING -c N -thread $THREAD
    java $TOKENIZER -m test -i $QUALITY_WIKI_ENTITIES -o $TOKENIZED_QUALITY -t $TOKEN_MAPPING -c N -thread $THREAD
fi  

### END Tokenization ###

if [[ $RAW_LABEL_FILE = *[!\ ]* ]]; then
	echo -ne "Current step: Tokenizing expert labels...\033[0K\n"
	java $TOKENIZER -m test -i $RAW_LABEL_FILE -o $LABEL_FILE -t $TOKEN_MAPPING -c N -thread $THREAD
else
	echo -ne "No provided expert labels.\033[0K\n"
fi

if [ ! $LANGUAGE == "JA" ] && [ ! $LANGUAGE == "CN" ]  && [ ! $LANGUAGE == "OTHER" ] && [ $FIRST_RUN -eq 1 ]; then
    if [ $POS_TAGGING_MODE -eq 1 ]; then
        echo ${green}===Part-Of-Speech Tagging===${reset}
        RAW=tmp/raw_tokenized_train.txt
        export THREAD LANGUAGE RAW
        bash ./tools/treetagger/pos_tag.sh
        mv tmp/pos_tags.txt tmp/pos_tags_tokenized_train.txt
    elif [ $POS_TAGGING_MODE -eq 2 ]; then
        echo ${green}===Loading Part-Of-Speech Tagged file===${reset}
        cp $DATA_DIR/$LANGUAGE/pos_tags.txt tmp/pos_tags_tokenized_train.txt
    fi
fi

### END Part-Of-Speech Tagging ###

echo ${green}===AutoPhrasing===${reset}

if [[ $POS_TAGGING_MODE -eq 1 || $POS_TAGGING_MODE -eq 2 ]]; then
    time ./bin/segphrase_train \
        --pos_tag \
        --thread $THREAD \
        --pos_prune ${DATA_DIR}/BAD_POS_TAGS.txt \
        --label_method $LABEL_METHOD \
		--label $LABEL_FILE \
        --max_positives $MAX_POSITIVES \
        --min_sup $MIN_SUP
else
    time ./bin/segphrase_train \
        --thread $THREAD \
        --label_method $LABEL_METHOD \
		--label $LABEL_FILE \
        --max_positives $MAX_POSITIVES \
        --min_sup $MIN_SUP
fi

echo ${green}===Saving Model and Results===${reset}

cp tmp/segmentation.model ${MODEL}/segmentation.model
cp tmp/token_mapping.txt ${MODEL}/token_mapping.txt
cp tmp/language.txt ${MODEL}/language.txt

### END AutoPhrasing ###

echo ${green}===Generating Output===${reset}
java $TOKENIZER -m translate -i tmp/final_quality_multi-words.txt -o ${MODEL}/AutoPhrase_multi-words.txt -t $TOKEN_MAPPING -c N -thread $THREAD
java $TOKENIZER -m translate -i tmp/final_quality_unigrams.txt -o ${MODEL}/AutoPhrase_single-word.txt -t $TOKEN_MAPPING -c N -thread $THREAD
java $TOKENIZER -m translate -i tmp/final_quality_salient.txt -o ${MODEL}/AutoPhrase.txt -t $TOKEN_MAPPING -c N -thread $THREAD

# java $TOKENIZER -m translate -i tmp/distant_training_only_salient.txt -o results/DistantTraning.txt -t $TOKEN_MAPPING -c N -thread $THREAD

### END Generating Output for Checking Quality ###

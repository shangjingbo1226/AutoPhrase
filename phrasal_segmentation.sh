# As in "auto_phrase.sh", make the default model amd data directories depend on whether or not we're running
# from a Docker container.
if [ -d "default_models" ]; then
    MODELS_DIR=${MODELS_DIR:- default_models}
else
    MODELS_DIR=${MODELS_DIR:- models}
fi
MODEL=${MODEL:- ${MODELS_DIR}/DBLP}
if [ -d "default_data" ]; then
    DATA_DIR=${DATA_DIR:- default_data}
else
    DATA_DIR=${DATA_DIR:- data}
fi
TEXT_TO_SEG=${TEXT_TO_SEG:- ${DATA_DIR}/EN/DBLP.5K.txt}
HIGHLIGHT_MULTI=${HIGHLIGHT_MULTI:- 0.5}
HIGHLIGHT_SINGLE=${HIGHLIGHT_SINGLE:- 0.8}

SEGMENTATION_MODEL=${MODEL}/segmentation.model
TOKEN_MAPPING=${MODEL}/token_mapping.txt

ENABLE_POS_TAGGING=1
THREAD=10

green=`tput setaf 2`
reset=`tput sgr0`

echo ${green}===Compilation===${reset}

COMPILE=${COMPILE:- 1}
if [ $COMPILE -eq 1 ]; then
    bash compile.sh
fi

mkdir -p tmp
mkdir -p ${MODEL}

### END Compilation###

echo ${green}===Tokenization===${reset}

TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer"
TOKENIZED_TEXT_TO_SEG=tmp/tokenized_text_to_seg.txt
CASE=tmp/case_tokenized_text_to_seg.txt


echo -ne "Current step: Tokenizing input file...\033[0K\r"
time java $TOKENIZER -m direct_test -i $TEXT_TO_SEG -o $TOKENIZED_TEXT_TO_SEG -t $TOKEN_MAPPING -c N -thread $THREAD

LANGUAGE=`cat ${MODEL}/language.txt`
echo -ne "Detected Language: $LANGUAGE\033[0K\n"

### END Tokenization ###

echo ${green}===Part-Of-Speech Tagging===${reset}

if [ ! $LANGUAGE == "JA" ] && [ ! $LANGUAGE == "CN" ]  && [ ! $LANGUAGE == "OTHER" ]  && [ $ENABLE_POS_TAGGING -eq 1 ]; then
	RAW=tmp/raw_tokenized_text_to_seg.txt # TOKENIZED_TEXT_TO_SEG is the suffix name after "raw_"
	export THREAD LANGUAGE RAW
	bash ./tools/treetagger/pos_tag.sh
	mv tmp/pos_tags.txt tmp/pos_tags_tokenized_text_to_seg.txt
fi

POS_TAGS=tmp/pos_tags_tokenized_text_to_seg.txt

### END Part-Of-Speech Tagging ###

echo ${green}===Phrasal Segmentation===${reset}

if [ $ENABLE_POS_TAGGING -eq 1 ]; then
	time ./bin/segphrase_segment \
        --pos_tag \
        --thread $THREAD \
        --model $SEGMENTATION_MODEL \
		--highlight-multi $HIGHLIGHT_MULTI \
		--highlight-single $HIGHLIGHT_SINGLE
else
	time ./bin/segphrase_segment \
        --thread $THREAD \
        --model $SEGMENTATION_MODEL \
		--highlight-multi $HIGHLIGHT_MULTI \
		--highlight-single $HIGHLIGHT_SINGLE
fi

### END Segphrasing ###

echo ${green}===Generating Output===${reset}
time java $TOKENIZER -m segmentation -i $TEXT_TO_SEG -segmented tmp/tokenized_segmented_sentences.txt -o ${MODEL}/segmentation.txt -tokenized_raw tmp/raw_tokenized_text_to_seg.txt -tokenized_id tmp/tokenized_text_to_seg.txt -c N

### END Generating Output for Checking Quality ###

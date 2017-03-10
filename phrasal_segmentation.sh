SEGMENTATION_MODEL=results/segmentation.model
TEXT_TO_SEG=data/EN/DBLP.5K.txt
HIGHLIGHT_MULTI=0.5
HIGHLIGHT_SINGLE=0.8
ENABLE_POS_TAGGING=1
THREAD=10

green=`tput setaf 2`
reset=`tput sgr0`

echo ${green}===Compilation===${reset}

if [ "$(uname)" == "Darwin" ]; then
	make all CXX=g++-6 | grep -v "Nothing to be done for"
	cp tools/treetagger/bin/tree-tagger-mac tools/treetagger/bin/tree-tagger
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        make all CXX=g++ | grep -v "Nothing to be done for"
	if [[ $(uname -r) == 2.6* ]]; then
		cp tools/treetagger/bin/tree-tagger-linux-old tools/treetagger/bin/tree-tagger
	else
		cp tools/treetagger/bin/tree-tagger-linux tools/treetagger/bin/tree-tagger
	fi
fi
if [ ! -e tools/tokenizer/build/Tokenizer.class ]; then
    mkdir -p tools/tokenizer/build/
	javac -cp ".:tools/tokenizer/lib/*" tools/tokenizer/src/Tokenizer.java -d tools/tokenizer/build/
fi

mkdir -p tmp
mkdir -p results

### END Compilation###

echo ${green}===Tokenization===${reset}

TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer"
TOKENIZED_TEXT_TO_SEG=tmp/tokenized_text_to_seg.txt
CASE=tmp/case_tokenized_text_to_seg.txt
TOKEN_MAPPING=tmp/token_mapping.txt

LANGUAGE=`cat tmp/language.txt`
echo -ne "Detected Language: $LANGUAGE\033[0K\n"

echo -ne "Current step: Tokenizing input file...\033[0K\r"
time java $TOKENIZER -m test -i $TEXT_TO_SEG -o $TOKENIZED_TEXT_TO_SEG -t $TOKEN_MAPPING -c N -thread $THREAD

### END Tokenization ###

echo ${green}===Part-Of-Speech Tagging===${reset}

if [ ! $LANGUAGE == "JA" ] && [ $ENABLE_POS_TAGGING -eq 1 ]; then
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
java $TOKENIZER -m segmentation -i $TEXT_TO_SEG -segmented tmp/tokenized_segmented_sentences.txt -o results/segmentation.txt -tokenized tmp/raw_tokenized_text_to_seg.txt

### END Generating Output for Checking Quality ###
#ifndef __PARAMETERS_H__
#define __PARAMETERS_H__

#include "../utils/utils.h"

typedef char PATTERN_LEN_TYPE;
typedef unsigned char POS_ID_TYPE;
typedef int TOTAL_TOKENS_TYPE;
typedef int PATTERN_ID_TYPE;
typedef int TOKEN_ID_TYPE;
typedef unsigned long long ULL;
typedef int INDEX_TYPE; // sentence id
typedef short int POSITION_INDEX_TYPE; // position inside a sentence

const string TRAIN_FILE = "tmp/tokenized_train.txt";
const string TRAIN_CAPITAL_FILE = "tmp/case_tokenized_train.txt";
const string STOPWORDS_FILE = "tmp/tokenized_stopwords.txt";
const string ALL_FILE = "tmp/tokenized_all.txt";
const string QUALITY_FILE = "tmp/tokenized_quality.txt";
const string POS_TAGS_FILE = "tmp/pos_tags_tokenized_train.txt";

const TOKEN_ID_TYPE BREAK = -911;

int ITERATIONS = 2;
int MIN_SUP = 30;
int MAX_LEN = 6;
int MAX_POSITIVE = 100;
int NEGATIVE_RATIO = 2;
int NTHREADS = 4;
bool ENABLE_POS_TAGGING = false;
bool ENABLE_POS_PRUNE = false;
string NO_EXPANSION_POS_FILENAME = "";
double DISCARD = 0.05;
string LABEL_FILE = "";
bool INTERMEDIATE = false;
string LABEL_METHOD = "DPDN"; // EPEN, EPDN, DPDN

string SEGMENTATION_MODEL = "";
double SEGMENT_MULTI_WORD_QUALITY_THRESHOLD = 0.5;
double SEGMENT_SINGLE_WORD_QUALITY_THRESHOLD = 0.8;
const string TEXT_TO_SEG_FILE = "tmp/tokenized_text_to_seg.txt";
const string TEXT_TO_SEG_POS_TAGS_FILE = "tmp/pos_tags_tokenized_text_to_seg.txt";


#endif

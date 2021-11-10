import sys
import codecs
from util import *
import argparse


def getOrigStopwordsPred(stopwords):
    def stopWordChecking(name):
        tokens = name.lower().split()
        if tokens[0] in stopwords:
            return False
        cnt = 0
        for token in tokens:
            if token in stopwords:
                cnt += 1
        return cnt * 3 < len(tokens)
    return stopWordChecking


def getEndStopwordsPred(stopwords):
    def stopWordChecking(name):
        tokens = name.lower().split()
        return not tokens[-1] in stopwords
    return stopWordChecking


def loadStopWords(filename):
    stopwords = set()
    for line in codecs.open(filename, 'r', 'utf-8'):
        stopwords.add(line.lower().strip())
    return stopwords


def noSeparatorPred(name):
    for ch in ',;:()':
        if name.find(ch) != -1:
            return False
    return True


def onlyAlphaPred(name):
    name = name.replace(" ", "")
    return name.isalnum() and not name.isnumeric()


def extract_entities(filename, predicates, output_filename, min_perc, min_sup, lang):

    always_valid = False
    if max(min_perc, min_sup) == -1:
        always_valid = True

    loader = get_file_loader(filename)

    candidate = set()
    for line_name, entities in loader(filename):
        valid = always_valid
        for (ent_name, support, percentage) in entities: 

            if (percentage >= min_perc) or (support >= min_sup):
                valid = True
                if(all(pred(ent_name) for pred in predicates)):
                    candidate.add(ent_name.lower())
        if valid:
            if(all(pred(line_name) for pred in predicates)):
                candidate.add(line_name.lower())

    if lang == 'zh':
        candidate = join_elements(candidate)

    print(len(candidate))
    write_file(output_filename, candidate)
    
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", type=str, help="language/dir containing files", default="EN")
    parser.add_argument("--min_sup", type=int, help="minimum support for considering entity", default=100)
    parser.add_argument("--min_perc", type=int, help="minimum percentage for considering entity", default=100)
    parser.add_argument("--stopwords_orig", action="store_true", default=False, help="whether tokens starting w/ stopwords or w/ high proportion of stopwords should be ignored")
    parser.add_argument("--stopwords_end", action="store_true", default=False, help="whether tokens ending w/ stopwords should be ignored")
    parser.add_argument("--only_alpha", action="store_true", default=False, help="whether only alphanumeric (ignoring only numeric) tokens should be extracted")
    parser.add_argument("--quality", action="store_true", default=False, help="whether quality profile should be used")
    parser.add_argument("--all", action="store_true", default=False, help="whether all profile should be used")
    
    args = parser.parse_args()

    MIN_SUP = MIN_PERC = 100
    USE_ORIG_STOPWORDS = True
    USE_END_STOPWORDS = False
    ONLY_ALPHA = False
    LANGUAGE = args.lang

    if args.quality and args.all:
        print("Impossible options")
        raise Exception
    elif args.quality:
        print("Only quality entities will be extracted")
        MIN_SUP = 100
        MIN_PERC =  100
        USE_ORIG_STOPWORDS = True
    elif args.all:
        print("All entities will be extracted")
        MIN_SUP = -1
        MIN_PERC =  -1
        USE_ORIG_STOPWORDS = False
    else:
        print("Custom entities will be extracted")
        MIN_SUP = args.min_sup
        MIN_PERC = args.min_perc
        USE_ORIG_STOPWORDS = args.stopwords_orig
        USE_END_STOPWORDS = args.stopwords_end
        ONLY_ALPHA = args.only_alpha

    print("Parameters:")
    print(f"MIN_SUP:{MIN_SUP}, MIN_PERC:{MIN_PERC}, USE_ORIG_STOPWORDS:{USE_ORIG_STOPWORDS}, USE_END_STOPWORDS:{USE_END_STOPWORDS}, ONLY_ALPHA:{ONLY_ALPHA}")
    print("\n")


    INPUT_FILENAME = LANGUAGE + '/entities'
    STOPWORDS = LANGUAGE + '/stopwords.txt'

    filename = '/wiki_custom.txt'
    if args.quality: filename = '/wiki_quality.txt'
    elif args.all: filename = '/wiki_all.txt'
    OUTPUT_FILENAME = LANGUAGE + filename

    predicates = []
    stopwords = None
    if USE_ORIG_STOPWORDS:
        if stopwords is None: stopwords = loadStopWords(STOPWORDS)
        predicates.append(getOrigStopwordsPred(stopwords))

    if USE_END_STOPWORDS:
        if stopwords is None: stopwords = loadStopWords(STOPWORDS)
        predicates.append(getEndStopwordsPred(stopwords))

    if ONLY_ALPHA:
        predicates.append(onlyAlphaPred)
    
    if args.quality:
        predicates.append(noSeparatorPred)

    extract_entities(INPUT_FILENAME, predicates, OUTPUT_FILENAME, MIN_PERC, MIN_SUP, LANGUAGE)

if __name__ == '__main__':
    main()
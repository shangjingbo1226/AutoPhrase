import sys
import codecs
from util import *

MIN_SUP = 100
MIN_PERCENT = 100
LANGUAGE = 'en'

def StopWordChecking(name, stopwords):
    tokens = name.lower().split()
    if tokens[0] in stopwords:
        return False
    cnt = 0
    for token in tokens:
        if token in stopwords:
            cnt += 1
    return cnt * 3 < len(tokens)


def LoadStopWords(filename):
    stopwords = set()
    for line in codecs.open(filename, 'r', 'utf-8'):
        stopwords.add(line.lower().strip())
    return stopwords


def NoSeparator(name):
    for ch in ',;:()':
        if name.find(ch) != -1:
            return False
    return True


def Load(filename, stopwords, output_filename):
    global MIN_PERCENT
    global MIN_SUP

    loader = get_file_loader(filename)

    candidate = set()
    for line_name, entities in loader(filename):
        valid = False
        for (ent_name, support, percentage) in entities: 

            if (percentage >= MIN_PERCENT) or (support >= MIN_SUP):
                valid = True
                if NoSeparator(ent_name) and StopWordChecking(ent_name, stopwords):
                    candidate.add(ent_name.lower())
        if valid:
            if NoSeparator(line_name) and StopWordChecking(line_name, stopwords):
                candidate.add(line_name.lower())

    if LANGUAGE == 'zh':
        candidate = join_elements(candidate)

    print(len(candidate))
    write_file(output_filename, candidate)
    
def main(argv):
    global LANGUAGE
    global MIN_PERCENT
    global MIN_SUP

    i = 0
    while i < len(argv):
        if argv[i] == '--min_sup':
            MIN_SUP = int(argv[i + 1])
            i += 1
        elif argv[i] == '--min_percentage':
            MIN_PERCENT = float(argv[i + 1])
            i += 1
        elif argv[i] == '-lang':
            LANGUAGE = argv[i + 1]
            i += 1
        else:
            print ('Unknown Parameter =', argv[i])
        i += 1

    INPUT_FILENAME = LANGUAGE + '/entities'
    STOPWORDS = LANGUAGE + '/stopwords.txt'
    OUTPUT_FILENAME = LANGUAGE + '/wiki_quality.txt'

    stopwords = LoadStopWords(STOPWORDS)

    Load(INPUT_FILENAME, stopwords, OUTPUT_FILENAME)

if __name__ == '__main__':
    main(sys.argv[1:])
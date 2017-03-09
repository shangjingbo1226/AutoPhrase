import sys
import codecs
from textblob import TextBlob
from mafan import simplify

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

    candidate = set()
    for line in codecs.open(filename, 'r', 'utf-8'):
        if line[0].isdigit():
            continue
        tokens = line.strip().split('\t')
        valid = False
        for token in tokens[2:]:
            support = int(token.split(':')[-2])
            percentage = float(token.split(':')[-1][:-1])
            if (percentage >= MIN_PERCENT) or (support >= MIN_SUP):
                name = ':'.join(token.split(':')[:-2])
                valid = True
                if NoSeparator(name) and StopWordChecking(name, stopwords):
                    candidate.add(name.lower())
        if valid:
            name = tokens[0]
            if NoSeparator(name) and StopWordChecking(name, stopwords):
                candidate.add(name.lower())
    out = codecs.open(output_filename, 'w', 'utf-8')
    if LANGUAGE == 'zh':
        seen = set()
        for name in candidate:
            name = simplify(''.join(name.split()))
            seen.add(name)
        candidate = seen
    print len(candidate)
    for name in candidate:
        out.write(name + '\n')
    out.close()
    
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
            print 'Unknown Parameter =', argv[i]
        i += 1

    INPUT_FILENAME = LANGUAGE + '/entities'
    STOPWORDS = LANGUAGE + '/stopwords.txt'
    OUTPUT_FILENAME = LANGUAGE + '/wiki_quality.txt'

    stopwords = LoadStopWords(STOPWORDS)
    Load(INPUT_FILENAME, stopwords, OUTPUT_FILENAME)

if __name__ == '__main__':
    main(sys.argv[1:])
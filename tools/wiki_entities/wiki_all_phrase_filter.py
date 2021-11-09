import sys
from mafan import simplify
from util import *

LANGUAGE = 'en'

def Load(filename, output_filename):

    loader = get_file_loader(filename)

    candidate = set()
    for line_name, entities in loader(filename):
        for (ent_name, support, percentage) in entities:
            candidate.add(ent_name.lower())

        line_name = simplify(' '.join(line_name.split()))
        candidate.add(line_name.lower())
    
    if LANGUAGE == 'zh':
        candidate = join_elements(candidate)

    print(len(candidate))
    write_file(output_filename, candidate)
    
def main(argv):
    global LANGUAGE
    i = 0
    while i < len(argv):
        if argv[i] == '-lang':
            LANGUAGE = argv[i + 1]
            i += 1
        else:
            print('Unknown Parameter =', argv[i])
        i += 1

    INPUT_FILENAME = LANGUAGE + '/entities'
    OUTPUT_FILENAME = LANGUAGE + '/wiki_all.txt'

    Load(INPUT_FILENAME, OUTPUT_FILENAME)

if __name__ == '__main__':
    main(sys.argv[1:])
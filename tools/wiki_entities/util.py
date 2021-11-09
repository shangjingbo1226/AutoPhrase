import codecs
import re
from mafan import simplify

p = re.compile('^Q[0-9]+:.*$')

def join_elements(candidate):
    seen = set()
    for name in candidate:
        name = simplify(''.join(name.split()))
        seen.add(name)
    return seen

def write_file(output_filename, phrase_list):
    out = codecs.open(output_filename, 'w', 'utf-8')
    for name in phrase_list:
        out.write(name + '\n')
    out.close()


def get_entry_version(token):
    dots_count = token.count(':')
    has_qid = (p.match(token) != None)

    if (dots_count == 4) and has_qid:
        return "new"
    elif (dots_count == 2) and not has_qid:
        return "old"
    else:
        return "undef"


def get_document_version(entities_filename):
    entries_count = {'new': 0, 'old': 0, 'undef': 0}

    MIN_ITERS = 100
    for i, line in enumerate(codecs.open(entities_filename, 'r', 'utf-8')):
        tokens = line.strip().split('\t')
        entries_count[get_entry_version(tokens[-1])] += 1

        if i >= MIN_ITERS:
            if entries_count['new'] > entries_count['old'] + entries_count['undef']:
                return "new"
            elif entries_count['old'] > entries_count['new'] + entries_count['undef']:
                return "old"

    return "undef" # probably wont happen


def get_name_new(entity):
    return ':'.join(entity.split(':')[1:-3])


def get_name_old(entity):
    return ':'.join(entity.split(':')[:-2])


def get_support(entity):
    return int(entity.split(':')[-2])


def get_perc(entity):
    return float(entity.split(':')[-1][:-1])


def iter_entries_new(entities_filename):
    for line in codecs.open(entities_filename, 'r', 'utf-8'):
        tokens = line.strip().split('\t')
        yield (tokens[0], [(get_name_new(x), get_support(x), get_perc(x)) for x in tokens[3:]])


def iter_entries_old(entities_filename):
    for line in codecs.open(entities_filename, 'r', 'utf-8'):
        tokens = line.strip().split('\t')
        yield (tokens[0], [(get_name_old(x), get_support(x), get_perc(x)) for x in tokens[2:]])


def get_file_loader(entities_filename):
    version = get_document_version(entities_filename)

    print(f"Version detected: {version}")

    if version == 'new':
        return iter_entries_new
    elif version == 'old':
        return iter_entries_old
    else:
        raise Exception
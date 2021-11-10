import codecs
import re
from mafan import simplify

NEW_VERSION_PREFIX_REGEXP = re.compile('^Q[0-9]+:.*$')

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
    has_qid = (NEW_VERSION_PREFIX_REGEXP.match(token) != None)

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


def get_stopwords_joint_pred(stopwords, use_head_token_pred, use_end_token_pred, use_token_count_pred):
    def head_token_pred(tokens):
        return not tokens[0] in stopwords

    def end_token_pred(tokens):
        return not tokens[-1] in stopwords

    def token_count_pred(tokens):
        cnt = 0
        for token in tokens:
            if token in stopwords:
                cnt += 1
        return cnt * 3 < len(tokens)

    predicates = []
    if use_head_token_pred: predicates.append(head_token_pred)
    if use_end_token_pred: predicates.append(end_token_pred)
    if use_token_count_pred: predicates.append(token_count_pred)

    def joint_predicate(name):
        tokens = name.lower().split()
        return all(x(tokens) for x in predicates)

    return joint_predicate


def load_stopwords(filename):
    stopwords = set()
    for line in codecs.open(filename, 'r', 'utf-8'):
        stopwords.add(line.lower().strip())
    return stopwords


def no_separator_pred(name):
    for ch in ',;:()':
        if name.find(ch) != -1:
            return False
    return True


def only_alpha_pred(name):
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
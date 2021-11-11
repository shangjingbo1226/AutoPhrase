import os
from util import *
import argparse
  

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", type=str, help="language/dir containing files", default="EN")
    parser.add_argument("--min_sup", type=int, help="minimum support for considering entity", default=100)
    parser.add_argument("--min_perc", type=int, help="minimum percentage for considering entity", default=100)
    parser.add_argument("--skip_head_token_stopword", action="store_true", default=False, help="whether entities starting w/ stopwords should be ignored")
    parser.add_argument("--skip_end_token_stopword", action="store_true", default=False, help="whether entities ending w/ stopwords should be ignored")
    parser.add_argument("--skip_high_prop_stopword", action="store_true", default=False, help="whether entities w/ high proportion of stopwords should be ignored")
    parser.add_argument("--no_sep", action="store_true", default=False, help="whether entities w/ sep chars should be ignored")
    parser.add_argument("--only_alpha", action="store_true", default=False, help="whether only alphanumeric (skipping only numeric) entities should be extracted")
    args = parser.parse_args()

    input_filename = os.path.join(args.lang, 'entities')
    output_filename = os.path.join(args.lang, 'wiki_custom.txt')
    predicates = []

    # Stopwords predicates
    stopwords = load_stopwords(os.path.join(args.lang, 'stopwords.txt'))
    stopwords_flags = [
        args.skip_head_token_stopword, 
        args.skip_end_token_stopword, 
        args.skip_high_prop_stopword
    ]
    if any(stopwords_flags):
        predicates.append(get_stopwords_joint_pred(stopwords, *stopwords_flags))

    if args.only_alpha:
        predicates.append(only_alpha_pred)
    
    if args.no_sep:
        predicates.append(no_separator_pred)

    extract_entities(input_filename, predicates, output_filename, args.min_perc, args.min_sup, args.lang)

if __name__ == '__main__':
    main()
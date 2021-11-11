import os
from util import *
import argparse

    
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", type=str, help="language/dir containing files", default="EN")
    parser.add_argument("--mode", type=str, help="`quality` or `all` mode", required=True)
    args = parser.parse_args()

    input_filename = os.path.join(args.lang, 'entities')

    if args.mode == "quality":
        print("Only quality entities will be extracted")

        stopwords = load_stopwords(os.path.join(args.lang, 'stopwords.txt'))
        predicates = [
            no_separator_pred,
            get_stopwords_joint_pred(stopwords, use_head_token_pred=True, use_end_token_pred=False, use_token_count_pred=True)
        ]

        extract_entities(input_filename, predicates, os.path.join(args.lang, 'wiki_quality.txt'), 100, 100, args.lang)
    elif args.mode == "all":
        print("All entities will be extracted")
        extract_entities(input_filename, [], os.path.join(args.lang, 'wiki_all.txt'), -1, -1, args.lang)
    else:
        print("Uknown mode")
        raise Exception


if __name__ == '__main__':
    main()
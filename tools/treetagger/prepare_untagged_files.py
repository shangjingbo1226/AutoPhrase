# -*- coding: utf-8 -*-

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-token", help="path for tokenized data")
parser.add_argument("-files", help="number of output files")
parser.add_argument("-pattern", help="output file name pattern")
args = parser.parse_args()

count = 0
with open(args.token, 'r') as input:
    for line in input:
        count += len(line.strip().split(' '))

file_size = count / int(args.files)

content_to_write = []
with open(args.token, 'r') as input:
    new_file = open(args.pattern + format(1, '05'), 'w')
    open_new_file = False
    file_count = 1
    token_count = 0
    for line in input:
        tokens_in_lines = line.strip().split(' ')
        if len(tokens_in_lines) == 0:
            continue
        if open_new_file:
            new_file.write('\n'.join(content_to_write))
            new_file.close()
            del content_to_write
            content_to_write = []
            file_count += 1
            new_file = open(args.pattern + format(file_count, '05'), 'w')
            open_new_file = False
        content_to_write.extend(tokens_in_lines)
        token_count += len(tokens_in_lines)
        if token_count / file_size >= file_count:
            open_new_file = True
new_file.write('\n'.join(content_to_write))
new_file.close()
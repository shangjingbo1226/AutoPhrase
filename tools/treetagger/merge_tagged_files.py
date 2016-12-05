# -*- coding: utf-8 -*-

import argparse
import glob
import re

parser = argparse.ArgumentParser()
parser.add_argument("-token", help="path for tokenized data")
parser.add_argument("-tagged_files", help="input tagged files")
parser.add_argument("-output", help="output merged file")
args = parser.parse_args()

files = glob.glob(args.tagged_files)

def num_key(s):
    return int(re.search(r'\d+', s).group())

files.sort(key=num_key)

file_index = 0
tagged_file = open(files[file_index], 'r')

output = open(args.output, 'w')

with open(args.token, 'r') as token_file:
    for line in token_file:
        content_to_output = []
        # number of tokens
        count = line.count(' ') + 1
        if count == 0:
            continue
        line = tagged_file.readline()
        if not line:
            tagged_file.close()
            file_index += 1
            tagged_file = open(files[file_index], 'r')
            line = tagged_file.readline()
        content_to_output.append(line[:-1])
        count -= 1
        while count > 0:
            line = tagged_file.readline()
            content_to_output.append(line[:-1])
            count -= 1
        output.write(' '.join(content_to_output))
        output.write('\n')

tagged_file.close()
output.close()
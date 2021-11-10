# How to get wiki_quality.txt and wiki_all.txt for other languages?

Suppose the language is **X**.

1. Find **X**'s Wikipedia dumps and run [WikipediaEntities](https://github.com/kno10/WikipediaEntities). It will generate a file named "entities". Put it in "**X**/entities". 

2. Put a stop word list of **X** at the "**X**/stopwords.txt".

3. Install some depended python packages.
```
pip install mafan
pip install textblob
```

4. Run the script. This script contain some simple rules designed for English, Spanish, and Chinese. You may want to modify them to fit the new language **X**. You will find "**X**/wiki_quality.txt" and "**X**/wiki_all.txt".
```
python extract_entities.py --lang X --quality
python extract_entities.py --lang X --all
```

4.1. If neither `--quality` nor `--all` intend to be used, the script also supports custom arguments:
```
python extract_entities.py -h

usage: extract_entities.py [-h] [--lang LANG] [--min_sup MIN_SUP] [--min_perc MIN_PERC] [--stopwords_orig] [--stopwords_end] [--only_alpha] [--quality] [--all]

optional arguments:
  -h, --help           show this help message and exit
  --lang LANG          language/dir containing files
  --min_sup MIN_SUP    minimum support for considering entity
  --min_perc MIN_PERC  minimum percentage for considering entity
  --stopwords_orig     whether tokens starting w/ stopwords or w/ high proportion of stopwords should be ignored
  --stopwords_end      whether tokens ending w/ stopwords should be ignored
  --only_alpha         whether only alphanumeric (ignoring only numeric) tokens should be extracted
  --quality            whether quality profile should be used
  --all                whether all profile should be used

```

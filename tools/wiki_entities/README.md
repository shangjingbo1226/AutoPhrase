# How to get wiki_quality.txt and wiki_all.txt for other languages?

Suppose the language is **X**.

1. Find **X**'s Wikipedia dumps and run [WikipediaEntities](https://github.com/kno10/WikipediaEntities). It will generate a file named "entities". Put it in "**X**/entities". 

2. Put a stop word list of **X** at the "**X**/stopwords.txt".

3. Install some depended python packages.
```
pip install mafan
pip install textblob
```

4. Run the `extract_entities.py`script for extracting entities to `wiki_all.txt` or `wiki_quality.txt` files. This script contains some simple rules designed for English, Spanish, and Chinese. You may want to modify them to fit the new language **X**. You will find "**X**/wiki_quality.txt" and "**X**/wiki_all.txt" after running the script
```
usage: extract_entities.py [-h] [--lang LANG] --mode MODE

optional arguments:
  -h, --help   show this help message and exit
  --lang LANG  language/dir containing files
  --mode MODE  `quality` or `all` mode
```

4.1. If neither `quality` nor `all` modes intend to be used, you can run the `custom_extract_entities.py` and choose the desired parameters for extraction.
```
usage: custom_extract_entities.py [-h] [--lang LANG] [--min_sup MIN_SUP] [--min_perc MIN_PERC] [--skip_head_token_stopword]
                                  [--skip_end_token_stopword] [--skip_high_prop_stopword] [--no_sep] [--only_alpha]

optional arguments:
  -h, --help                  show this help message and exit
  --lang LANG                 language/dir containing files
  --min_sup MIN_SUP           minimum support for considering entity
  --min_perc MIN_PERC         minimum percentage for considering entity
  --skip_head_token_stopword  whether entities starting w/ stopwords should be ignored
  --skip_end_token_stopword   whether entities ending w/ stopwords should be ignored
  --skip_high_prop_stopword   whether entities w/ high proportion of stopwords should be ignored
  --no_sep                    whether entities w/ sep chars should be ignored
  --only_alpha                whether only alphanumeric (skipping only numeric) entities should be extracted
```

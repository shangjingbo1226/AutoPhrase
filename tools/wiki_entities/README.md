# How to get wiki_quality.txt and wiki_all.txt for other languages?

Suppose the language is **X**.

1. Find **X**'s Wikipedia dumps and run [WikipediaEntities](https://github.com/kno10/WikipediaEntities). It will generate a file named "entities". Put it in "**X**/entities". 

2. Put a stop word list of **X** at the "**X**/stopwords".

3. Install some depended python packages.
```
pip install mafan
pip install textblob
```

4. Run the following two scripts. These two scripts contain some simple rules designed for English, Spanish, and Chinese. You may want to modify them to fit the new language **X**. You will find "**X**/wiki_quality.txt" and "**X**/wiki_all.txt".
```
python wiki_all_phrase_filter.py -lang X
python high_quality_phrase_filter.py -lang X
```

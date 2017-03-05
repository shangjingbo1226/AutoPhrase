# AutoPhrase: Automated Phrase Mining from Massive Text Corpora

## Publications

Please cite the following two papers if you are using our tools. Thanks!

*   Jingbo Shang, Jialu Liu, Meng Jiang, Xiang Ren, Clare R Voss, Jiawei Han, "**Automated Phrase Mining from Massive Text Corpora**", submitted to SIGKDD 2017, under review. [arXiv:1702.04457](https://arxiv.org/abs/1702.04457) [cs.CL]

*   Jialu Liu\*, Jingbo Shang\*, Chi Wang, Xiang Ren and Jiawei Han, "**[Mining
    Quality Phrases from Massive Text
    Corpora](http://jialu.cs.illinois.edu/paper/sigmod2015-liu.pdf)**”, Proc. of
    2015 ACM SIGMOD Int. Conf. on Management of Data (SIGMOD'15), Melbourne,
    Australia, May 2015. (\* equally contributed,
    [slides](http://jialu.cs.illinois.edu/paper/sigmod2015-liu-slides.pdf))

## New Features
(compared to SegPhrase)

*   **Minimized Human Effort**. We develop a robust positive-only distant training method to estimate the phrase quality by leveraging exsiting general knowledge bases.
*   **Support Multiple Languages: English, Spanish, and Chinese**. The language
    in the input will be automatically detected.
*   **High Accuracy**. We propose a POS-guided phrasal segmentation model incorporating POS tags when POS tagger is available. Meanwhile, the new framework is able to extract single-word quality phrases.
*   **High Efficiency**. A better indexing and an almost lock-free parallelization are implemented, which lead to both running time speedup and memory saving.

## Related GitHub Repositories

*   [SegPhrase](https://github.com/shangjingbo1226/SegPhrase)
*	[SegPhrase-MultiLingual](https://github.com/remenberl/SegPhrase-MultiLingual)

## Requirements

Linux or MacOS with g++ and Java installed.

Ubuntu:

*   g++ 4.8 `$ sudo apt-get install g++-4.8`
*   Java 8 `$ sudo apt-get install openjdk-8-jre`

MacOS:

*   g++ 6 `$ brew install gcc6`
*   Java 8 `$ brew update; brew tap caskroom/cask; brew install Caskroom/cask/java`

## Default Run

```
$ ./auto_phrase.sh
```

The default run will download an English corpus from the server of our data
mining group and run AutoPhrase to get 3 ranked lists of phrases under the
results/ folder 
* results/AutoPhrase.txt: the unified ranked list for both single-word phrases and multi-word phrases. 
* results/AutoPhrase_multi-words.txt: the sub-ranked list for multi-word phrases only. 
* results/AutoPhrase_single-word.txt: the sub-ranked list for single-word phrases only.

## Incorporate Domain-Specific Knowledge Bases

If domain-specific knowledge bases are available, such as MeSH terms, there are two ways to incorporate them.
* (**recommended**) Append your known quality phrases to the file "data/EN/wiki_quality.txt".
* Replace the file "data/EN/wiki_quality.txt" by your known quality phrases.

## Handle Other Languages

We provide a default tokenizer together with a dummy POS tagger in the tools/tokenizer.
It uses the StandardTokenizer in Lucene, and always assign a tag UNKNOWN to each token.
To enable this feature, please add the "-l OTHER" to the TOKENIZER command in the bash script auto_phrase.sh.
```
TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer -l OTHER"
```
If you want to incorporate your own tokenizer and/or POS tagger, please create a new class extending SpecialTagger in the tools/tokenizer. You may refer to StandardTagger as an example.

Meanwhile, you have to add two lists of quality phrases in the data/OTHER/wiki_quality.txt and data/OTHER/wiki_all.txt. 
The quality of phrases in wiki_quality should be very confident, while wiki_all, as its superset, could be a little noisy.

## Docker

###Default Run

```
sudo docker run -v $PWD/results:/autophrase/results -it \
    -e FIRST_RUN=1 -e ENABLE_POS_TAGGING=1 \
    -e MIN_SUP=30 -e THREAD=10 \
    remenberl/autophrase

./autophrase.sh
```

The results will be available in the results folder.

###User Specified Input
Assuming the path to input file is ./data/input.txt.
```
sudo docker run -v $PWD/data:/autophrase/data -v $PWD/results:/autophrase/results -it \
    -e RAW_TRAIN=data/input.txt \
    -e FIRST_RUN=1 -e ENABLE_POS_TAGGING=1 \
    -e MIN_SUP=30 -e THREAD=10 \
    remenberl/autophrase

./autophrase.sh
```

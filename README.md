# AutoPhrase: A Unified Framework for Automated Quality Phrase Mining from Massive Text Corpora

## Publications

Please cite the following two papers if you are using our tools. Thanks!

* Jingbo Shang, Jialu Liu, Meng Jiang, Xiang Ren, Jiawei Han, "**AutoPhrase: A Unified Framework for Automated Quality Phrase Mining from Massive Text Corpora**", VLDB 2017, under review.

* Jialu Liu\*, Jingbo Shang\*, Chi Wang, Xiang Ren and Jiawei Han, "**[Mining Quality Phrases from Massive Text Corpora](http://jialu.cs.illinois.edu/paper/sigmod2015-liu.pdf)**”, Proc. of 2015 ACM SIGMOD Int. Conf. on Management of Data (SIGMOD'15), Melbourne, Australia, May 2015. (\* equally contributed, [slides](http://jialu.cs.illinois.edu/paper/sigmod2015-liu-slides.pdf))

## New Features

* No Human Effort. We are using the distant training based on the quality phrases in knowledge bases to generate labels.
* Support Multiple Languages: English, Spanish, and Chinese. The language in the input will be automatically detected.
* High Accuracy. Precision and recall are improved over our previous work SegPhrase, because context-aware phrasal segmentation considering POS tags has been developed and single-word phrases are modeled systematiaclly. 
* High Efficiency. A better indexing and an almost lock-free parallelization are implemented, which lead to both running time speedup and memory saving.

## Related GitHub Repository

* [SegPhrase](https://github.com/shangjingbo1226/SegPhrase)

## Requirements

We will take Ubuntu for example.

* g++ 4.8
```
$ sudo apt-get install g++-4.8
```
* Java 8
```
$ sudo apt-get install openjdk-8-jdk
$ sudo apt-get install openjdk-8-jre
```

## Build

The C++ part is encoded in the Makefile while the Java part is done in the bash script.

## Default Run

```
$ ./auto_phrase 
```

The default run will download an English corpus from the server of our data mining group and run AutoPhrase to get 3 ranked lists of phrases under the results/ folder
* results/AutoPhrase.txt: the unified ranked list for both single-word phrases and multi-word phrases.
* results/AutoPhrase_multi-words.txt: the sub-ranked list for multi-word phrases only.
* results/AutoPhrase_single-word.txt: the sub-ranked list for single-word phrases only.

## Parameters

```
RAW_TRAIN=data/DBLP.txt
```
RAW_TRAIN is the input of AutoPhrase, where each line is a single document.

```
FIRST_RUN=1
```
When FIRST_RUN is set to 1, AutoPhrase will run all preprocessing. Otherwise, AutoPhrase directly starts from the current preprocessed data in the tmp/ folder.

```
ENABLE_POS_TAGGING=1
```
When ENABLE_POS_TAGGING is set to 1, AutoPhrase will utilize the POS tagging in the phrase mining. Otherwise, a simple length penalty mode as the same as SegPhrase will be used.

```
MIN_SUP=30
```
A hard threshold of raw frequency is specified for frequent phrase mining, which will generate a candidate set.

```
THREAD=10
```
You can also specify how many threads can be used for SegPhrase

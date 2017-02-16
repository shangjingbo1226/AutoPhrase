# AutoPhrase: A Unified Framework for Automated Quality Phrase Mining from Massive Text Corpora

## Publications

Please cite the following two papers if you are using our tools. Thanks!

*   Jingbo Shang, Jialu Liu, Meng Jiang, Xiang Ren, Jiawei Han, "**AutoPhrase: A
    Framework for Automated Quality Phrase Mining from Massive Text
    Corpora**", submitted to SIGKDD 2017, under review. [arXiv:1702.04457](https://128.84.21.199/abs/1702.04457) [cs.CL]

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
$ ./auto_phrase
```

The default run will download an English corpus from the server of our data
mining group and run AutoPhrase to get 3 ranked lists of phrases under the
results/ folder * results/AutoPhrase.txt: the unified ranked list for both
single-word phrases and multi-word phrases. *
results/AutoPhrase_multi-words.txt: the sub-ranked list for multi-word phrases
only. * results/AutoPhrase_single-word.txt: the sub-ranked list for single-word
phrases only.

## Parameters

```
RAW_TRAIN=data/DBLP.txt
```

RAW_TRAIN is the input of AutoPhrase, where each line is a single document.

```
FIRST_RUN=1
```

When FIRST_RUN is set to 1, AutoPhrase will run all preprocessing. Otherwise,
AutoPhrase directly starts from the current preprocessed data in the tmp/
folder.

```
ENABLE_POS_TAGGING=1
```

When ENABLE_POS_TAGGING is set to 1, AutoPhrase will utilize the POS tagging in
the phrase mining. Otherwise, a simple length penalty mode as the same as
SegPhrase will be used.

```
MIN_SUP=30
```

A hard threshold of raw frequency is specified for frequent phrase mining, which
will generate a candidate set.

```
THREAD=10
```

You can also specify how many threads can be used for AutoPhrase

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

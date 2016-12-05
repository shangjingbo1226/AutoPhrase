#ifndef __DUMP_H__
#define __DUMP_H__

#include "../utils/parameters.h"
#include "../utils/commandline_flags.h"
#include "../utils/utils.h"
#include "../frequent_pattern_mining/frequent_pattern_mining.h"
#include "../data/documents.h"
#include "../classification/feature_extraction.h"
#include "../classification/label_generation.h"
#include "../classification/predict_quality.h"
#include "../model_training/segmentation.h"

namespace Dump
{

using FrequentPatternMining::Pattern;
using FrequentPatternMining::patterns;
using FrequentPatternMining::pattern2id;

void loadSegmentationModel(const string& filename)
{
    FILE* in = tryOpen(filename, "rb");
    bool flag;
    Binary::read(in, flag);
    myAssert(ENABLE_POS_TAGGING == flag, "Model and configuration mismatch! whether ENABLE_POS_TAGGING?");
    Binary::read(in, Segmentation::penalty);

    cerr << flag << " " << Segmentation::penalty << endl;

    // quality phrases & unigrams
    size_t cnt = 0;
    Binary::read(in, cnt);
    patterns.resize(cnt);
    cerr << "# of patterns to load = " << cnt << endl;
    for (int i = 0; i < cnt; ++ i) {
        patterns[i].load(in);
    }
    cerr << "pattern loaded" << endl;

    // POS Tag mapping
    Binary::read(in, cnt);
    Documents::posTag.resize(cnt);
    for (int i = 0; i < Documents::posTag.size(); ++ i) {
        Binary::read(in, Documents::posTag[i]);
        Documents::posTag2id[Documents::posTag[i]] = i;
    }
    cerr << "pos tags loaded" << endl;

    // POS Tag Transition
    Binary::read(in, cnt);
    Segmentation::connect.resize(cnt);
    for (int i = 0; i < Segmentation::connect.size(); ++ i) {
        Segmentation::connect[i].resize(cnt);
        for (int j = 0; j < Segmentation::connect[i].size(); ++ j) {
            Binary::read(in, Segmentation::connect[i][j]);
        }
    }
    cerr << "POS tag transition loaded" << endl;

    fclose(in);
}

void dumpSegmentationModel(const string& filename)
{
    FILE* out = tryOpen(filename, "wb");
    Binary::write(out, ENABLE_POS_TAGGING);
    Binary::write(out, Segmentation::penalty);

    // quality phrases & unigrams
    size_t cnt = 0;
    for (int i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() > 1 && patterns[i].currentFreq > 0 || patterns[i].size() == 1 && patterns[i].currentFreq > 0 && unigrams[patterns[i].tokens[0]] >= MIN_SUP) {
            ++ cnt;
        }
    }
    Binary::write(out, cnt);
    cerr << "# of patterns dumped = " << cnt << endl;
    for (int i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() > 1 && patterns[i].currentFreq > 0 || patterns[i].size() == 1 && patterns[i].currentFreq > 0 && unigrams[patterns[i].tokens[0]] >= MIN_SUP) {
            patterns[i].dump(out);
        }
    }

    // POS Tag mapping
    Binary::write(out, Documents::posTag.size());
    for (int i = 0; i < Documents::posTag.size(); ++ i) {
        Binary::write(out, Documents::posTag[i]);
    }

    // POS Tag Transition
    Binary::write(out, Segmentation::connect.size());
    for (int i = 0; i < Segmentation::connect.size(); ++ i) {
        for (int j = 0; j < Segmentation::connect[i].size(); ++ j) {
            Binary::write(out, Segmentation::connect[i][j]);
        }
    }

    fclose(out);
}

void dumpPOSTransition(const string& filename)
{
    FILE* out = tryOpen(filename, "w");
    for (int i = 0; i < Documents::posTag.size(); ++ i) {
        fprintf(out, "\t%s", Documents::posTag[i].c_str());
    }
    fprintf(out, "\n");
    for (int i = 0; i < Documents::posTag.size(); ++ i) {
        fprintf(out, "%s", Documents::posTag[i].c_str());
        for (int j = 0; j < Documents::posTag.size(); ++ j) {
            fprintf(out, "\t%.10f", Segmentation::connect[i][j]);
        }
        fprintf(out, "\n");
    }
    fclose(out);
}

void dumpFeatures(const string& filename, const vector<vector<double>>& features, const vector<Pattern>& truth)
{
    FILE* out = tryOpen(filename, "w");
    for (Pattern pattern : truth) {
        int i = FrequentPatternMining::pattern2id[pattern.hashValue];
        if (features[i].size() > 0) {
            for (int j = 0; j < features[i].size(); ++ j) {
                fprintf(out, "%.10f%c", features[i][j], j + 1 == features[i].size() ? '\n' : '\t');
            }
        }
    }
    fclose(out);
}

void dumpLabels(const string& filename, const vector<Pattern>& truth)
{
    FILE* out = tryOpen(filename, "w");
    for (Pattern pattern : truth) {
        for (int j = 0; j < pattern.tokens.size(); ++ j) {
            fprintf(out, "%d%c", pattern.tokens[j], j + 1 == pattern.tokens.size() ? '\n' : ' ');
        }
    }
    fclose(out);
}

template<class T>
void dumpRankingList(const string& filename, vector<pair<T, int>> &order)
{
    FILE* out = tryOpen(filename, "w");
    sort(order.rbegin(), order.rend());
    for (int iter = 0; iter < order.size(); ++ iter) {
        int i = order[iter].second;
        fprintf(out, "%.10f\t", patterns[i].quality);
        for (int j = 0; j < patterns[i].tokens.size(); ++ j) {
            fprintf(out, "%d%c", patterns[i].tokens[j], j + 1 == patterns[i].tokens.size() ? '\n' : ' ');
        }
    }
    fclose(out);
}

void dumpResults(const string& prefix)
{
    vector<pair<double, int>> order;
    for (int i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() > 1 && patterns[i].currentFreq > 0) {
            order.push_back(make_pair(patterns[i].quality, i));
        }
    }
    dumpRankingList(prefix + "_multi-words.txt", order);

    order.clear();
    for (int i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() == 1 && patterns[i].currentFreq > 0 && unigrams[patterns[i].tokens[0]] >= MIN_SUP) {
            order.push_back(make_pair(patterns[i].quality, i));
        }
    }
    dumpRankingList(prefix + "_unigrams.txt", order);

    order.clear();
    for (int i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() > 1 && patterns[i].currentFreq > 0 || patterns[i].size() == 1 && patterns[i].currentFreq > 0 && unigrams[patterns[i].tokens[0]] >= MIN_SUP) {
            order.push_back(make_pair(patterns[i].quality, i));
        }
    }
    dumpRankingList(prefix + "_salient.txt", order);
}

};

#endif

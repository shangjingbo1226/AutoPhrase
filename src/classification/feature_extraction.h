#ifndef __FEATURE_EXTRACTION_H__
#define __FEATURE_EXTRACTION_H__

#include "../utils/utils.h"
#include "../frequent_pattern_mining/frequent_pattern_mining.h"
#include "../data/documents.h"
#include "../model_training/segmentation.h"

using FrequentPatternMining::Pattern;

// === global variables ===
using Documents::totalWordTokens;
using Documents::wordTokens;

using FrequentPatternMining::patterns;
using FrequentPatternMining::pattern2id;
using FrequentPatternMining::id2ends;
using FrequentPatternMining::unigrams;
// ===

namespace Features
{
// ===
    inline TOTAL_TOKENS_TYPE getFrequency(const Pattern &pattern) {
        if (pattern2id.count(pattern.hashValue)) {
            return patterns[pattern2id[pattern.hashValue]].currentFreq;
        }
        return 0;
    }

    void extractCompleteness(Pattern &pattern, vector<double> &feature) {
        if (pattern.currentFreq == 0) {
            feature.push_back(0);
            feature.push_back(0);
            return;
        }
        const vector<TOTAL_TOKENS_TYPE> &tokens = pattern.tokens;
        vector<unordered_set<TOTAL_TOKENS_TYPE>> distinct(tokens.size());
        PATTERN_ID_TYPE id = pattern2id[pattern.hashValue];
        double freq = patterns[id].currentFreq;
        double superFreq = 0, subFreq = freq;

        Pattern subLeft, subRight;
        for (int i = 0; i < pattern.size(); ++ i) {
            if (i) {
                subRight.append(tokens[i]);
            }
            if (i + 1 < pattern.size()) {
                subLeft.append(tokens[i]);
            }
        }
        subFreq = max(subFreq, (double)getFrequency(subLeft));
        subFreq = max(subFreq, (double)getFrequency(subRight));
        feature.push_back(freq / subFreq);

        for (const TOTAL_TOKENS_TYPE &ed : id2ends[id]) {
            TOTAL_TOKENS_TYPE st = ed - tokens.size();
            if (st > 0 && !Documents::isEndOfSentence(st - 1)) {
                Pattern left;
                for (TOTAL_TOKENS_TYPE i = st - 1; i <= ed; ++ i) {
                    left.append(wordTokens[i]);
                }
                superFreq = max(superFreq, (double)getFrequency(left));
            }
            if (!Documents::isEndOfSentence(ed) && ed + 1 < totalWordTokens) {
                Pattern right = pattern;
                right.append(wordTokens[ed + 1]);
                superFreq = max(superFreq, (double)getFrequency(right));
            }
        }
        feature.push_back(superFreq / freq);
    }

    // ready for parallel
    void extractStopwords(const Pattern &pattern, vector<double> &feature) {
        if (Documents::stopwords.count(pattern.tokens[0]) != 0 || Documents::isDigital[pattern.tokens[0]]) {
            feature.push_back(1);
        } else {
            feature.push_back(0);
        }
        if (Documents::stopwords.count(pattern.tokens.back()) != 0) { // || Documents::isDigital[pattern.tokens.back()]);)
            feature.push_back(1);
        } else {
            feature.push_back(0);
        }
        double stop = 0, sumIdf = 0;
        int cnt = 0;
        FOR (token, pattern.tokens) {
            if (Documents::stopwords.count(*token) != 0 || Documents::isDigital[*token]) {
                stop += 1;
            }
            sumIdf += Documents::idf[*token];
            ++ cnt;
        }
        feature.push_back(stop / pattern.tokens.size());
        feature.push_back(sumIdf / cnt);
    }

    // ready for parallel
    void extractPunctuation(PATTERN_ID_TYPE id, vector<double> &feature) {
        if (id2ends[id].size() == 0) {
            feature.push_back(0);
            feature.push_back(0);
            feature.push_back(0);
            feature.push_back(0);
            return;
        }
        TOTAL_TOKENS_TYPE dash = 0, quote = 0, parenthesis = 0, allCap = 0, allCAP = 0;
        for (const TOTAL_TOKENS_TYPE& ed : id2ends[id]) {
            TOTAL_TOKENS_TYPE st = ed - patterns[id].size() + 1;
            assert(Documents::wordTokens[st] == patterns[id].tokens[0]);

            bool hasDash = false;
            for (TOTAL_TOKENS_TYPE j = st; j < ed && !hasDash; ++ j) {
                hasDash |= Documents::hasDashAfter(j);
            }
            dash += hasDash;

            bool isAllCap = true, isAllCAP = true;
            for (TOTAL_TOKENS_TYPE j = st; j <= ed; ++ j) {
                isAllCap &= Documents::isFirstCapital(j);
                isAllCAP &= Documents::isAllCapital(j);
            }
            allCap += isAllCap;
            allCAP += isAllCAP;
            if (Documents::hasQuoteBefore(st) && Documents::hasQuoteAfter(ed)) {
                ++ quote;
            }
            if (Documents::hasParentThesisBefore(st) && Documents::hasParentThesisAfter(ed)) {
                ++ parenthesis;
            }
        }
        feature.push_back((double)quote / id2ends[id].size());
        feature.push_back((double)dash / id2ends[id].size());
        feature.push_back((double)parenthesis / id2ends[id].size());
        feature.push_back((double)allCap / id2ends[id].size());
        // feature.push_back((double)allCAP / id2ends[id].size()); // not used in SegPhrase
    }

    // ready for parallel
    void extractStatistical(PATTERN_ID_TYPE id, vector<double> &feature) {
        const Pattern &pattern = patterns[id];
        if (pattern.currentFreq == 0) {
            feature.push_back(0);
            feature.push_back(0);
            feature.push_back(0);
            feature.push_back(0);
            return;
        }
        PATTERN_ID_TYPE AB = 0, CD = 0;
        double best = -1;
        for (int i = 0; i + 1 < pattern.size(); ++ i) {
            Pattern left = pattern.substr(0, i + 1);
            Pattern right = pattern.substr(i + 1, pattern.size());

            if (!pattern2id.count(right.hashValue)) {
                cerr << i << " " << pattern.size() << endl;
                left.show();
                right.show();
            }
            assert(pattern2id.count(left.hashValue));
            assert(pattern2id.count(right.hashValue));

            PATTERN_ID_TYPE leftID = pattern2id[left.hashValue], rightID = pattern2id[right.hashValue];

            double current = patterns[leftID].probability * patterns[rightID].probability;
            if (current > best) {
                best = current;
                AB = leftID;
                CD = rightID;
            }
        }

        // prob_feature
        double f1 = pattern.probability / patterns[AB].probability / patterns[CD].probability;
        // occur_feature
        double f2 = patterns[id].currentFreq / sqrt(patterns[AB].currentFreq + EPS) / sqrt(patterns[CD].currentFreq + EPS);
        // log_occur_feature
        double f3 = sqrt(patterns[id].currentFreq) * log(f1);
        // prob_log_occur
        double f4 = patterns[id].currentFreq * log(f1);
        feature.push_back(f1);
        feature.push_back(f2);
        // feature.push_back(f3); // f3 is ignored in SegPhrase
        feature.push_back(f4);

        const vector<TOKEN_ID_TYPE> &tokens = pattern.tokens;
        unordered_map<TOKEN_ID_TYPE, int> local, context;
        for (int j = 0; j < tokens.size(); ++ j) {
            ++ local[tokens[j]];
        }
        vector<double> outside(pattern.size(), 0);
        double total = 0.0;
        for (TOTAL_TOKENS_TYPE ed : id2ends[id]) {
            TOTAL_TOKENS_TYPE st = ed - patterns[id].size() + 1;
            assert(Documents::wordTokens[st] == patterns[id].tokens[0]);

            for (TOTAL_TOKENS_TYPE sentences = 0; st >= 0 && sentences < 2; -- st) {
                if (Documents::isEndOfSentence(st - 1)) {
                    ++ sentences;
                }
            }
            for (TOTAL_TOKENS_TYPE sentences = 0; ed < Documents::totalWordTokens && sentences < 2; ++ ed) {
                if (Documents::isEndOfSentence(ed)) {
                    ++ sentences;
                }
            }

            assert(Documents::isEndOfSentence(st) && Documents::isEndOfSentence(ed - 1));

            unordered_map<TOKEN_ID_TYPE, int> context;
            for (TOTAL_TOKENS_TYPE j = st + 1; j < ed; ++ j) {
                ++ context[Documents::wordTokens[j]];
            }

            total += 1;
            for (size_t j = 0; j < tokens.size(); ++ j) {
                TOKEN_ID_TYPE diff = context[tokens[j]] - local[tokens[j]];
                assert(diff >= 0);
                outside[j] += diff;
            }
        }
        double sum = 0, norm = 0;
        for (size_t i = 0; i < tokens.size(); ++ i) {
            sum += outside[i] * Documents::idf[tokens[i]];
            norm += Documents::idf[tokens[i]];
        }
        if (total > 0) {
            sum /= total;
        }
        double outsideFeat = sum / norm;
        feature.push_back(outsideFeat);
    }

    PATTERN_ID_TYPE recognize(vector<Pattern> &truth) {
        if (INTERMEDIATE) {
            fprintf(stderr, "Loaded Truth = %d\n", truth.size());
        }
        PATTERN_ID_TYPE truthCnt = 0;
        for (PATTERN_ID_TYPE i = 0; i < truth.size(); ++ i) {
            if (pattern2id.count(truth[i].hashValue)) {
                ++ truthCnt;
                PATTERN_ID_TYPE id = pattern2id[truth[i].hashValue];
                patterns[id].label = truth[i].label;
            }
        }
        if (INTERMEDIATE) {
            fprintf(stderr, "Recognized Truth = %d\n", truthCnt);
        }
        return truthCnt;
    }

    vector<vector<double>> extract(vector<string> &featureNames) {
        // prepare token counts
        const TOTAL_TOKENS_TYPE& corpusTokensN = Documents::totalWordTokens;
        for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
            patterns[i].probability = (patterns[i].currentFreq + EPS) / (corpusTokensN / (double)patterns[i].size());
        }

        featureNames = {"stat_f1", "stat_f2", "stat_f4", "stat_outside",
                        "punc_quote", "punc_dash", "punc_parenthesis", "first_capitalized",
                        // "all_capitalized",
                        "stopwords_1st", "stopwords_last", "stopwords_ratio", "avg_idf",
                        "complete_sub", "complete_super",
                        };

        // compute features for each pattern
        vector<vector<double>> features(patterns.size(), vector<double>());
        # pragma omp parallel for schedule(dynamic, PATTERN_CHUNK_SIZE)
        for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
            if (patterns[i].size() > 1) {
                extractStatistical(i, features[i]);
                extractPunctuation(i, features[i]);
                extractStopwords(patterns[i], features[i]);
                extractCompleteness(patterns[i], features[i]);
                features[i].shrink_to_fit();
            }
        }
        features.shrink_to_fit();
        return features;
    }

    // ready for parallel
    void extractPunctuationUnigram(PATTERN_ID_TYPE id, vector<double> &feature) {
        if (id2ends[id].size() == 0) {
            feature.push_back(0);
            feature.push_back(0);
            feature.push_back(0);
            feature.push_back(0);
            return;
        }
        TOTAL_TOKENS_TYPE quote = 0, parenthesis = 0, allCap = 0, allCAP = 0;
        for (const TOTAL_TOKENS_TYPE& ed : id2ends[id]) {
            TOTAL_TOKENS_TYPE st = ed - patterns[id].size() + 1;
            assert(Documents::wordTokens[st] == patterns[id].tokens[0]);

            bool isAllCap = true, isAllCAP = true;
            for (TOTAL_TOKENS_TYPE j = st; j <= ed; ++ j) {
                isAllCap &= Documents::isFirstCapital(j);
                isAllCAP &= Documents::isAllCapital(j);
            }
            allCap += isAllCap;
            allCAP += isAllCAP;
            if (Documents::hasQuoteBefore(st) && Documents::hasQuoteAfter(ed)) {
                ++ quote;
            }
            if (Documents::hasParentThesisBefore(st) && Documents::hasParentThesisAfter(ed)) {
                ++ parenthesis;
            }
        }
        feature.push_back((double)quote / id2ends[id].size());
        feature.push_back((double)parenthesis / id2ends[id].size());
        feature.push_back((double)allCap / id2ends[id].size());
        feature.push_back((double)allCAP / id2ends[id].size()); // not used in SegPhrase
    }

    void extractCompletenessUnigram(Pattern &pattern, vector<double> &feature) {
        const vector<TOTAL_TOKENS_TYPE> &tokens = pattern.tokens;
        vector<unordered_set<TOTAL_TOKENS_TYPE>> distinct(tokens.size());
        PATTERN_ID_TYPE id = pattern2id[pattern.hashValue];
        double freq = patterns[id].currentFreq;
        double superFreq = 0;

        for (const TOTAL_TOKENS_TYPE &ed : id2ends[id]) {
            TOTAL_TOKENS_TYPE st = ed - tokens.size();
            if (st > 0 && !Documents::isEndOfSentence(st - 1)) {
                Pattern left;
                for (TOTAL_TOKENS_TYPE i = st - 1; i <= ed; ++ i) {
                    left.append(wordTokens[i]);
                }
                superFreq = max(superFreq, (double)getFrequency(left));
            }
            if (!Documents::isEndOfSentence(ed) && ed + 1 < totalWordTokens) {
                Pattern right = pattern;
                right.append(wordTokens[ed + 1]);
                superFreq = max(superFreq, (double)getFrequency(right));
            }
        }
        feature.push_back(superFreq / freq);
    }

    vector<vector<double>> extractUnigram(vector<string> &featureNames) {
        // prepare token counts
        const TOTAL_TOKENS_TYPE& corpusTokensN = Documents::totalWordTokens;
        for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
            patterns[i].probability = patterns[i].currentFreq / (corpusTokensN / (double)patterns[i].size());
        }

        featureNames = {"log_frequency", "independent_ratio",
                        "stopwords", "idf",
                        "punc_quote", "punc_parenthesis", "first_capitalized", "all_capitalized",
                        "complete_super"
                        };

        // compute features for each pattern
        vector<vector<double>> features(patterns.size(), vector<double>());
        # pragma omp parallel for schedule(dynamic, PATTERN_CHUNK_SIZE)
        for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
            if (patterns[i].size() == 1) {
                const Pattern& pattern = patterns[i];

                features[i].push_back(log(pattern.currentFreq + 1.0));
                features[i].push_back((double)pattern.currentFreq / unigrams[pattern.tokens[0]]);

                features[i].push_back(Documents::stopwords.count(pattern.tokens[0]) || Documents::isDigital[pattern.tokens[0]]);
                features[i].push_back(Documents::idf[pattern.tokens[0]]);

                extractPunctuationUnigram(i, features[i]);
                extractCompletenessUnigram(patterns[i], features[i]);

                features[i].shrink_to_fit();
            }
        }
        features.shrink_to_fit();
        return features;
    }
};

#endif

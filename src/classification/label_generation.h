#ifndef __LABEL_GENERATION_H__
#define __LABEL_GENERATION_H__

#include "../utils/utils.h"
#include "../data/documents.h"
#include "../frequent_pattern_mining/frequent_pattern_mining.h"
#include "../clustering/clustering.h"
#include "../classification/predict_quality.h"

using Documents::totalWordTokens;
using Documents::wordTokens;

using FrequentPatternMining::Pattern;
using FrequentPatternMining::patterns;
using FrequentPatternMining::pattern2id;
using FrequentPatternMining::id2ends;
using FrequentPatternMining::unigrams;

namespace Label
{

inline vector<Pattern> loadLabels(string filename)
{
    vector<Pattern> ret;
    FILE* in = tryOpen(filename, "r");
    while (getLine(in)) {
        stringstream sin(line);
        bool valid = true;
        Pattern p;
        sin >> p.label;
        for (TOKEN_ID_TYPE s; sin >> s;) {
            p.append(s);
        }
        if (p.size() > 1) {
            ret.push_back(p);
        }
    }
    cerr << "# of loaded labels = " << ret.size() << endl;
    return ret;
}

inline unordered_set<ULL> loadPatterns(string filename)
{
    FILE* in = tryOpen(filename, "r");
    unordered_set<ULL> ret;
    while (getLine(in)) {
        stringstream sin(line);
        bool valid = true;
        Pattern p;
        for (string s; sin >> s;) {
            bool possibleInt = false;
            for (int i = 0; i < s.size(); ++ i) {
                possibleInt |= isdigit(s[i]);
            }
            if (possibleInt) {
                int x;
                fromString(s, x);
                if (x < 0) {
                    valid = false;
                    break;
                }
                p.append(x);
            }
        }
        if (valid) {
            ret.insert(p.hashValue);
        }
    }
    fclose(in);
    return ret;
}

inline vector<int> select(vector<int> candidates, const vector<vector<double>> &features, int n)
{
    if (n > candidates.size()) {
        fprintf(stderr, "[WARNING] labels may not be enough. Only %d\n", candidates.size());
        return candidates;
    }

    if (candidates.size() > 10 * n) {
        random_shuffle(candidates.begin(), candidates.end());
        candidates.resize(10 * n);
    }

    HardClustering *solver = new KMeans(n);
    vector<vector<double>> points;
    for (int i : candidates) {
        points.push_back(features[i]);
    }
    # pragma omp parallel for
    for (int j = 0; j < points[0].size(); ++ j) {
        double sum = 0, sum2 = 0;
        for (int i = 0; i < points.size(); ++ i) {
            sum += points[i][j];
            sum2 += sqr(points[i][j]);
        }
        double avg = sum / points.size();
        double stderror = sqrt(fabs(sum2 / points.size() - avg * avg));
        if (stderror < EPS) {
            cerr << "useless feature " << j << endl;
        }
        for (int i = 0; i < points.size(); ++ i) {
            points[i][j] -= avg;
            if (stderror > EPS) {
                points[i][j] /= stderror;
            }
        }
    }
    vector<int> assignment = solver->clustering(points);

    vector<vector<int>> clusters(n, vector<int>());
    for (int i = 0; i < assignment.size(); ++ i) {
        clusters[assignment[i]].push_back(candidates[i]);
    }
    vector<int> ret;
    for (vector<int> arr : clusters) {
        if (arr.size()) {
            ret.push_back(arr[rand() % arr.size()]);
        }
    }
    return ret;
}

inline vector<PATTERN_ID_TYPE> samplingByLength(vector<PATTERN_ID_TYPE> all, PATTERN_ID_TYPE total, PATTERN_ID_TYPE base = 0)
{
    if (total <= 0 || total >= all.size()) {
        return all;
    }

    vector<PATTERN_ID_TYPE> ret;
    unordered_map<int, vector<PATTERN_ID_TYPE>> groups;
    for (PATTERN_ID_TYPE id : all) {
        groups[patterns[id].size()].push_back(id);
    }
    PATTERN_ID_TYPE accumulated = 0, remain = total - base * groups.size();
    if (remain < 0) {
        remain = total;
        base = 0;
    }

    for (auto& iter : groups) {
        vector<PATTERN_ID_TYPE>& group = iter.second;
        PATTERN_ID_TYPE weight = (PATTERN_ID_TYPE)group.size() - base;
        assert(weight >= 0);

        double percent1 = (double)accumulated / (all.size() - base * groups.size());
        double percent2 = (double)(accumulated + weight) / (all.size() - base * groups.size());

        accumulated += weight;
        assert(accumulated <= all.size() - base * groups.size());

        PATTERN_ID_TYPE limit = (PATTERN_ID_TYPE)(remain * percent2) - (PATTERN_ID_TYPE)(remain * percent1) + base;
        assert(limit >= 0 && limit < group.size());
// cerr << "length = " << iter.first << ", samples = " << limit << "/" << group.size() << endl;
        random_shuffle(group.begin(), group.end());
        if (limit < group.size()) {
            group.resize(limit);
        }

        for (PATTERN_ID_TYPE id : group) {
            ret.push_back(id);
        }
    }
    return ret;
}

inline vector<Pattern> generateBootstrap(vector<vector<double>> &features, vector<string> &featureNames, vector<PATTERN_ID_TYPE> &positives, vector<PATTERN_ID_TYPE> &negatives)
{
    vector<Pattern> ret;
    srand(19910724);
    // randomly choose the initial labels
    random_shuffle(positives.begin(), positives.end());
    random_shuffle(negatives.begin(), negatives.end());

    PATTERN_ID_TYPE cntPositives = 0;
    for (PATTERN_ID_TYPE i = 0; i < positives.size() && i < MAX_POSITIVE; ++ i) {
        patterns[positives[i]].label = 1;
        ++ cntPositives;
    }
    for (PATTERN_ID_TYPE i = 0; i < negatives.size() && i < cntPositives * NEGATIVE_RATIO; ++ i) {
        patterns[negatives[i]].label = 0;
    }
    predictQuality(patterns, features, featureNames);

    for (PATTERN_ID_TYPE i = 0; i < positives.size() && i < MAX_POSITIVE; ++ i) {
        patterns[positives[i]].label = FrequentPatternMining::UNKNOWN_LABEL;
    }
    for (PATTERN_ID_TYPE i = 0; i < negatives.size() && i < cntPositives * NEGATIVE_RATIO; ++ i) {
        patterns[negatives[i]].label = FrequentPatternMining::UNKNOWN_LABEL;
    }

    vector<PATTERN_ID_TYPE> newPositives, newNegatives;
    for (PATTERN_ID_TYPE i = 0; i < positives.size(); ++ i) {
        if (patterns[positives[i]].quality > 0.1) {
            newPositives.push_back(positives[i]);
        }
    }
    for (PATTERN_ID_TYPE i = 0; i < negatives.size(); ++ i) {
        if (patterns[negatives[i]].quality < 0.9) {
            newNegatives.push_back(negatives[i]);
        }
    }
    random_shuffle(newPositives.begin(), newPositives.end());
    random_shuffle(newNegatives.begin(), newNegatives.end());

    // positives
    if (cntPositives < newPositives.size()) {
        newPositives.resize(cntPositives);
    }
    if (newPositives.size() < newNegatives.size()) {
        newNegatives.resize(newPositives.size());
    }
    for (PATTERN_ID_TYPE id : newPositives) {
        ret.push_back(patterns[id]);
        ret.back().label = 1;
    }
    for (PATTERN_ID_TYPE id : newNegatives) {
        ret.push_back(patterns[id]);
        ret.back().label = 0;
    }

    fprintf(stderr, "selected positives = %d\n", positives.size());
    fprintf(stderr, "selected negatives = %d\n", newNegatives.size());

    return ret;
}

inline vector<Pattern> generate(vector<vector<double>> &features, vector<string> &featureNames, string ALL_FILE, string QUALITY_FILE)
{
    unordered_set<ULL> exclude = loadPatterns(ALL_FILE);
    unordered_set<ULL> include = loadPatterns(QUALITY_FILE);

    vector<pair<ULL, PATTERN_ID_TYPE>> positiveOrder, negativeOrder;
    for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() <= 1) {
            continue;
        }
        assert(features[i].size() != 0);
        if (include.count(patterns[i].hashValue)) {
            positiveOrder.push_back(make_pair(patterns[i].hashValue, i));
        } else if (!exclude.count(patterns[i].hashValue)) {
            negativeOrder.push_back(make_pair(patterns[i].hashValue, i));
        }
    }
    sort(positiveOrder.begin(), positiveOrder.end());
    sort(negativeOrder.begin(), negativeOrder.end());
    // make sure the patterns are same each time
    vector<PATTERN_ID_TYPE> positives, negatives;
    for (const auto& iter : positiveOrder) {
        positives.push_back(iter.second);
    }
    for (const auto& iter : negativeOrder) {
        negatives.push_back(iter.second);
    }

    if (INTERMEDIATE) {
        fprintf(stderr, "matched positives = %d\n", positives.size());
        fprintf(stderr, "matched negatives = %d\n", negatives.size());
    }

    if (LABEL_METHOD == "ByBootstrap") {
        return generateBootstrap(features, featureNames, positives, negatives);
    }

    vector<Pattern> ret;
    int cntPositives = 0, cntNegatives = 0;
    srand(19910724);

    random_shuffle(positives.begin(), positives.end());
    if (MAX_POSITIVE > 0 && MAX_POSITIVE < positives.size()) {
        positives.resize(MAX_POSITIVE);
    }

/*
    if (LABEL_METHOD.find("ByLength") != -1) {
        positives = samplingByLength(positives, MAX_POSITIVE, 0);
    } else if (LABEL_METHOD.find("ByRandom") != -1) {
        random_shuffle(positives.begin(), positives.end());
        if (MAX_POSITIVE > 0 && MAX_POSITIVE < positives.size()) {
            positives.resize(MAX_POSITIVE);
        }
    } else if (LABEL_METHOD.find("ByKMeans") != -1) {
        positives = select(positives, features, MAX_POSITIVE);
    }
*/

    unordered_set<PATTERN_ID_TYPE> negativeSet(negatives.begin(), negatives.end());

    // positives
    for (PATTERN_ID_TYPE id : positives) {
        ret.push_back(patterns[id]);
        ret.back().label = 1;
        ++ cntPositives;
    }

    // negatives part 1
    if (LABEL_METHOD.find("ByPositive") != -1) {
        for (PATTERN_ID_TYPE id : positives) {
            // sub pattern
            for (int st = 0; st < patterns[id].size(); ++ st) {
                Pattern pattern;
                for (int ed = st; ed < patterns[id].size(); ++ ed) {
                    pattern.append(patterns[id].tokens[ed]);
                    if (pattern.size() > 1 && pattern2id.count(pattern.hashValue)) {
                        PATTERN_ID_TYPE subID = pattern2id[pattern.hashValue];
                        if (negativeSet.count(subID)) {
                            ret.push_back(patterns[subID]);
                            ret.back().label = 0;
                            negativeSet.erase(subID);
                            ++ cntNegatives;
                        }
                    }
                }
            }
            // super pattern
            PATTERN_ID_TYPE superLeft = -1, superRight = -1;
            for (TOTAL_TOKENS_TYPE ed : id2ends[id]) {
                TOTAL_TOKENS_TYPE st = ed - patterns[id].size();
                if (st > 0 && !Documents::isEndOfSentence(st - 1)) {
                    Pattern left;
                    for (TOTAL_TOKENS_TYPE i = st - 1; i <= ed; ++ i) {
                        left.append(wordTokens[i]);
                    }
                    if (pattern2id.count(left.hashValue)) {
                        PATTERN_ID_TYPE superID = pattern2id[left.hashValue];
                        if (negativeSet.count(superID)) {
                            if (superLeft == -1 || patterns[superID].currentFreq > patterns[superLeft].currentFreq) {
                                superLeft = superID;
                            }

                            ret.push_back(patterns[superID]);
                            ret.back().label = 0;
                            negativeSet.erase(superID);
                            ++ cntNegatives;
                        }
                    }
                }
                if (!Documents::isEndOfSentence(ed) && ed + 1 < totalWordTokens) {
                    Pattern right = patterns[id];
                    right.append(wordTokens[ed + 1]);
                    if (pattern2id.count(right.hashValue)) {
                        PATTERN_ID_TYPE superID = pattern2id[right.hashValue];
                        if (negativeSet.count(superID)) {
                            if (superRight == -1 || patterns[superID].currentFreq > patterns[superRight].currentFreq) {
                                superRight = superID;
                            }

                            ret.push_back(patterns[superID]);
                            ret.back().label = 0;
                            negativeSet.erase(superID);
                            ++ cntNegatives;
                        }
                    }
                }
            }
        }
    }

    // negatives part 2
    negatives = vector<int>(negativeSet.begin(), negativeSet.end());
    if (LABEL_METHOD.find("ByLength") != -1) {
        negatives = samplingByLength(negatives, positives.size() * NEGATIVE_RATIO);
    } else if (LABEL_METHOD.find("ByRandom") != -1) {
        random_shuffle(negatives.begin(), negatives.end());
        if (positives.size() * NEGATIVE_RATIO < negatives.size()) {
            negatives.resize(positives.size() * NEGATIVE_RATIO);
        }
    } else if (LABEL_METHOD.find("ByKMeans") != -1) {
        negatives = select(negatives, features, positives.size() * NEGATIVE_RATIO);
    } else {
        negatives.clear();
    }

    for (PATTERN_ID_TYPE id : negatives) {
        ret.push_back(patterns[id]);
        ret.back().label = 0;
        ++ cntNegatives;
    }

    fprintf(stderr, "\t[multi-word phrase] # of positive labels = %d\n", cntPositives);
    fprintf(stderr, "\t[multi-word phrase] # of negative labels = %d\n", cntNegatives);

    return ret;
}

inline vector<Pattern> generateUnigram(vector<vector<double>> &features, string ALL_FILE, string QUALITY_FILE)
{
    unordered_set<ULL> exclude = loadPatterns(ALL_FILE);
    unordered_set<ULL> include = loadPatterns(QUALITY_FILE);

    vector<pair<ULL, PATTERN_ID_TYPE>> positiveOrder, negativeOrder;
    for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() != 1 || unigrams[patterns[i].tokens[0]] < MIN_SUP) {
            continue;
        }
        if (include.count(patterns[i].hashValue)) {
            positiveOrder.push_back(make_pair(patterns[i].hashValue, i));
        } else if (!exclude.count(patterns[i].hashValue)) {
            negativeOrder.push_back(make_pair(patterns[i].hashValue, i));
        }
    }
    sort(positiveOrder.begin(), positiveOrder.end());
    sort(negativeOrder.begin(), negativeOrder.end());
    // make sure the patterns are same each time
    vector<PATTERN_ID_TYPE> positives, negatives;
    for (const auto& iter : positiveOrder) {
        positives.push_back(iter.second);
    }
    for (const auto& iter : negativeOrder) {
        negatives.push_back(iter.second);
    }

    if (INTERMEDIATE) {
        fprintf(stderr, "matched positives = %d\n", positives.size());
        fprintf(stderr, "matched negatives = %d\n", negatives.size());
    }

    srand(19910724);
    random_shuffle(positives.begin(), positives.end());
    if (MAX_POSITIVE > 0 && MAX_POSITIVE < positives.size()) {
        positives.resize(MAX_POSITIVE);
    }

    if (LABEL_METHOD.find("ByKMeans") != -1) {
        negatives = select(negatives, features, positives.size() * NEGATIVE_RATIO);
    } else {
        random_shuffle(negatives.begin(), negatives.end());
        if (positives.size() * NEGATIVE_RATIO < negatives.size()) {
            negatives.resize(positives.size() * NEGATIVE_RATIO);
        }
    }

    vector<Pattern> ret;
    int cntPositives = 0, cntNegatives = 0;
    // positives
    for (PATTERN_ID_TYPE id : positives) {
        ret.push_back(patterns[id]);
        ret.back().label = 1;
        ++ cntPositives;
    }
    // negatives
    for (PATTERN_ID_TYPE id : negatives) {
        ret.push_back(patterns[id]);
        ret.back().label = 0;
        ++ cntNegatives;
    }

    fprintf(stderr, "\t[single-word phrase] # of positive labels = %d\n", cntPositives);
    fprintf(stderr, "\t[single-word phrase] # of negative labels = %d\n", cntNegatives);

    return ret;
}

inline vector<Pattern> generateAll(string ALL_FILE, string QUALITY_FILE)
{
    unordered_set<ULL> exclude = loadPatterns(ALL_FILE);
    unordered_set<ULL> include = loadPatterns(QUALITY_FILE);

    vector<Pattern> ret;
    int cntPositives = 0, cntNegatives = 0;
    for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() < 1) {
            continue;
        }
        if (include.count(patterns[i].hashValue)) {
            ret.push_back(patterns[i]);
            ret.back().label = 1;
            ++ cntPositives;
        } else if (!exclude.count(patterns[i].hashValue)) {
            ret.push_back(patterns[i]);
            ret.back().label = 0;
            ++ cntNegatives;
        }
    }
    fprintf(stderr, "\tThe size of the positive pool = %d\n", cntPositives);
    fprintf(stderr, "\tThe size of the negative pool = %d\n", cntNegatives);

    return ret;
}

void removeWrongLabels()
{
    for (Pattern& pattern : patterns) {
        if (pattern.currentFreq == 0 && pattern.label == 1) {
            pattern.label = FrequentPatternMining::UNKNOWN_LABEL;
        }
    }
}

}

#endif

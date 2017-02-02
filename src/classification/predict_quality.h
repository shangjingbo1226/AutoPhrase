#ifndef __PREDICT_QUALITY_H__
#define __PREDICT_QUALITY_H__

#include "../frequent_pattern_mining/frequent_pattern_mining.h"
using FrequentPatternMining::Pattern;

#include "random_forest.h"
using namespace RandomForestRelated;

void predictQuality(vector<Pattern> &patterns, vector<vector<double>> &features, vector<string> &featureNames)
{
    vector<vector<double>> trainX;
    vector<double> trainY;
    for (int i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() > 1 && patterns[i].label != FrequentPatternMining::UNKNOWN_LABEL) {
            trainX.push_back(features[i]);
            trainY.push_back(patterns[i].label);
        }
    }

    if (trainX.size() == 0) {
        fprintf(stderr, "[ERROR] no training data found!\n");
        return;
    }

    initialize();
    TASK_TYPE = REGRESSION;
    RandomForest *solver = new RandomForest();
    RANDOM_FEATURES = 4;
    RANDOM_POSITIONS = 4;
    K_OUT_OF_N = 100;

    cerr << "K = " << K_OUT_OF_N << endl;

    // fprintf(stderr, "[multi-word phrase] phrase quality estimation...\n");
    solver->train(trainX, trainY, 1000, 1, 100, featureNames);

    if (INTERMEDIATE) {
        vector<pair<double, string>> order;
        for (int i = 0; i < featureImportance.size(); ++ i) {
            order.push_back(make_pair(featureImportance[i], featureNames[i]));
        }
        sort(order.rbegin(), order.rend());
        for (int i = 0; i < order.size(); ++ i) {
            cerr << order[i].first << "\t" << order[i].second << endl;
        }
    }

	for (int i = 0; i < features.size(); ++ i) {
        if (patterns[i].size() > 1) {
            patterns[i].quality = solver->estimate(features[i]);
        }
	}
}

void predictQualityUnigram(vector<Pattern> &patterns, vector<vector<double>> &features, vector<string> &featureNames)
{
    vector<vector<double>> trainX;
    vector<double> trainY;
    for (int i = 0; i < patterns.size(); ++ i) {
        if (patterns[i].size() == 1 && patterns[i].label != FrequentPatternMining::UNKNOWN_LABEL) {
            trainX.push_back(features[i]);
            trainY.push_back(patterns[i].label);
        }
    }

    if (trainX.size() == 0) {
        fprintf(stderr, "[ERROR] no training data found!\n");
        return;
    }

    initialize();
    TASK_TYPE = REGRESSION;
    RandomForest *solver = new RandomForest();
    RANDOM_FEATURES = 4;
    RANDOM_POSITIONS = 4;
    K_OUT_OF_N = 100;

    // fprintf(stderr, "[single-word phrase] phrase quality estimation...\n");
    solver->train(trainX, trainY, 1000, 1, 100, featureNames);

    if (INTERMEDIATE) {
        vector<pair<double, string>> order;
        for (int i = 0; i < featureImportance.size(); ++ i) {
            order.push_back(make_pair(featureImportance[i], featureNames[i]));
        }
        sort(order.rbegin(), order.rend());
        for (int i = 0; i < order.size(); ++ i) {
            cerr << order[i].first << "\t" << order[i].second << endl;
        }
    }

	for (int i = 0; i < features.size(); ++ i) {
        if (patterns[i].size() == 1) {
            patterns[i].quality = solver->estimate(features[i]);
        }
	}
}


#endif

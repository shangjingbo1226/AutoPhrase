#include "utils/parameters.h"
#include "utils/commandline_flags.h"
#include "utils/utils.h"
#include "frequent_pattern_mining/frequent_pattern_mining.h"
#include "data/documents.h"
#include "classification/feature_extraction.h"
#include "classification/label_generation.h"
#include "classification/predict_quality.h"
#include "model_training/segmentation.h"
#include "data/dump.h"

using FrequentPatternMining::Pattern;
using FrequentPatternMining::patterns;

int main(int argc, char* argv[])
{
    parseCommandFlags(argc, argv);

    sscanf(argv[1], "%d", &NTHREADS);
    omp_set_num_threads(NTHREADS);

    // load stopwords, documents, and capital information
    Documents::loadStopwords(STOPWORDS_FILE);
    Documents::loadAllTrainingFiles(TRAIN_FILE, POS_TAGS_FILE, TRAIN_CAPITAL_FILE);
    Documents::splitIntoSentences();

    FrequentPatternMining::mine(MIN_SUP, MAX_LEN);
    // check the patterns
    if (INTERMEDIATE) {
        vector<pair<int, int>> order;
        for (int i = 0; i < patterns.size(); ++ i) {
            order.push_back(make_pair(patterns[i].currentFreq, i));
        }
        Dump::dumpRankingList("tmp/frequent_patterns.txt", order);
    }

    // feature extraction
    vector<string> featureNames;
    vector<vector<double>> features = Features::extract(featureNames);

    vector<string> featureNamesUnigram;
    vector<vector<double>> featuresUnigram = Features::extractUnigram(featureNamesUnigram);

    cerr << "feature extraction done!" << endl;

    vector<Pattern> truth;
    if (LABEL_FILE != "") {
        cerr << "=== Load Existing Labels ===" << endl;
        truth = Label::loadLabels(LABEL_FILE);
        int recognized = Features::recognize(truth);
    } else {
        // generate labels
        cerr << "=== Generate Labels ===" << endl;
        // multi-words
        truth = Label::generate(features, featureNames, ALL_FILE, QUALITY_FILE);
        int recognized = Features::recognize(truth);

        // unigram
        vector<Pattern> truthUnigram = Label::generateUnigram(featuresUnigram, ALL_FILE, QUALITY_FILE);
        int recognizedUnigram = Features::recognize(truthUnigram);

        if (INTERMEDIATE) {
            Dump::dumpLabels("tmp/generated_label.txt", truth);
            Dump::dumpLabels("tmp/generated_unigram_label.txt", truthUnigram);

            Dump::dumpFeatures("tmp/features_for_labels.tsv", features, truth);
            Dump::dumpFeatures("tmp/features_for_unigram_labels.tsv", featuresUnigram, truthUnigram);
        }
    }

    if (ENABLE_POS_TAGGING) {
        Segmentation::initializePosTags(Documents::posTag2id.size());
    }

    // SegPhrase, +, ++, +++, ...
    for (int iteration = 0; iteration < ITERATIONS; ++ iteration) {
        fprintf(stderr, "Feature Matrix = %d X %d\n", features.size(), features.back().size());
        predictQuality(patterns, features, featureNames);
        predictQualityUnigram(patterns, featuresUnigram, featureNamesUnigram);

        constructTrie(); // update the current frequent enough patterns

        // check the quality
        if (INTERMEDIATE) {
            char filename[256];
            sprintf(filename, "tmp/iter_%d_quality", iteration);
            Dump::dumpResults(filename);
        }

        if (!ENABLE_POS_TAGGING) {
            cerr << "[Length Penalty Mode]" << endl;
            double penalty = EPS;
            if (true) {
                // Binary Search for Length Penalty
                double lower = EPS, upper = 200;
                for (int _ = 0; _ < 10; ++ _) {
                    penalty = (lower + upper) / 2;
                    Segmentation segmentation(penalty);
                    segmentation.rectifyFrequency(Documents::sentences);
                    double wrong = 0, total = 0;
                    # pragma omp parallel for reduction (+:total,wrong)
                    for (int i = 0; i < truth.size(); ++ i) {
                        if (truth[i].label == 1) {
                            ++ total;
                            vector<double> f;
                            vector<int> pre;
                            segmentation.viterbi(truth[i].tokens, f, pre);
                            wrong += pre[truth[i].tokens.size()] != 0;
                        }
                    }
                    if (wrong / total <= DISCARD) {
                        lower = penalty;
                    } else {
                        upper = penalty;
                    }
                }
                cerr << "Length Penalty = " << penalty << endl;
            }
            // Running Segmentation
            Segmentation segmentation(penalty);
            segmentation.rectifyFrequency(Documents::sentences);
        } else {
            cerr << "[POS Tags Mode]" << endl;
            if (true) {
                Segmentation segmentation(ENABLE_POS_TAGGING);
                double last = 1e100;
                for (int inner = 0; inner < 10; ++ inner) {
                    double energy = segmentation.adjustPOSTagTransition(Documents::sentences, MIN_SUP);
                    if (fabs(energy - last) / fabs(last) < EPS) {
                        break;
                    }
                    last = energy;
                }
            }

            if (INTERMEDIATE) {
                char filename[256];
                sprintf(filename, "tmp/iter_%d_pos_tags.txt", iteration);
                Dump::dumpPOSTransition(filename);
            }

            Segmentation segmentation(ENABLE_POS_TAGGING);
            segmentation.rectifyFrequencyPOS(Documents::sentences, MIN_SUP);
        }

        if (iteration + 1 < ITERATIONS) {
            // rectify the features
            cerr << "Rectify Features..." << endl;
            Label::removeWrongLabels();

            /*
            // use number of sentences + rectified frequency to approximate the new idf
            double docs = Documents::sentences.size() + EPS;
            double diff = 0;
            int cnt = 0;
            for (int i = 0; i < patterns.size(); ++ i) {
                if (patterns[i].size() == 1) {
                    const TOKEN_ID_TYPE& token = patterns[i].tokens[0];
                    TOTAL_TOKENS_TYPE freq = patterns[i].currentFreq;
                    double newIdf = log(docs / (freq + EPS) + EPS);
                    diff += abs(newIdf - Documents::idf[token]);
                    ++ cnt;
                    Documents::idf[token] = newIdf;
                }
            }
            */

            features = Features::extract(featureNames);
            featuresUnigram = Features::extractUnigram(featureNamesUnigram);
        }

        // check the quality
        if (INTERMEDIATE) {
            char filename[256];
            sprintf(filename, "tmp/iter_%d_frequent_quality", iteration);
            Dump::dumpResults(filename);
        }
    }

    Dump::dumpResults("tmp/final_quality");
    Dump::dumpSegmentationModel("results/segmentation.model");

    return 0;
}

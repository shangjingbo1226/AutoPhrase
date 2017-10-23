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
using FrequentPatternMining::truthPatterns;

int main(int argc, char* argv[])
{
    parseCommandFlags(argc, argv);

    sscanf(argv[1], "%d", &NTHREADS);
    omp_set_num_threads(NTHREADS);

    cerr << "Loading data..." << endl;
    // load stopwords, documents, and capital information
    Documents::loadStopwords(STOPWORDS_FILE);
    Documents::loadAllTrainingFiles(TRAIN_FILE, POS_TAGS_FILE, TRAIN_CAPITAL_FILE);
    Documents::splitIntoSentences();

    cerr << "Mining frequent phrases..." << endl;
    FrequentPatternMining::initialize();
    FrequentPatternMining::mine(MIN_SUP, MAX_LEN);
    // check the patterns
    if (INTERMEDIATE) {
        vector<pair<TOTAL_TOKENS_TYPE, PATTERN_ID_TYPE>> order;
        for (PATTERN_ID_TYPE i = 0; i < patterns.size(); ++ i) {
            order.push_back(make_pair(patterns[i].currentFreq, i));
        }
        Dump::dumpRankingList("tmp/frequent_patterns.txt", order);
    }

    // feature extraction
    cerr << "Extracting features..." << endl;
    vector<string> featureNames;
    vector<vector<double>> features = Features::extract(featureNames);

    vector<string> featureNamesUnigram;
    vector<vector<double>> featuresUnigram = Features::extractUnigram(featureNamesUnigram);

    cerr << "Constructing label pools..." << endl;
    vector<Pattern> truth = Label::generateAll(LABEL_METHOD, LABEL_FILE, ALL_FILE, QUALITY_FILE);

    truthPatterns = Label::loadTruthPatterns(QUALITY_FILE);
    cerr << "# truth patterns = " << truthPatterns.size() << endl;
    for (Pattern p : truth) {
        if (p.label == 1) {
            truthPatterns.push_back(p);
        }
    }
    TOTAL_TOKENS_TYPE recognized = Features::recognize(truth);

    if (ENABLE_POS_TAGGING) {
        Segmentation::initializePosTags(Documents::posTag2id.size());
    }

    // SegPhrase, +, ++, +++, ...
    for (int iteration = 0; iteration < ITERATIONS; ++ iteration) {
        if (INTERMEDIATE) {
            fprintf(stderr, "Feature Matrix = %d X %d\n", features.size(), features.back().size());
        }
        cerr << "Estimating Phrase Quality..." << endl;
        predictQuality(patterns, features, featureNames);
        predictQualityUnigram(patterns, featuresUnigram, featureNamesUnigram);

        /*
        if (iteration == 0) {
            Dump::dumpResults("tmp/distant_training_only");
            break;
        }
        */

        constructTrie(); // update the current frequent enough patterns

        // check the quality
        if (INTERMEDIATE) {
            char filename[256];
            sprintf(filename, "tmp/iter_%d_quality", iteration);
            Dump::dumpResults(filename);
        }

        cerr << "Segmenting..." << endl;
        if (!ENABLE_POS_TAGGING) {
            if (INTERMEDIATE) {
                cerr << "[Length Penalty Mode]" << endl;
            }
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
            }
            if (INTERMEDIATE) {
                cerr << "Length Penalty = " << penalty << endl;
            }
            // Running Segmentation
            Segmentation segmentation(penalty);
            segmentation.rectifyFrequency(Documents::sentences);
        } else {
            if (INTERMEDIATE) {
                cerr << "[POS Tags Mode]" << endl;
            }
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
            cerr << "Rectifying features..." << endl;
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

    cerr << "Dumping results..." << endl;
    Dump::dumpResults("tmp/final_quality");
    Dump::dumpSegmentationModel("tmp/segmentation.model");

    cerr << "Done." << endl;

    return 0;
}

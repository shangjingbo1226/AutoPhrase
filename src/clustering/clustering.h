#ifndef __CLUSTERING_H__
#define __CLUSTERING_H__

#include "../utils/utils.h"

class HardClustering
{
public:
    virtual vector<int> clustering(const vector<vector<double>> &points) = 0;
};

class KMeans : public HardClustering
{
private:
    int n, iter, rounds;
    double EPS;

    inline double dist(const vector<double> &a, const vector<double> &b) {
        double sum = 0;
        for (int i = 0; i < a.size(); ++ i) {
            sum += sqr(a[i] - b[i]);
        }
        return sum;
    }

    inline vector<vector<double>> initialize(const vector<vector<double>> &points) {
        vector<vector<double>> ret;
        ret.push_back(points[rand() % points.size()]);

        vector<double> closest(points.size(), 1e100);
        for (int i = 0; i < points.size(); ++ i) {
            closest[i] = dist(points[i], ret.back());
        }
        for (int k = 1; k < n; ++ k) {
            double maxi = -1;
            int select = 0;
            for (int i = 0; i < points.size(); ++ i) {
                if (closest[i] > maxi) {
                    maxi = closest[i];
                    select = i;
                }
            }
            ret.push_back(points[select]);
            for (int i = 0; i < points.size(); ++ i) {
                closest[i] = min(closest[i], dist(points[i], ret.back()));
            }
        }
        return ret;
    }

    inline double adjust(const vector<vector<double>> &points, vector<int> &assignment, vector<vector<double>> &center) {
        vector<int> cnt(center.size(), 0);
        double loss = 1e100, lastLoss = 1e100;
        for (int _ = 0; _ < rounds; ++ _) {
            loss = 0;
            # pragma omp parallel for schedule(dynamic, POINT_CHUNK_SIZE) reduction (+:loss)
            for (int i = 0; i < points.size(); ++ i) {
                double closest = 1e100;
                for (int j = 0; j < center.size(); ++ j) {
                    double d = dist(points[i], center[j]);
                    if (d < closest) {
                        closest = d;
                        assignment[i] = j;
                    }
                }
                loss += closest;
            }
            if (lastLoss < EPS || fabs(loss - lastLoss) / lastLoss < EPS) {
                break;
            }
            lastLoss = loss;

            # pragma omp parallel for schedule(dynamic, POINT_CHUNK_SIZE)
            for (int j = 0; j < center.size(); ++ j) {
                for (int k = 0; k < center[j].size(); ++ k) {
                    center[j][k] = 0;
                }
                cnt[j] = 0;
            }
            for (int i = 0; i < points.size(); ++ i) {
                int id = assignment[i];
                # pragma omp parallel for schedule(dynamic, POINT_CHUNK_SIZE)
                for (int k = 0; k < center[id].size(); ++ k) {
                    center[id][k] += points[i][k];
                }
                ++ cnt[id];
            }
            # pragma omp parallel for schedule(dynamic, POINT_CHUNK_SIZE)
            for (int j = 0; j < center.size(); ++ j) {
                if (cnt[j] > 0) {
                    double ratio = 1.0 / cnt[j];
                    for (int k = 0; k < center[j].size(); ++ k) {
                        center[j][k] *= ratio;
                    }
                }
            }
        }
        return loss;
    }

public:
    KMeans(int n, int iter = 10, int rounds = 100, double EPS = 1e-3) : n(n), iter(iter), rounds(rounds), EPS(EPS) {
        srand(19910724);
    }
    virtual vector<int> clustering(const vector<vector<double>> &points) {
        assert(points.size() != 0);
        cerr << "Clustering Started... " << endl;
        vector<int> ret;
        double best = 1e100;
        vector<int> assignment(points.size(), 0);
        for (int i = 0; i < iter; ++ i) {
            vector<vector<double>> center = initialize(points);
            double opt = adjust(points, assignment, center);
            if (ret.size() == 0 || opt < best) {
                best = opt;
                ret = assignment;
            }
        }
        cerr << "Clustering Done... " << endl;
        return ret;
    }
};

#endif

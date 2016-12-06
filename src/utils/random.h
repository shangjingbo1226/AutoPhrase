#ifndef __RANDOM_H__
#define __RANDOM_H__

#include "utils.h"

namespace RandomNumbers
{
struct RandomNumberGenerator
{
    unsigned int MT[624];
    int index;

    void init(int seed = 1) {
        MT[0] = seed;
        for (int i = 1; i < 624; ++ i) {
            MT[i] = (1812433253UL * (MT[i-1] ^ (MT[i-1] >> 30)) + i);
        }
        index = 0;
    }

    void generate() {
        const unsigned int MULT[] = {0, 2567483615UL};
        for (int i = 0; i < 227; ++ i) {
            unsigned int y = (MT[i] & 0x8000000UL) + (MT[i+1] & 0x7FFFFFFFUL);
            MT[i] = MT[i+397] ^ (y >> 1);
            MT[i] ^= MULT[y&1];
        }
        for (int i = 227; i < 623; ++ i) {
            unsigned int y = (MT[i] & 0x8000000UL) + (MT[i+1] & 0x7FFFFFFFUL);
            MT[i] = MT[i-227] ^ (y >> 1);
            MT[i] ^= MULT[y&1];
        }
        unsigned int y = (MT[623] & 0x8000000UL) + (MT[0] & 0x7FFFFFFFUL);
        MT[623] = MT[623-227] ^ (y >> 1);
        MT[623] ^= MULT[y&1];
    }

    unsigned int rand() {
        if (index == 0) {
            generate();
        }

        unsigned int y = MT[index];
        y ^= y >> 11;
        y ^= y << 7  & 2636928640UL;
        y ^= y << 15 & 4022730752UL;
        y ^= y >> 18;
        index = index == 623 ? 0 : index + 1;
        return y;
    }

    int next(int x) { // [0, x)
        return rand() % x;
    }

    int next(int a, int b) { // [a, b)
        return a + (rand() % (b - a));
    }

    double nextDouble() { // (0, 1)
        return (rand() + 0.5) * (1.0 / 4294967296.0);
    }
};

static vector<RandomNumberGenerator> rng;

void initialize()
{
    int nthread = omp_get_max_threads();
//cerr << "# of threads = " << nthread << endl;
    rng.resize(nthread);
    RandomNumberGenerator seeds;
    seeds.init(19910724);
    for (int i = 0; i < nthread; ++ i) {
        rng[i].init(seeds.rand());
    }
}
}

#endif

#ifndef __UTILS_H__
#define __UTILS_H__

#include "omp.h"

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cctype>
#include <cmath>
#include <cassert>
#include <iostream>
#include <algorithm>
#include <string>
#include <vector>
#include <sstream>
#include <map>
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <mutex>
using namespace std;

#define FOR(i,a) for (__typeof((a).begin()) i = (a).begin(); i != (a).end(); ++ i)

#define PATTERN_CHUNK_SIZE 10
#define SENTENCE_CHUNK_SIZE 5
#define POINT_CHUNK_SIZE 5

const int SUFFIX_MASK = (1 << 20) - 1; // should be 2^k - 1
mutex separateMutex[SUFFIX_MASK + 1];

const double EPS = 1e-8;

/*! \brief return a real numer uniform in (0,1) */
inline double next_double2(){
    return (static_cast<double>( rand() ) + 1.0 ) / (static_cast<double>(RAND_MAX) + 2.0);
}

/*! \brief return  x~N(0,1) */
inline double sample_normal(){
	double x,y,s;
	do{
		x = 2 * next_double2() - 1.0;
		y = 2 * next_double2() - 1.0;
		s = x*x + y*y;
	}while( s >= 1.0 || s == 0.0 );

	return x * sqrt( -2.0 * log(s) / s ) ;
}

inline bool myAssert(bool flg, string msg)
{
	if (!flg) {
		cerr << msg << endl;
		// exit(-1);
	}
	return flg;
}

inline int sign(double x)
{
	return x < -EPS ? -1 : x > EPS;
}

inline string replaceAll(const string &s, const string &from, const string &to)
{
    string ret = "";
    for (size_t i = 0; i < s.size(); ++ i) {
        bool found = true;
        for (size_t offset = 0; offset < from.size() && found; ++ offset) {
            found &= i + offset < s.size() && s[i + offset] == from[offset];
        }
        if (found) {
            ret += to;
            i += from.size() - 1;
        } else {
            ret += s[i];
        }
    }
    return ret;
}

inline double sqr(double x)
{
    return x * x;
}

template<class T>
inline void fromString(const string &s, T &x)
{
	stringstream in(s);
	in >> x;
}

inline string tolower(const string &a)
{
	string ret = a;
	for (size_t i = 0; i < ret.size(); ++ i) {
		ret[i] = tolower(ret[i]);
	}
	return ret;
}

const int MAX_LENGTH = 100000000;

char line[MAX_LENGTH + 1];

inline bool getLine(FILE* in)
{
	bool hasNext = fgets(line, MAX_LENGTH, in);
	int length = strlen(line);
	while (length > 0 && (line[length - 1] == '\n' || line[length - 1] == '\r')) {
		-- length;
	}
	line[length] = 0;
	return hasNext;
}

inline FILE* tryOpen(const string &filename, const string &param)
{
	FILE* ret = fopen(filename.c_str(), param.c_str());
	if (ret == NULL) {
		cerr << "[Warning] failed to open " << filename  << " under parameters = " << param << endl;
	}
	return ret;
}

inline vector<string> splitBy(const string &line, char sep)
{
	vector<string> tokens;
	string token = "";
	for (size_t i = 0; i < line.size(); ++ i) {
		if (line[i] == sep) {
		    if (token != "") {
    			tokens.push_back(token);
			}
			token = "";
		} else {
			token += line[i];
		}
	}
	if (token != "") {
    	tokens.push_back(token);
	}
	return tokens;
}

namespace Binary
{
    template<class T>
    inline void write(FILE* out, const T& x) {
		fwrite(&x, sizeof(x), 1, out);
	}

    template<class T>
	inline void read(FILE* in, T &size) {
		fread(&size, sizeof(size), 1, in);
	}

    inline void write(FILE* out, const string &s) {
		write(out, s.size());
		if (s.size() > 0) {
			fwrite(&s[0], sizeof(char), s.size(), out);
		}
	}

	inline void read(FILE* in, string &s) {
		size_t size;
		read(in, size);
		s.resize(size);
		if (size > 0) {
			fread(&s[0], sizeof(char), size, in);
		}
	}
}

#endif

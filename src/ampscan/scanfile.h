// scanfile.h -- the run description: which card, which variable to scan, which values to hold fixed.
//
//   card        ../cards/sm.slha          # paths are relative to this file
//   mudim       29756.25                  # renormalisation scale mu^2 handed to the backend
//   scan  s     linspace  1000  600000  300      # variable, linspace|logspace, first, last, points
//   set   t     -50.0                     # a fixed value (beats the card)
//   amplitudes  vacpol_fermion bubble_unequal    # optional; default: every amplitude
//
// The 'amplitudes' entry is as long as you like:
//   * the line may be continued: end it with a backslash (the last character of the line, a comment may follow)
//         amplitudes  vacpol_fermion  vacpol_smp  (backslash)
//                     bubble_unequal
//   * it may appear several times; the lists are added up (they do not replace each other)
//   * an entry can be a wildcard (vacpol_*), 'all' (the whole amplitude repository), -NAME to leave one out
//     (see ampselect.h), or @FILE: a text file with one or more names per line (# comments allowed; path relative to
//     this scan file)
//
// Where an input comes from:  the scan variable, or a 'set' line. Everything else an amplitude uses is read from
// the card through the SLHA[...] entries of the model files -- those were bound when the code was generated.
#pragma once
#include <cmath>
#include <filesystem>
#include <fstream>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>
#include "text.h"

namespace ampflow {

struct ScanSpec {
    std::string variable, kind;      // kind: "linspace" or "logspace"
    double lo = 0, hi = 0;
    int n = 0;
};

struct RunConfig {
    std::string name;                // file stem; also the name of the output folder
    std::string card;                // resolved path
    double mudim = 1.0;
    ScanSpec scan;
    std::map<std::string, double> fixed;
    std::vector<std::string> amplitudes;      // entries of all 'amplitudes' lines, in order (see ampselect.h); empty = all
};

// One logical line: physical lines joined while they end in a backslash (a '#' comment may follow the backslash).
// 'lineNo' counts physical lines read so far.
inline bool readLogicalLine(std::istream& in, std::string& out, std::size_t& lineNo) {
    out.clear();
    std::string line;
    bool any = false;
    while (std::getline(in, line)) {
        ++lineNo;
        any = true;
        std::string body = text::stripComment(line);
        while (!body.empty() && (body.back() == ' ' || body.back() == '\t' || body.back() == '\r')) body.pop_back();
        if (!body.empty() && body.back() == '\\') { body.pop_back(); out += body + " "; continue; }
        out += body;
        return true;
    }
    return any;                                       // a dangling backslash on the last line just ends the entry
}

// Names listed in a file given as '@file'.
inline void readNameList(const std::filesystem::path& file, const std::string& at, std::vector<std::string>& into) {
    std::ifstream f(file);
    if (!f) throw std::runtime_error(at + "cannot open amplitude list '" + file.string() + "'");
    std::string line;
    while (std::getline(f, line))
        for (const std::string& tok : text::split(text::stripComment(line))) {
            if (tok[0] == '@') throw std::runtime_error(at + "'" + file.string() + "': an amplitude list cannot include another list");
            into.push_back(tok);
        }
}

inline RunConfig parseScanStream(std::istream& in, const std::string& origin, const std::filesystem::path& baseDir,
                                 const std::string& name) {
    namespace fs = std::filesystem;
    RunConfig cfg;
    cfg.name = name;
    auto resolve = [&](const std::string& p) { return (fs::path(p).is_absolute() ? fs::path(p) : baseDir / p).lexically_normal().string(); };

    std::string line;
    std::size_t lineNo = 0;
    while (true) {
        const std::size_t startLine = lineNo + 1;
        if (!readLogicalLine(in, line, lineNo)) break;
        const auto t = text::split(line);
        if (t.empty()) continue;
        const std::string at = origin + ":" + std::to_string(startLine) + ": ";
        auto number = [&](const std::string& s) {
            const auto v = text::toDouble(s);
            if (!v) throw std::runtime_error(at + "'" + s + "' is not a number");
            return *v;
        };
        const std::string& key = t[0];
        if (key == "card" && t.size() == 2)          cfg.card = resolve(t[1]);
        else if (key == "bindings")
            throw std::runtime_error(at + "'bindings' no longer exists: symbols are defined in model files (models/*.model) "
                                          "when the code is generated");
        else if (key == "mudim" && t.size() == 2)    cfg.mudim = number(t[1]);
        else if (key == "set" && t.size() == 3)      cfg.fixed[t[1]] = number(t[2]);
        else if (key == "amplitudes" && t.size() >= 2) {          // adds to what earlier 'amplitudes' lines gave
            for (std::size_t i = 1; i < t.size(); ++i) {
                if (t[i][0] == '@' && t[i].size() > 1) readNameList(resolve(t[i].substr(1)), at, cfg.amplitudes);
                else cfg.amplitudes.push_back(t[i]);
            }
        }
        else if (key == "scan" && t.size() == 6) {
            if (!cfg.scan.variable.empty()) throw std::runtime_error(at + "only one 'scan' line is supported");
            cfg.scan.variable = t[1];
            cfg.scan.kind = t[2];
            if (cfg.scan.kind != "linspace" && cfg.scan.kind != "logspace")
                throw std::runtime_error(at + "scan kind must be linspace or logspace");
            cfg.scan.lo = number(t[3]);
            cfg.scan.hi = number(t[4]);
            const auto n = text::toInt(t[5]);
            if (!n || *n < 2) throw std::runtime_error(at + "the number of scan points must be an integer >= 2");
            cfg.scan.n = *n;
            if (cfg.scan.kind == "logspace" && (cfg.scan.lo <= 0 || cfg.scan.hi <= 0))
                throw std::runtime_error(at + "logspace needs positive endpoints");
        } else {
            throw std::runtime_error(at + "cannot understand '" + text::split(text::stripComment(line))[0] +
                                     "' here (keywords: card, mudim, scan, set, amplitudes)");
        }
    }
    if (cfg.card.empty())         throw std::runtime_error(origin + ": missing 'card' line");
    if (cfg.scan.variable.empty()) throw std::runtime_error(origin + ": missing 'scan' line");
    return cfg;
}

inline RunConfig parseScanFile(const std::string& path) {
    std::ifstream in(path);
    if (!in) throw std::runtime_error("cannot open scan file '" + path + "'");
    const std::filesystem::path p(path);
    return parseScanStream(in, path, p.parent_path(), p.stem().string());
}

inline std::vector<double> scanPoints(const ScanSpec& s) {
    std::vector<double> v(static_cast<std::size_t>(s.n));
    for (int i = 0; i < s.n; ++i) {
        const double t = static_cast<double>(i) / (s.n - 1);
        v[static_cast<std::size_t>(i)] = s.kind == "linspace" ? s.lo + (s.hi - s.lo) * t : s.lo * std::pow(s.hi / s.lo, t);
    }
    v.back() = s.hi;                                  // exact last point
    return v;
}

}  // namespace ampflow

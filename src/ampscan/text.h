// text.h -- tiny string helpers shared by the card, binding and scan-file parsers.
#pragma once
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

namespace ampflow::text {

inline std::string upper(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
    return s;
}

inline std::string stripComment(const std::string& line) { return line.substr(0, line.find('#')); }

inline std::vector<std::string> split(const std::string& s) {      // on whitespace
    std::istringstream in(s);
    std::vector<std::string> out;
    for (std::string tok; in >> tok;) out.push_back(tok);
    return out;
}

// "1.5", "-2E-3", ".5" and Fortran-style "1.0D+02". Rejects anything else (also nan/inf).
inline std::optional<double> toDouble(std::string tok) {
    if (tok.empty() || std::string("+-.0123456789").find(tok[0]) == std::string::npos) return std::nullopt;
    for (char& c : tok) if (c == 'd' || c == 'D') c = 'E';
    char* end = nullptr;
    const double v = std::strtod(tok.c_str(), &end);
    if (*end != '\0' || !std::isfinite(v)) return std::nullopt;
    return v;
}

inline std::optional<int> toInt(const std::string& tok) {
    if (tok.empty()) return std::nullopt;
    char* end = nullptr;
    const long v = std::strtol(tok.c_str(), &end, 10);
    if (*end != '\0') return std::nullopt;
    return static_cast<int>(v);
}

// Shell-style wildcard match: '*' = any run of characters, '?' = any one character. Whole-string match.
inline bool globMatch(const std::string& pat, const std::string& s) {
    std::size_t p = 0, i = 0, star = std::string::npos, mark = 0;
    while (i < s.size()) {
        if (p < pat.size() && (pat[p] == '?' || pat[p] == s[i])) { ++p; ++i; }
        else if (p < pat.size() && pat[p] == '*') { star = p++; mark = i; }
        else if (star != std::string::npos) { p = star + 1; i = ++mark; }
        else return false;
    }
    while (p < pat.size() && pat[p] == '*') ++p;
    return p == pat.size();
}

inline bool hasGlob(const std::string& s) { return s.find_first_of("*?") != std::string::npos; }

}  // namespace ampflow::text

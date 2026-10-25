// ampselect.h -- turns the 'amplitudes' entries of a scan file (or -a options) into a list of amplitude names.
//
// An entry is, in order of precedence:
//   NAME          exactly one amplitude of the repository
//   all           every amplitude of the repository (same as '*'; also 'repository')
//   PATTERN       a wildcard: '*' any run of characters, '?' any one character     vacpol_*   box_?
//   -NAME, !NAME  take this name / pattern OUT of what has been selected so far     -tadpole_*
//                 (an exclusion that matches nothing is not an error, so one scan file can serve workspaces with different amplitudes)
// Entries are processed left to right, so "all -tadpole_top_toy" means everything except that one. If there are only
// exclusions, they apply to the whole repository. Duplicates are dropped; the result keeps the order of the first mention
// (a wildcard or 'all' adds its matches in repository order).
#pragma once
#include <algorithm>
#include <string>
#include <vector>
#include "text.h"

namespace ampflow {

inline std::string joinNames(const std::vector<std::string>& v) {
    std::string out;
    for (std::size_t i = 0; i < v.size(); ++i) out += (i ? ", " : "") + v[i];
    return out;
}

// 'available': the amplitude names of the repository. On a problem returns {} and sets 'error'.
inline std::vector<std::string> expandAmplitudeNames(const std::vector<std::string>& available,
                                                      const std::vector<std::string>& entries, std::string& error) {
    auto has = [](const std::vector<std::string>& v, const std::string& n) { return std::find(v.begin(), v.end(), n) != v.end(); };
    std::vector<std::string> out;
    auto exact = [&](const std::string& e) { return has(available, e); };

    // only exclusions -> start from the whole repository
    const bool anyInclude = std::any_of(entries.begin(), entries.end(), [&](const std::string& e) {
        return exact(e) || !(e.size() > 1 && (e[0] == '-' || e[0] == '!')); });
    if (!anyInclude) out = available;

    for (const std::string& e : entries) {
        const bool exclude = !exact(e) && e.size() > 1 && (e[0] == '-' || e[0] == '!');
        const std::string pat = exclude ? e.substr(1) : e;
        const bool everything = pat == "all" || pat == "repository";
        std::vector<std::string> hit;
        if (exact(pat))                          hit.push_back(pat);
        else if (everything)                     hit = available;
        else if (text::hasGlob(pat)) {
            for (const std::string& a : available) if (text::globMatch(pat, a)) hit.push_back(a);
            if (hit.empty() && !exclude) { error = "'" + e + "' matches no amplitude; available: " + joinNames(available); return {}; }
        } else if (!exclude) {
            error = "unknown amplitude '" + pat + "'; available: " + joinNames(available);
            return {};
        }
        if (exclude) out.erase(std::remove_if(out.begin(), out.end(), [&](const std::string& n) { return has(hit, n); }), out.end());
        else for (const std::string& h : hit) if (!has(out, h)) out.push_back(h);
    }
    return out;
}

}  // namespace ampflow

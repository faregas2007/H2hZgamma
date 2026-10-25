#include "runner.h"

#include <cmath>
#include <iostream>

namespace ampflow {

namespace {
struct Source { enum Kind { Scan, Fixed, Card } kind; double value; };
}

std::string joined(const std::vector<std::string>& v, const char* sep) {
    std::string s;
    for (std::size_t i = 0; i < v.size(); ++i) s += (i ? sep : "") + v[i];
    return s;
}

std::string where(const SlhaRef& r) {
    std::string s = r.block + "[";
    for (std::size_t i = 0; i < r.key.size(); ++i) s += (i ? "," : "") + std::to_string(r.key[i]);
    return s + "]";
}

std::vector<std::string> readSlha(const Amplitude& amp, const SlhaCard& card, std::vector<double>& values) {
    std::vector<std::string> missing;
    values.assign(amp.slha.size(), 0.0);
    for (std::size_t i = 0; i < amp.slha.size(); ++i) {
        const auto v = card.get(amp.slha[i].block, amp.slha[i].key);
        if (v) values[i] = *v; else missing.push_back(where(amp.slha[i]));
    }
    return missing;
}

// Returns false (after printing why) if the amplitude cannot be evaluated; fills `rows` otherwise.
bool runAmplitude(const Amplitude& amp, const RunConfig& cfg, const SlhaCard& card, Backend& backend,
                  std::vector<Row>& rows, CsvMeta& meta) {
    // 1. inputs: the scan variable or a 'set' line
    std::vector<double> fixed(amp.inputs.size(), 0.0);
    std::vector<std::string> unset;
    int scanAt = -1;
    for (std::size_t j = 0; j < amp.inputs.size(); ++j) {
        if (amp.inputs[j] == cfg.scan.variable) { scanAt = static_cast<int>(j); continue; }
        const auto f = cfg.fixed.find(amp.inputs[j]);
        if (f != cfg.fixed.end()) fixed[j] = f->second; else unset.push_back(amp.inputs[j]);
    }
    // 2. the card
    std::vector<double> slha;
    const std::vector<std::string> missing = readSlha(amp, card, slha);

    if (!unset.empty())
        std::cerr << "ampscan: " << amp.name << ": no value for input " << joined(unset)
                  << "  (scan it, or add a 'set' line to the scan file)\n";
    if (!missing.empty())
        std::cerr << "ampscan: " << amp.name << ": the card has no " << joined(missing) << "\n";
    if (!unset.empty() || !missing.empty()) return false;

    // 3. evaluate at Delta = 0, 1, 2
    const std::vector<double> xs = scanPoints(cfg.scan);
    std::vector<std::complex<double>> val[3];
    std::vector<double> input = fixed;
    for (int d = 0; d < 3; ++d) {
        backend.setDelta(d);
        val[d].resize(xs.size());
        for (std::size_t i = 0; i < xs.size(); ++i) {
            if (scanAt >= 0) input[static_cast<std::size_t>(scanAt)] = xs[i];
            try { val[d][i] = amp.eval(Args{input.data(), slha.data(), static_cast<double>(d), cfg.mudim}); }
            catch (const std::exception& e) {
                std::cerr << "ampscan: " << amp.name << ": at " << cfg.scan.variable << " = " << xs[i] << ": " << e.what() << "\n";
                return false;
            }
        }
    }
    backend.setDelta(0);

    // 4. rows; and the linearity check
    std::size_t nonlinear = 0;
    rows.clear();
    for (std::size_t i = 0; i < xs.size(); ++i) {
        rows.push_back({xs[i], val[0][i], val[1][i] - val[0][i]});
        const double curvature = std::abs(val[2][i] - 2.0 * val[1][i] + val[0][i]);
        const double size = std::abs(val[0][i]) + std::abs(val[1][i]) + std::abs(val[2][i]);
        if (curvature > 1e-9 * size) ++nonlinear;
    }
    if (nonlinear)
        std::cerr << "ampscan: warning: " << amp.name << " is not linear in Delta at " << nonlinear
                  << " point(s); the 're/im_div' columns are then only A(Delta=1) - A(Delta=0)\n";

    meta.amplitude = amp.name;
    meta.inputs.clear();
    meta.slha.clear();
    for (std::size_t j = 0; j < amp.inputs.size(); ++j)
        if (static_cast<int>(j) != scanAt) meta.inputs.emplace_back(amp.inputs[j], fixed[j]);
    for (std::size_t i = 0; i < amp.slha.size(); ++i) meta.slha.emplace_back(where(amp.slha[i]), slha[i]);
    return true;
}

}  // namespace ampflow

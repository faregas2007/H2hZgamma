// csvout.h -- the amplitude data format.
//
// One CSV per amplitude. '#' lines carry the provenance (pandas: read_csv(..., comment='#')),
// then a header and one row per scan point:
//
//   <scan variable>,re_finite,im_finite,re_div,im_div
//
//   finite : the amplitude at Delta = 0
//   div    : the coefficient of Delta (Delta = 1/eps - gamma_E + ln 4pi), i.e. the UV pole
//            amplitude = finite + Delta * div      (one-loop amplitudes are linear in Delta)
#pragma once
#include <complex>
#include <cstdio>
#include <fstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace ampflow {

struct CsvMeta {
    std::string amplitude, backend, scanDescription;
    double mudim = 1.0;
    std::string models;                                           // model files + hashes the code was generated with
    std::vector<std::pair<std::string, double>> inputs;           // fixed inputs (the 'set' lines) used
    std::vector<std::pair<std::string, double>> slha;             // card entries read, "MASS[24]" -> value
};

struct Row { double x; std::complex<double> finite, div; };

inline std::string num(double v, const char* fmt = "%.12e") {
    char buf[64];
    std::snprintf(buf, sizeof buf, fmt, v);
    return buf;
}

inline void writeCsv(const std::string& path, const CsvMeta& m, const std::string& xName, const std::vector<Row>& rows) {
    std::ofstream out(path);
    if (!out) throw std::runtime_error("cannot write '" + path + "'");
    out << "# ampflow-csv 1\n"
        << "# amplitude: " << m.amplitude << "\n"
        << "# backend: " << m.backend << "\n"
        << "# scan: " << m.scanDescription << "\n"
        << "# mudim: " << num(m.mudim, "%.17g") << "\n"
        << "# models: " << m.models << "\n"
        << "# inputs:";
    for (const auto& [k, v] : m.inputs) out << " " << k << "=" << num(v, "%.17g");
    out << "\n# slha:";
    for (const auto& [k, v] : m.slha) out << " " << k << "=" << num(v, "%.17g");
    out << "\n# columns: " << xName << " = scanned variable; re/im_finite = amplitude at Delta=0; "
        << "re/im_div = coefficient of Delta (UV pole)\n";
    out << xName << ",re_finite,im_finite,re_div,im_div\n";
    for (const Row& r : rows)
        out << num(r.x) << "," << num(r.finite.real()) << "," << num(r.finite.imag()) << ","
            << num(r.div.real()) << "," << num(r.div.imag()) << "\n";
}

}  // namespace ampflow

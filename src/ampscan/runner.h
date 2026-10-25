// runner.h -- evaluate ONE amplitude along a scan.
//
// What an amplitude needs was fixed when its code was generated (symbols resolved against the model files):
//   inputs : free symbols (s, t, ...)  -> the scan variable or a 'set' line of the scan file
//   slha   : card entries (MASS[24], ...) -> the SLHA card
// So there is no binding step here: check the card, then evaluate at Delta = 0, 1, 2 (Delta = 1/eps - gamma_E + ln 4pi).
//   finite = A(0),   div = A(1) - A(0)        (A(2) only checks that the amplitude is linear in Delta)
#pragma once
#include <string>
#include <vector>
#include "ampflow/amplitude.h"
#include "backend.h"
#include "csvout.h"
#include "scanfile.h"
#include "slha.h"

namespace ampflow {

std::string joined(const std::vector<std::string>& v, const char* sep = ", ");
std::string where(const SlhaRef& r);                                                // "MASS[24]"

// Reads every card entry the amplitude needs; returns the ones the card lacks.
std::vector<std::string> readSlha(const Amplitude& amp, const SlhaCard& card, std::vector<double>& values);

// Fills `rows` and `meta`. Returns false (after printing why on stderr) if the amplitude cannot be evaluated.
bool runAmplitude(const Amplitude& amp, const RunConfig& cfg, const SlhaCard& card, Backend& backend,
                  std::vector<Row>& rows, CsvMeta& meta);

}  // namespace ampflow

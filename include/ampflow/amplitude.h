// amplitude.h -- what every generated amplitude looks like to the runner.
//
// fc2lt turns each amplitudes/NAME.m (plus the model files) into a header that defines
//     ampgen::NAME::eval(const Args&)        the amplitude as a plain C++ function
//     ampgen::NAME::descriptor()             an Amplitude (below): the function plus WHAT IT NEEDS, by name
// and CMake collects all descriptors into registry() (see src/registry.cpp.in).
//
// "What it needs" is fixed when the code is generated (symbols were resolved against the model then):
//   inputs : free symbols the runner supplies at every scan point  (s, t, ...)
//   slha   : SLHA card entries it reads                             (MASS[24], SMINPUTS[1], ...)
// The runner checks the card against `slha` before evaluating anything.
#pragma once
#include <complex>
#include <functional>
#include <string>
#include <vector>

namespace ampflow {

struct SlhaRef {
    std::string block;                 // upper case
    std::vector<int> key;
};

// The values handed to eval(): arrays ordered like Amplitude::inputs / Amplitude::slha, plus two runner values.
struct Args {
    const double* input;
    const double* slha;
    double delta;                      // Delta = 1/eps - gamma_E + ln 4pi, as set in the backend (Runner[Delta])
    double mu2;                        // the renormalisation scale mu^2   (Runner[Mu2])
};

struct Amplitude {
    std::string name;                                          // file stem of the .m file
    std::vector<std::string> inputs;                           // symbol keys exactly as written, e.g. s or SMP["m_t"]
    std::vector<SlhaRef> slha;                                 // card entries needed
    std::function<std::complex<double>(const Args&)> eval;
};

// All amplitudes found in the amplitude directory at configure time (defined in the generated registry.cpp).
const std::vector<Amplitude>& registry();

// The model files the amplitudes were generated with, "sm.model(1a2b3c4d) custom.model(...)": name + content hash.
const char* modelInfo();

}  // namespace ampflow

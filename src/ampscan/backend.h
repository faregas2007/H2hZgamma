// backend.h -- the one place where the loop-integral library is initialised and configured.
// "clooptools.h" is LoopTools' own header (found or built by cmake/AmpflowBackend.cmake).
#pragma once
#include "clooptools.h"

#ifndef AMPFLOW_BACKEND_NAME
#define AMPFLOW_BACKEND_NAME "unknown"
#endif

namespace ampflow {

class Backend {
public:
    explicit Backend(double mudim) { ltini(); setmudim(mudim); setdelta(0.0); }
    ~Backend() { ltexi(); }
    Backend(const Backend&) = delete;
    Backend& operator=(const Backend&) = delete;

    // Delta = 1/eps - gamma_E + ln(4 pi). LoopTools caches results, so drop the cache when it changes.
    void setDelta(double d) { setdelta(d); clearcache(); }

    static const char* name() { return AMPFLOW_BACKEND_NAME; }
};

}  // namespace ampflow

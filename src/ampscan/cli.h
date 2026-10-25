// cli.h -- the command line of ampscan, separated from the physics (runner.h).
//
//   ampscan [-o DATA_ROOT] [-a NAME]... SCANFILE       run a scan, write DATA_ROOT/<run>/<amplitude>.csv
//   ampscan --check CARD [-a NAME]...                   does CARD hold every entry the amplitudes read?
//   ampscan --list                                      the compiled-in amplitudes and what each needs
//
// The registry (the amplitudes compiled into THIS binary) is passed in, so this library does not depend on any
// particular workspace.
#pragma once
#include <vector>
#include "ampflow/amplitude.h"

namespace ampflow {

int runCli(int argc, char** argv, const std::vector<Amplitude>& registry, const char* modelInfo);

}  // namespace ampflow

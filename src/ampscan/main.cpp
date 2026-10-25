// ampscan -- the runner of ONE workspace: this file is compiled once per workspace, together with that
// workspace's generated registry (see cmake/AmpflowWorkspace.cmake).
#include "ampflow/amplitude.h"
#include "cli.h"

int main(int argc, char** argv) {
    return ampflow::runCli(argc, argv, ampflow::registry(), ampflow::modelInfo());
}

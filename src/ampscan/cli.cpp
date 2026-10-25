#include "cli.h"

#include <filesystem>
#include <iostream>
#include "ampselect.h"
#include "runner.h"

namespace fs = std::filesystem;

namespace ampflow {

namespace {

const char* const kUsage =
    "usage: ampscan [-o DATA_ROOT] [-a NAME]... SCANFILE\n"
    "       ampscan --check CARD [-a NAME]...\n"
    "       ampscan --list\n"
    "  -o DATA_ROOT  where the run folder is created (default: data)\n"
    "  -a NAME       only this amplitude (repeatable; overrides the 'amplitudes' lines; NAME may be a wildcard like 'vacpol_*',\n"
    "                'all', or -NAME to leave one out)\n"
    "  --check CARD  report SLHA entries the compiled-in amplitudes need but CARD lacks\n"
    "  --list        print the compiled-in amplitudes and what each needs\n";

std::vector<const Amplitude*> select(const std::vector<Amplitude>& registry,
                                      const std::vector<std::string>& wanted, std::string& error) {
    std::vector<const Amplitude*> out;
    if (wanted.empty()) {
        for (const Amplitude& a : registry) out.push_back(&a);
        return out;
    }
    std::vector<std::string> available;
    for (const Amplitude& a : registry) available.push_back(a.name);
    const auto names = expandAmplitudeNames(available, wanted, error);      // names, wildcards, 'all', -exclusions
    if (!error.empty()) { error += std::string(" (backend '") + Backend::name() + "')"; return {}; }
    for (const std::string& n : names)
        out.push_back(&*std::find_if(registry.begin(), registry.end(), [&](const Amplitude& a) { return a.name == n; }));
    return out;
}

}  // namespace

int runCli(int argc, char** argv, const std::vector<Amplitude>& registry, const char* modelInfo) {
    std::string scanPath, outRoot = "data", checkCard;
    std::vector<std::string> only;
    bool list = false;
    for (int i = 1; i < argc; ++i) {
        const std::string a = argv[i];
        if (a == "-h" || a == "--help") { std::cout << kUsage; return 0; }
        else if (a == "--list") list = true;
        else if (a == "--check" && i + 1 < argc) checkCard = argv[++i];
        else if (a == "-o" && i + 1 < argc) outRoot = argv[++i];
        else if (a == "-a" && i + 1 < argc) only.push_back(argv[++i]);
        else if (!a.empty() && a[0] == '-') { std::cerr << "ampscan: unknown option " << a << "\n" << kUsage; return 2; }
        else scanPath = a;
    }

    if (list) {
        std::cout << "backend: " << Backend::name() << "\nmodels:  " << modelInfo << "\n";
        for (const Amplitude& a : registry) {
            std::cout << a.name << "\n  inputs: " << (a.inputs.empty() ? "-" : joined(a.inputs)) << "\n  card:    ";
            for (std::size_t i = 0; i < a.slha.size(); ++i) std::cout << (i ? ", " : "") << where(a.slha[i]);
            std::cout << (a.slha.empty() ? "-" : "") << "\n";
        }
        if (registry.empty()) std::cout << "(no amplitudes: put FeynCalc exports in amplitudes/*.m and re-run cmake)\n";
        return 0;
    }

    try {
        std::string error;
        const auto selected = select(registry, only, error);
        if (!error.empty()) { std::cerr << "ampscan: " << error << "\n"; return 2; }

        if (!checkCard.empty()) {                                  // --check CARD
            const SlhaCard card = SlhaCard::parseFile(checkCard);
            int bad = 0;
            for (const Amplitude* a : selected) {
                std::vector<double> v;
                const auto missing = readSlha(*a, card, v);
                if (!missing.empty()) { ++bad; std::cerr << a->name << ": missing " << joined(missing) << "\n"; }
            }
            std::cout << (bad ? "card is incomplete for " + std::to_string(bad) + " amplitude(s)" : std::string("card has every entry")) << "\n";
            return bad ? 1 : 0;
        }

        if (scanPath.empty()) { std::cerr << kUsage; return 2; }
        const RunConfig cfg = parseScanFile(scanPath);
        const SlhaCard card = SlhaCard::parseFile(cfg.card);
        std::vector<const Amplitude*> chosen = selected;                 // -a NAME (or everything)
        if (only.empty() && !cfg.amplitudes.empty()) {
            chosen = select(registry, cfg.amplitudes, error);
            if (!error.empty()) { std::cerr << "ampscan: " << error << "\n"; return 2; }
        }
        if (chosen.empty()) { std::cerr << "ampscan: no amplitudes to run (see: ampscan --list)\n"; return 2; }

        const fs::path outDir = fs::path(outRoot) / cfg.name;
        fs::create_directories(outDir);
        fs::copy_file(cfg.card, outDir / "parameters.slha", fs::copy_options::overwrite_existing);
        fs::copy_file(scanPath, outDir / "run.scan", fs::copy_options::overwrite_existing);

        Backend backend(cfg.mudim);
        const std::string scanText = cfg.scan.variable + " " + cfg.scan.kind + " " + num(cfg.scan.lo, "%.12g") + " " +
                                     num(cfg.scan.hi, "%.12g") + " " + std::to_string(cfg.scan.n);
        std::ofstream manifest(outDir / "manifest.csv");
        manifest << "amplitude,file,npoints,scan_variable,first,last,backend\n";

        int failures = 0, written = 0;
        for (const Amplitude* amp : chosen) {
            std::vector<Row> rows;
            CsvMeta meta;
            meta.backend = Backend::name();
            meta.scanDescription = scanText;
            meta.mudim = cfg.mudim;
            meta.models = modelInfo;
            if (!runAmplitude(*amp, cfg, card, backend, rows, meta)) { ++failures; continue; }
            const std::string file = amp->name + ".csv";
            writeCsv((outDir / file).string(), meta, cfg.scan.variable, rows);
            manifest << amp->name << "," << file << "," << rows.size() << "," << cfg.scan.variable << ","
                     << num(cfg.scan.lo, "%.12g") << "," << num(cfg.scan.hi, "%.12g") << "," << Backend::name() << "\n";
            std::cout << "ampscan: " << amp->name << " -> " << (outDir / file).string() << "  (" << rows.size() << " points)\n";
            ++written;
        }
        std::cout << "ampscan: " << written << " amplitude(s) written to " << outDir.string() << "\n";
        return failures ? 1 : 0;
    } catch (const std::exception& e) {
        std::cerr << "ampscan: error: " << e.what() << "\n";
        return 1;
    }
}

}  // namespace ampflow

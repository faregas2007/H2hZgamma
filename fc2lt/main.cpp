// main.cpp -- command line front end:
//   fc2lt [--registry] [--model FILE]... [-f NAME] [-o OUT] [INPUT]
#include <fstream>
#include <iostream>
#include <iterator>
#include "fc2lt.h"

namespace {

const char* const kUsage =
    "usage: fc2lt [--registry] [--model FILE]... [-f NAME] [-o OUT] [INPUT]\n"
    "  Translate FeynCalc output (Mathematica InputForm) into a C++ function using LoopTools.\n"
    "  INPUT        file to read (default or '-': standard input)\n"
    "  --model FILE a model file defining symbols (repeatable; later files override earlier ones)\n"
    "  --registry   emit namespace ampgen::NAME { eval(), descriptor() } for the ampflow runner\n"
    "  -f NAME      name of the generated function (default: amplitude)\n"
    "  -o OUT       write to this file instead of standard output\n"
    "  --tokens     debug: print how the lexer splits the input, then stop\n";

bool isIdentifier(const std::string& s) {
    if (s.empty() || std::isdigit(static_cast<unsigned char>(s[0]))) return false;
    for (char c : s) if (!std::isalnum(static_cast<unsigned char>(c)) && c != '_') return false;
    return true;
}

bool readFile(const std::string& path, std::string& out) {
    std::ifstream in(path);
    if (!in) return false;
    out.assign(std::istreambuf_iterator<char>(in), {});
    return true;
}

}  // namespace

int main(int argc, char** argv) {
    std::string functionName = "amplitude", inputPath = "-", outputPath;
    std::vector<std::string> modelPaths;
    bool dumpTokens = false, registry = false;
    for (int i = 1; i < argc; ++i) {
        const std::string a = argv[i];
        if (a == "-h" || a == "--help") { std::cout << kUsage; return 0; }
        if (a == "--tokens") { dumpTokens = true; continue; }
        if (a == "--registry") { registry = true; continue; }
        if (a == "--model" && i + 1 < argc) { modelPaths.push_back(argv[++i]); continue; }
        if ((a == "-f" || a == "-o") && i + 1 < argc) { (a == "-f" ? functionName : outputPath) = argv[++i]; }
        else if (a.size() > 1 && a[0] == '-') { std::cerr << "fc2lt: unknown option " << a << "\n" << kUsage; return 2; }
        else inputPath = a;
    }
    if (!isIdentifier(functionName)) { std::cerr << "fc2lt: '" << functionName << "' is not a valid C++ name\n"; return 2; }

    std::string source;
    if (inputPath == "-") {
        source.assign(std::istreambuf_iterator<char>(std::cin), {});
    } else if (!readFile(inputPath, source)) {
        std::cerr << "fc2lt: cannot open " << inputPath << "\n";
        return 1;
    }

    try {
        if (dumpTokens) {                                   // one line per token: offset, kind, text
            static const char* const names[] = {"number", "name", "string", "op", "end"};
            for (const auto& tok : fc2lt::Lexer(fc2lt::trimTrailing(source)).run())
                std::cout << tok.pos << "\t" << names[static_cast<int>(tok.kind)] << "\t" << tok.text << "\n";
            return 0;
        }
        fc2lt::Model model;
        for (const std::string& path : modelPaths) {
            std::string text;
            if (!readFile(path, text)) { std::cerr << "fc2lt: cannot open model file " << path << "\n"; return 1; }
            model.addSource(path, text);                    // errors carry the model file's name and text
        }
        const fc2lt::Translation tr = fc2lt::translate(source, modelPaths.empty() ? nullptr : &model);
        const std::string out = registry ? fc2lt::renderRegistered(tr, functionName)
                                         : fc2lt::renderFunction(tr, functionName);
        if (outputPath.empty()) std::cout << out;
        else {
            std::ofstream f(outputPath);
            if (!f) { std::cerr << "fc2lt: cannot write " << outputPath << "\n"; return 1; }
            f << out;
        }
    } catch (const fc2lt::Error& e) {
        std::cerr << fc2lt::describeError(e.inFile(inputPath == "-" ? "<stdin>" : inputPath, source), source);
        return 1;
    } catch (const std::exception& e) {
        std::cerr << "fc2lt: error: " << e.what() << "\n";
        return 1;
    }
    return 0;
}

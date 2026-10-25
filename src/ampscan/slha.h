// slha.h -- reader for SLHA-style parameter cards (SUSY Les Houches Accord format).
//
//   BLOCK MASS                      # block name, case-insensitive
//        6     1.725000E+02         # <index> <value>      (value may use D exponents)
//   BLOCK SMINPUTS
//        1     1.279520E+02
//   BLOCK HMIX Q= 1.0E+03           # anything after the name is ignored
//        1  2  0.5                  # several indices:  <i> <j> <value>
//   DECAY 6 1.35                    # DECAY tables are skipped
//
// Lines that do not fit "<int> ... <int> <number>" (e.g. the text blocks SPINFO / MODSEL strings)
// are ignored; a missing entry is reported later, by name, when something asks for it.
#pragma once
#include <fstream>
#include <map>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>
#include "text.h"

namespace ampflow {

class SlhaCard {
public:
    static SlhaCard parse(std::istream& in) {
        SlhaCard card;
        std::string line, block;
        while (std::getline(in, line)) {
            const auto toks = text::split(text::stripComment(line));
            if (toks.empty()) continue;
            const std::string head = text::upper(toks[0]);
            if (head == "BLOCK") {
                if (toks.size() < 2) throw std::runtime_error("SLHA: BLOCK line without a name");
                block = text::upper(toks[1]);
                card.blocks_[block];                                   // the block exists even if empty
            } else if (head == "DECAY") {
                block.clear();                                         // skip the decay table that follows
            } else if (!block.empty()) {
                const auto value = text::toDouble(toks.back());
                if (!value) continue;
                std::vector<int> key;
                bool ok = true;
                for (std::size_t i = 0; i + 1 < toks.size() && ok; ++i) {
                    const auto k = text::toInt(toks[i]);
                    if (k) key.push_back(*k); else ok = false;
                }
                if (ok) card.blocks_[block][key] = *value;
            }
        }
        return card;
    }

    static SlhaCard parseFile(const std::string& path) {
        std::ifstream in(path);
        if (!in) throw std::runtime_error("cannot open SLHA card '" + path + "'");
        return parse(in);
    }

    std::optional<double> get(const std::string& block, const std::vector<int>& key) const {
        const auto b = blocks_.find(text::upper(block));
        if (b == blocks_.end()) return std::nullopt;
        const auto e = b->second.find(key);
        if (e == b->second.end()) return std::nullopt;
        return e->second;
    }

    bool hasBlock(const std::string& block) const { return blocks_.count(text::upper(block)) > 0; }

private:
    std::map<std::string, std::map<std::vector<int>, double>> blocks_;
};

}  // namespace ampflow

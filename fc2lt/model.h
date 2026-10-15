// model.h -- model files: the one place where symbols get their meaning.
//
// A model file is written in the SAME language as the amplitudes and read by the SAME lexer and parser:
//
//   (* comment *)
//   Inputs[s, t, u]                       declares symbols the runner supplies per scan point
//   mt     = SLHA[MASS, 6]                a symbol defined by an SLHA card entry
//   alpha  = 1/SLHA[SMINPUTS, 1]          ... or by any expression
//   e      = Sqrt[4 Pi alpha]             derived parameters use other definitions
//   SMP["m_t"] = mt                       FeynCalc atoms can be defined directly
//   SMP["Delta_UV"] = Runner[Delta]       a value the runner provides: Delta (the UV pole parameter) or Mu2
//
// One statement per line (a line continues while brackets are open or it ends in an operator), or ';'-separated.
// Several model files are applied in order; a later file may redefine a symbol of an earlier one,
// but a file may not define the same symbol twice.
#pragma once
#include <map>
#include <set>
#include <string>
#include <vector>
#include "ast.h"
#include "parser.h"

namespace fc2lt {

struct Definition {
    NodePtr tree;
    std::string file, source;     // where it came from (for error messages)
    std::size_t shift = 0;        // offset of its statement inside `source`
};

struct StatementText { std::string text; std::size_t offset; };

// Splits a model file into statements without looking inside (* comments *), "strings" or brackets.
inline std::vector<StatementText> splitStatements(const std::string& s) {
    std::vector<StatementText> out;
    std::size_t start = 0, depth = 0;
    int comment = 0;
    bool inString = false;
    auto flush = [&](std::size_t end) {
        if (end > start) out.push_back({s.substr(start, end - start), start});
    };
    auto lastSignificantIsOperator = [&](std::size_t end) {                 // line continues after + - * / ^ = ,
        for (std::size_t k = end; k > start; --k) {
            const char c = s[k - 1];
            if (std::isspace(static_cast<unsigned char>(c))) continue;
            return std::string("+-*/^=,").find(c) != std::string::npos;
        }
        return false;
    };
    for (std::size_t i = 0; i < s.size(); ++i) {
        const char c = s[i], n = i + 1 < s.size() ? s[i + 1] : '\0';
        if (comment > 0) {
            if (c == '(' && n == '*') { ++comment; ++i; }
            else if (c == '*' && n == ')') { --comment; ++i; }
        } else if (inString) {
            if (c == '\\') ++i; else if (c == '"') inString = false;
        } else if (c == '(' && n == '*') { ++comment; ++i; }
        else if (c == '"') inString = true;
        else if (c == '[' || c == '(') ++depth;
        else if ((c == ']' || c == ')') && depth > 0) --depth;
        else if (c == ';' && depth == 0) { flush(i); start = i + 1; }
        else if (c == '\n' && depth == 0 && !lastSignificantIsOperator(i)) { flush(i); start = i + 1; }
    }
    flush(s.size());
    return out;
}

class Model {
public:
    // Reads one model file. Throws fc2lt::Error located in `file`.
    void addSource(const std::string& file, const std::string& text) {
        std::set<std::string> definedHere;
        sources_.push_back(file);
        for (const StatementText& st : splitStatements(text)) {
            try {
                std::vector<Token> toks = Lexer(st.text).run();
                if (toks.size() == 1) continue;                               // only comments/blank
                const Statement s = Parser(std::move(toks)).parseStatement();
                if (!s.lhs) {
                    declare(*s.rhs);
                } else {
                    const std::string& name = s.lhs->text;
                    if (!definedHere.insert(name).second)
                        throw Error("'" + name + "' is defined twice in this file", s.lhs->pos);
                    defs_[name] = Definition{s.rhs, file, text, st.offset};
                }
            } catch (const Error& e) {
                throw e.inFile(file, text, st.offset);
            }
        }
    }

    const Definition* find(const std::string& name) const {
        const auto it = defs_.find(name);
        return it == defs_.end() ? nullptr : &it->second;
    }
    bool isInput(const std::string& name) const { return inputs_.count(name) > 0; }
    const std::vector<std::string>& sources() const { return sources_; }

    // Every name a user could have meant (for "did you mean ...?").
    std::vector<std::string> knownNames() const {
        std::vector<std::string> v;
        for (const auto& d : defs_) v.push_back(d.first);
        for (const auto& i : inputs_) v.push_back(i);
        return v;
    }

private:
    void declare(const Node& n) {
        if (n.kind != Kind::Call || n.text != "Inputs")
            throw Error("a line without '=' must be Inputs[symbol, ...]", n.pos);
        for (const NodePtr& k : n.kids) {
            if (k->kind != Kind::Symbol) throw Error("Inputs[...] takes symbols only", k->pos);
            inputs_.insert(k->text);
        }
    }

    std::map<std::string, Definition> defs_;
    std::set<std::string> inputs_;
    std::vector<std::string> sources_;
};

}  // namespace fc2lt

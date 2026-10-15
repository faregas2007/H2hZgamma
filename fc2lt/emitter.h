// emitter.h -- stage 3: AST -> C++ expression text.
//
// Two ideas drive this file:
//
//  1. Every sub-expression is returned as an Expr = { code, isComplex }.
//     Tracking "is it complex?" lets us
//       * reject a complex value passed to LoopTools (its arguments are real doubles) at
//         translation time, with the exact position, instead of a cryptic g++ error, and
//       * only wrap things in std::complex where it matters.
//
//  2. Output is fully parenthesised, so C++ precedence can never differ from the AST.
//     Numbers are always emitted as doubles ("4" -> "4.0"), because 1/2 would be 0 in C++.
#pragma once
#include <algorithm>
#include <cctype>
#include <map>
#include <optional>
#include <string>
#include <vector>
#include "ast.h"
#include "tables.h"

namespace fc2lt {

struct Translation {
    std::string body;                 // the C++ expression
    std::vector<std::string> params;  // C++ parameter names (sanitised), in order of first appearance
    std::vector<std::string> symbols; // the same symbols as written in the source (SMP["m_t"], ...): the runner's inputs
    std::vector<SlhaRef> slha;        // SLHA entries read through SLHA[...] (filled in by translate())
    bool usesDelta = false;           // uses Runner[Delta]
    bool usesMu2 = false;             // uses Runner[Mu2]
};

class Emitter {
public:
    Translation run(const NodePtr& root) {
        params_.clear(); symbols_.clear(); origin_.clear();     // an Emitter can be reused
        Expr e = emit(*root);
        Translation t;
        t.body = std::move(e.code);
        t.params = params_;
        t.symbols = symbols_;
        return t;
    }

private:
    struct Expr { std::string code; bool isComplex; };

    // ---- small helpers ---------------------------------------------------------------
    static bool isPlainInteger(const std::string& s) { return s.find_first_of(".e") == std::string::npos; }

    static std::optional<long> asInteger(const Node& n) {
        if (n.kind == Kind::Number && isPlainInteger(n.text) && n.text.size() <= 9) return std::stol(n.text);
        if (n.kind == Kind::Neg) if (auto v = asInteger(*n.kids[0])) return -*v;
        return std::nullopt;
    }
    static bool isHalf(const Node& n) {                     // 0.5  or  1/2
        if (n.kind == Kind::Number) return n.text == "0.5";
        return n.kind == Kind::Div && n.kids[0]->kind == Kind::Number && n.kids[0]->text == "1" &&
               n.kids[1]->kind == Kind::Number && n.kids[1]->text == "2";
    }
    // A C++ name from a source name:  a$b -> a_b,   SMP["g'_W"] -> SMP_gp_W   (collisions are caught in symbol()).
    static std::string sanitize(const std::string& s) {
        std::string out;
        for (char c : s) {
            if (std::isalnum(static_cast<unsigned char>(c))) out += c;
            else if (c == '\'') out += 'p';
            else if (out.empty() || out.back() != '_') out += '_';
        }
        while (!out.empty() && out.back() == '_') out.pop_back();
        if (out.empty() || std::isdigit(static_cast<unsigned char>(out[0]))) out = "x" + out;
        return out;
    }
    static std::string toComplex(const std::string& code) { return "std::complex<double>(" + code + ")"; }

    // ---- dispatcher ------------------------------------------------------------------
    Expr emit(const Node& n) {
        switch (n.kind) {
            case Kind::Number: return {isPlainInteger(n.text) ? n.text + ".0" : n.text, false};
            case Kind::Symbol: return symbol(n);
            case Kind::Slot:   return {n.text, false};                 // slha_0, rt_delta: made by the resolver, always real
            case Kind::String: throw Error("a string is only allowed inside SLHA[...] or an atom such as SMP[\"m_t\"]", n.pos);
            case Kind::Neg:    { Expr x = emit(*n.kids[0]); return {"(-" + x.code + ")", x.isComplex}; }
            case Kind::Add:    return binary(n, " + ");
            case Kind::Sub:    return binary(n, " - ");
            case Kind::Mul:    return binary(n, " * ");
            case Kind::Div:    return binary(n, " / ");
            case Kind::Pow:    return power(n);
            case Kind::Call:   return call(n);
        }
        throw Error("internal error: unknown node kind", n.pos);
    }

    Expr binary(const Node& n, const char* op) {
        Expr l = emit(*n.kids[0]), r = emit(*n.kids[1]);
        return {"(" + l.code + op + r.code + ")", l.isComplex || r.isComplex};
    }

    // Constants map to literals; anything else becomes a `double` parameter.
    Expr symbol(const Node& n) {
        if (const auto* c = tables::lookup(tables::kConstants, n.text)) return {std::string(c->cpp), c->isComplex};
        std::string id = sanitize(n.text);
        for (auto word : tables::kReserved) if (word == id) { id += "_"; break; }
        const auto it = origin_.find(id);
        if (it == origin_.end()) { origin_[id] = n.text; params_.push_back(id); symbols_.push_back(n.text); }
        else if (it->second != n.text)
            throw Error("symbols '" + it->second + "' and '" + n.text + "' both map to the C++ name '" + id + "'", n.pos);
        return {id, false};
    }

    // x^2 -> std::pow(x, 2)  (integer exponent: exact, stays real for real x)
    // x^(1/2) -> sqrt of a complex (no NaN for negative x)
    // anything else -> complex pow
    Expr power(const Node& n) {
        Expr base = emit(*n.kids[0]);
        const Node& ex = *n.kids[1];
        if (auto k = asInteger(ex)) return {"std::pow(" + base.code + ", " + std::to_string(*k) + ")", base.isComplex};
        if (isHalf(ex))             return {"std::sqrt(" + toComplex(base.code) + ")", true};
        Expr e = emit(ex);
        return {"std::pow(" + toComplex(base.code) + ", " + e.code + ")", true};
    }

    // ---- function calls --------------------------------------------------------------
    Expr call(const Node& n) {
        if (const auto* f = tables::lookup(tables::kLoopFuncs, n.text)) {
            if (n.kids.size() != f->argc)
                throw Error(n.text + " needs " + std::to_string(f->argc) + " arguments, got " +
                            std::to_string(n.kids.size()), n.pos);
            return loopCall(n.text, n.kids);
        }
        if (const auto* f = tables::lookup(tables::kMathFuncs, n.text)) {
            if (n.kids.size() != 1) throw Error(n.text + " needs exactly 1 argument", n.pos);
            Expr x = emit(*n.kids[0]);
            const bool cplx = f->result == tables::Result::AlwaysComplex ||
                              (f->result == tables::Result::FollowsArgument && x.isComplex);
            return {std::string(f->cpp) + "(" + (f->castArgToComplex ? toComplex(x.code) : x.code) + ")", cplx};
        }
        throw Error("unsupported function " + n.text + "[...] -- simplify or contract it in FeynCalc first", n.pos);
    }

    // name(a1, a2, ...): LoopTools takes real arguments and returns a complex number.
    Expr loopCall(const std::string& fn, const std::vector<NodePtr>& args) {
        std::string code = fn + "(";
        for (std::size_t i = 0; i < args.size(); ++i) {
            Expr a = emit(*args[i]);                       // emitted in source order, one at a time
            if (a.isComplex)
                throw Error("argument " + std::to_string(i + 1) + " of " + fn +
                            " must be real, but this expression is complex", args[i]->pos);
            code += (i ? ", " : "") + a.code;
        }
        return {code + ")", true};
    }

    std::vector<std::string> params_, symbols_;
    std::map<std::string, std::string> origin_;   // C++ name -> source name
};

}  // namespace fc2lt

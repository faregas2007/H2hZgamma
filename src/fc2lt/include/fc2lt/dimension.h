// dimension.h -- the D -> 4 limit of an amplitude that still carries the dimension D.
//
// FeynCalc results are often left in D dimensions: coefficients such as (D-4)/(D-3) multiply PaVe functions. Those
// functions carry a UV pole, A0[m] = m/eps + ..., B0[...] = 1/eps + ...  (D = 4 - 2 eps), so a coefficient c(D)
// multiplying a pole leaves a finite rational term:
//
//     c(D) F  ->  c(4) F  -  2 c'(4) r_F        r_F = residue of the pole:  A0[m]: m,  B0: 1
//
// (c(4-2eps) = c(4) - 2 eps c'(4), times r/eps.)  Here F is the ordinary LoopTools function (its Delta included).
// C0 and D0 have no UV pole: for them D -> 4 only.
//
// The expression is split as  E = sum_i c_i(D) F_i + c_0(D):  replacing A0[m] -> m t and B0 -> t gives sum c_i r_i t + c_0,
// and the difference between t = 1 and t = 0 isolates  sum c_i(D) r_i.  Its derivative with respect to D, evaluated at D = 4,
// is the correction. D may appear only rationally: not inside the arguments of functions and not in exponents.
//
// Verified by a symbolic run on the D-dimensional photon self-energy (reproduces Denner's formula with its s/3 term).
#pragma once
#include <string>
#include "ast.h"

namespace fc2lt::dimension {

inline NodePtr number(long v, std::size_t pos) {
    NodePtr n = makeNode(Kind::Number, pos, std::to_string(v < 0 ? -v : v));
    return v < 0 ? makeNode(Kind::Neg, pos, "", {n}) : n;
}
inline bool isNumber(const NodePtr& n, const char* text) { return n->kind == Kind::Number && n->text == text; }
inline bool isZero(const NodePtr& n) { return isNumber(n, "0"); }
inline bool isOne(const NodePtr& n)  { return isNumber(n, "1"); }

// Small constructors that drop 0 and 1, so the derivative does not grow needlessly.
inline NodePtr neg(const NodePtr& a) { return isZero(a) ? a : makeNode(Kind::Neg, a->pos, "", {a}); }
inline NodePtr add(const NodePtr& a, const NodePtr& b) {
    if (isZero(a)) return b;
    if (isZero(b)) return a;
    return makeNode(Kind::Add, a->pos, "", {a, b});
}
inline NodePtr sub(const NodePtr& a, const NodePtr& b) {
    if (isZero(b)) return a;
    if (isZero(a)) return neg(b);
    return makeNode(Kind::Sub, a->pos, "", {a, b});
}
inline NodePtr mul(const NodePtr& a, const NodePtr& b) {
    if (isZero(a) || isZero(b)) return number(0, a->pos);
    if (isOne(a)) return b;
    if (isOne(b)) return a;
    return makeNode(Kind::Mul, a->pos, "", {a, b});
}
inline NodePtr div(const NodePtr& a, const NodePtr& b) {
    if (isZero(a)) return a;
    if (isOne(b)) return a;
    return makeNode(Kind::Div, a->pos, "", {a, b});
}
inline NodePtr power(const NodePtr& a, const NodePtr& e) { return makeNode(Kind::Pow, a->pos, "", {a, e}); }

inline bool plainInteger(const NodePtr& n, long& v) {
    if (n->kind == Kind::Number && n->text.find_first_of(".e") == std::string::npos && n->text.size() <= 9) {
        v = std::stol(n->text);
        return true;
    }
    if (n->kind == Kind::Neg && plainInteger(n->kids[0], v)) { v = -v; return true; }
    return false;
}

inline bool contains(const NodePtr& n, const std::string& var) {
    if (n->kind == Kind::Symbol && n->text == var) return true;
    for (const NodePtr& k : n->kids) if (contains(k, var)) return true;
    return false;
}

inline NodePtr replaceSymbol(const NodePtr& n, const std::string& var, const NodePtr& by) {
    if (n->kind == Kind::Symbol && n->text == var) return by;
    if (n->kids.empty()) return n;
    std::vector<NodePtr> kids;
    for (const NodePtr& k : n->kids) kids.push_back(replaceSymbol(k, var, by));
    return makeNode(n->kind, n->pos, n->text, std::move(kids));
}

// D may only appear rationally.
inline void checkRational(const NodePtr& n, const std::string& var) {
    if (n->kind == Kind::Call)
        for (const NodePtr& k : n->kids)
            if (contains(k, var))
                throw Error(var + " appears inside the argument of " + n->text + "[...]; only a rational dependence on " + var +
                            " can be taken to 4 dimensions", n->pos);
    if (n->kind == Kind::Pow && contains(n->kids[1], var))
        throw Error(var + " appears in an exponent; only a rational dependence on " + var + " can be taken to 4 dimensions", n->pos);
    for (const NodePtr& k : n->kids) checkRational(k, var);
}

// d n / d var   (var-dependence is rational by checkRational)
inline NodePtr diff(const NodePtr& n, const std::string& var) {
    if (!contains(n, var)) return number(0, n->pos);
    switch (n->kind) {
        case Kind::Symbol: return number(1, n->pos);
        case Kind::Neg:    return neg(diff(n->kids[0], var));
        case Kind::Add:    return add(diff(n->kids[0], var), diff(n->kids[1], var));
        case Kind::Sub:    return sub(diff(n->kids[0], var), diff(n->kids[1], var));
        case Kind::Mul:    return add(mul(diff(n->kids[0], var), n->kids[1]), mul(n->kids[0], diff(n->kids[1], var)));
        case Kind::Div:    return div(sub(mul(diff(n->kids[0], var), n->kids[1]), mul(n->kids[0], diff(n->kids[1], var))),
                                      power(n->kids[1], number(2, n->pos)));
        case Kind::Pow: {
            const NodePtr& base = n->kids[0];
            const NodePtr& ex = n->kids[1];
            const NodePtr db = diff(base, var);
            long k;
            NodePtr lowered;                                              // base^(ex - 1)
            if (plainInteger(ex, k)) {
                lowered = k - 1 == 0 ? number(1, n->pos) : k - 1 == 1 ? base : power(base, number(k - 1, n->pos));
            } else {
                lowered = power(base, sub(ex, number(1, n->pos)));
            }
            return mul(mul(ex, lowered), db);
        }
        default: throw Error("cannot differentiate this expression with respect to " + var, n->pos);
    }
}

// Pole residues: A0[m] -> m t, B0[...] -> t, C0/D0 -> 0   (t = 1 or 0)
inline NodePtr poleResidues(const NodePtr& n, bool t) {
    if (n->kind == Kind::Call) {
        if (n->text == "A0" && n->kids.size() == 1) return t ? n->kids[0] : number(0, n->pos);
        if (n->text == "B0") return t ? number(1, n->pos) : number(0, n->pos);
        if (n->text == "C0" || n->text == "D0") return number(0, n->pos);
    }
    if (n->kids.empty()) return n;
    std::vector<NodePtr> kids;
    for (const NodePtr& k : n->kids) kids.push_back(poleResidues(k, t));
    return makeNode(n->kind, n->pos, n->text, std::move(kids));
}

// The expression with D -> 4, including the rational terms from (D-4) x pole.
inline NodePtr limitTo4(const NodePtr& e, const std::string& var = "D") {
    if (!contains(e, var)) return e;
    checkRational(e, var);
    const NodePtr four = number(4, e->pos);
    const NodePtr residue = sub(poleResidues(e, true), poleResidues(e, false));      // sum_i c_i(D) r_i
    const NodePtr correction = replaceSymbol(diff(residue, var), var, four);
    return sub(replaceSymbol(e, var, four), mul(number(2, e->pos), correction));
}

}  // namespace fc2lt::dimension

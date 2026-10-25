// tables.h -- everything that is DATA rather than logic.
//
// To support a new function or constant, add one row here; the emitter does not change.
#pragma once
#include <cstddef>
#include <string_view>

namespace fc2lt::tables {

template <class T, std::size_t N>
const T* lookup(const T (&table)[N], std::string_view name) {
    for (const T& row : table) if (row.name == name) return &row;
    return nullptr;
}

// Mathematica constants -> C++ literals (I is the only complex one).
struct Constant { std::string_view name, cpp; bool isComplex; };
inline constexpr Constant kConstants[] = {
    {"I",  "std::complex<double>(0.0, 1.0)", true},
    {"Pi", "3.14159265358979323846",         false},
    {"E",  "2.71828182845904523536",         false},
};

// The LoopTools scalar integrals; names and argument order are the same in FeynCalc and
// LoopTools, so the call is copied through verbatim. `argc` = number of arguments:
//   A0(m)                      B0(p, m1, m2)
//   C0(p1, p2, p1p2, m1, m2, m3)
//   D0(p1, p2, p3, p4, p1p2, p2p3, m1, m2, m3, m4)
// All arguments are real; masses are SQUARED (m^2), exactly as FeynCalc writes them.
struct LoopFunc { std::string_view name; std::size_t argc; };
inline constexpr LoopFunc kLoopFuncs[] = {
    {"A0", 1}, {"B0", 3}, {"C0", 6}, {"D0", 10},
};

// One-argument math functions.
//   castArgToComplex : wrap the argument in std::complex first, so Sqrt[s-4m^2] is a
//                      complex number below threshold instead of NaN.
//   result           : whether the C++ result is complex.
enum class Result { AlwaysComplex, AlwaysReal, FollowsArgument };
struct MathFunc { std::string_view name, cpp; Result result; bool castArgToComplex; bool reciprocal = false; };
inline constexpr MathFunc kMathFuncs[] = {
    {"Sqrt", "std::sqrt", Result::AlwaysComplex,   true},
    {"Log",  "std::log",  Result::AlwaysComplex,   true},
    {"Exp",  "std::exp",  Result::FollowsArgument, false},
    {"Sin",  "std::sin",  Result::FollowsArgument, false},
    {"Cos",  "std::cos",  Result::FollowsArgument, false},
    {"Tan",  "std::tan",  Result::FollowsArgument, false},
    {"Abs",  "std::abs",  Result::AlwaysReal,      false},
    {"Csc",  "std::sin",  Result::FollowsArgument, false, true},     // 1/sin
    {"Sec",  "std::cos",  Result::FollowsArgument, false, true},     // 1/cos
    {"Cot",  "std::tan",  Result::FollowsArgument, false, true},     // 1/tan
    {"ArcTan", "std::atan", Result::FollowsArgument, false},
    {"ArcSin", "std::asin", Result::FollowsArgument, false},          // real argument outside [-1,1]: NaN (Mathematica: complex)
    {"ArcCos", "std::acos", Result::FollowsArgument, false},
};

// Words that cannot be C++ parameter names; a trailing '_' is appended ("int" -> "int_").
inline constexpr std::string_view kReserved[] = {
    "int", "double", "float", "long", "short", "class", "new", "delete", "template", "this",
    "default", "register", "union", "signed", "unsigned", "void", "auto", "char", "bool",
    "do", "if", "else", "for", "while", "switch", "case", "return",
};

// ---------------------------------------------------------------------------------------------------
// Names that wrap a single parameter:  SMP["m_t"], FCGV["MT"], Subscript[m, t].
// The whole expression is ONE symbol (key: SMP["m_t"]); a model file can define it.
inline constexpr std::string_view kAtomHeads[] = {"SMP", "FCGV", "Subscript"};

// ---------------------------------------------------------------------------------------------------
// Unicode and Mathematica named characters, normalised by the lexer. Only ASCII ever reaches the
// generated code. (Hex escapes below, so this file is safe in any editor/encoding; the glyph is in the comment.)
//   Letter   : part of a name        alpha -> "alpha"
//   Constant : a symbol on its own   pi -> Pi, imaginary i -> I
//   Op       : punctuation look-alike
//   Space    : invisible/odd whitespace
enum class AliasKind { Space, Op, Constant, Letter };
struct Alias { std::string_view utf8, ascii; AliasKind kind; };
inline constexpr Alias kAliases[] = {
    {"\xEF\xBB\xBF", "", AliasKind::Space},      // byte-order mark
    {"\xC2\xA0", "", AliasKind::Space},          // U+00A0 no-break space
    {"\xE2\x80\x89", "", AliasKind::Space},      // U+2009 thin space
    {"\xE2\x80\x8B", "", AliasKind::Space},      // U+200B zero-width space
    {"\xE2\x80\xAF", "", AliasKind::Space},      // U+202F narrow no-break space
    {"\xE2\x88\x92", "-", AliasKind::Op},        // U+2212 minus sign
    {"\xC3\x97", "*", AliasKind::Op},            // U+00D7 multiplication sign
    {"\xEF\xBC\x8C", ",", AliasKind::Op},        // U+FF0C fullwidth comma
    {"\xEF\xBC\x88", "(", AliasKind::Op}, {"\xEF\xBC\x89", ")", AliasKind::Op},   // fullwidth ( )
    {"\xEF\xBC\xBB", "[", AliasKind::Op}, {"\xEF\xBC\xBD", "]", AliasKind::Op},   // fullwidth [ ]
    {"\xE2\x85\x88", "I", AliasKind::Constant},  // U+2148 double-struck italic i  (Mathematica ImaginaryI)
    {"\xE2\x85\x87", "E", AliasKind::Constant},  // U+2147 double-struck italic e  (Mathematica ExponentialE)
    {"\xCF\xB5", "epsilon", AliasKind::Letter},   // ϵ
    {"\xCF\x91", "theta", AliasKind::Letter},   // ϑ
    {"\xCF\x95", "phi", AliasKind::Letter},   // ϕ
    {"\xCF\xB0", "kappa", AliasKind::Letter},   // ϰ
    {"\xCF\xB1", "rho", AliasKind::Letter},   // ϱ
    {"\xCF\x82", "sigma", AliasKind::Letter},   // ς
    {"\xC2\xB5", "mu", AliasKind::Letter},   // µ
};

// Greek letters. name = Mathematica's name (\[Alpha] lower case, \[CapitalAlpha] upper case).
// lower case -> "alpha", upper case -> "Alpha"; the exceptions are pi (-> the constant Pi) and capital Pi (-> CapitalPi).
struct Greek { std::string_view name, lower, upper; };
inline constexpr Greek kGreek[] = {
    {"Alpha", "\xCE\xB1", "\xCE\x91"},   // α Α
    {"Beta", "\xCE\xB2", "\xCE\x92"},   // β Β
    {"Gamma", "\xCE\xB3", "\xCE\x93"},   // γ Γ
    {"Delta", "\xCE\xB4", "\xCE\x94"},   // δ Δ
    {"Epsilon", "\xCE\xB5", "\xCE\x95"},   // ε Ε
    {"Zeta", "\xCE\xB6", "\xCE\x96"},   // ζ Ζ
    {"Eta", "\xCE\xB7", "\xCE\x97"},   // η Η
    {"Theta", "\xCE\xB8", "\xCE\x98"},   // θ Θ
    {"Iota", "\xCE\xB9", "\xCE\x99"},   // ι Ι
    {"Kappa", "\xCE\xBA", "\xCE\x9A"},   // κ Κ
    {"Lambda", "\xCE\xBB", "\xCE\x9B"},   // λ Λ
    {"Mu", "\xCE\xBC", "\xCE\x9C"},   // μ Μ
    {"Nu", "\xCE\xBD", "\xCE\x9D"},   // ν Ν
    {"Xi", "\xCE\xBE", "\xCE\x9E"},   // ξ Ξ
    {"Omicron", "\xCE\xBF", "\xCE\x9F"},   // ο Ο
    {"Pi", "\xCF\x80", "\xCE\xA0"},   // π Π
    {"Rho", "\xCF\x81", "\xCE\xA1"},   // ρ Ρ
    {"Sigma", "\xCF\x83", "\xCE\xA3"},   // σ Σ
    {"Tau", "\xCF\x84", "\xCE\xA4"},   // τ Τ
    {"Upsilon", "\xCF\x85", "\xCE\xA5"},   // υ Υ
    {"Phi", "\xCF\x86", "\xCE\xA6"},   // φ Φ
    {"Chi", "\xCF\x87", "\xCE\xA7"},   // χ Χ
    {"Psi", "\xCF\x88", "\xCE\xA8"},   // ψ Ψ
    {"Omega", "\xCF\x89", "\xCE\xA9"},   // ω Ω
};

// Mathematica named characters \[Name] that are not plain Greek letters.
struct Named { std::string_view name, ascii; AliasKind kind; };
inline constexpr Named kNamed[] = {
    {"ImaginaryI", "I", AliasKind::Constant}, {"ImaginaryJ", "I", AliasKind::Constant},
    {"ExponentialE", "E", AliasKind::Constant},
    {"CurlyEpsilon", "epsilon", AliasKind::Letter}, {"CurlyPhi", "phi", AliasKind::Letter},
    {"CurlyTheta", "theta", AliasKind::Letter}, {"CurlyKappa", "kappa", AliasKind::Letter},
    {"CurlyRho", "rho", AliasKind::Letter}, {"FinalSigma", "sigma", AliasKind::Letter},
    {"Micro", "mu", AliasKind::Letter},
};

}  // namespace fc2lt::tables

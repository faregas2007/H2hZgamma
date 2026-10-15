// test_fc2lt.cpp -- unit tests without any framework.   (run by ctest as fc2lt_unit)
#include <cmath>
#include <complex>
#include <iostream>
#include "fc2lt.h"

static int failures = 0;

#define CHECK(cond) do { if (!(cond)) { ++failures; std::cerr << "FAIL line " << __LINE__ << ": " #cond "\n"; } } while (0)
#define CHECK_BODY(src, expected) do { auto t_ = fc2lt::translate(src); \
    if (t_.body != (expected)) { ++failures; std::cerr << "FAIL line " << __LINE__ \
        << "\n  got:      " << t_.body << "\n  expected: " << (expected) << "\n"; } } while (0)
#define CHECK_BODY_M(model, src, expected) do { auto t_ = fc2lt::translate(src, &(model)); \
    if (t_.body != (expected)) { ++failures; std::cerr << "FAIL line " << __LINE__ \
        << "\n  got:      " << t_.body << "\n  expected: " << (expected) << "\n"; } } while (0)

static std::string errorOf(const std::string& src, std::size_t* pos = nullptr, const fc2lt::Model* model = nullptr) {
    try { fc2lt::translate(src, model); }
    catch (const fc2lt::Error& e) { if (pos) *pos = e.pos(); return e.what(); }
    return "<no error>";
}
#define CHECK_ERR(src, needle) do { std::string m_ = errorOf(src); if (m_.find(needle) == std::string::npos) { \
    ++failures; std::cerr << "FAIL line " << __LINE__ << ": error was \"" << m_ << "\", wanted \"" << needle << "\"\n"; } } while (0)
#define CHECK_ERR_M(model, src, needle) do { std::string m_ = errorOf(src, nullptr, &(model)); if (m_.find(needle) == std::string::npos) { \
    ++failures; std::cerr << "FAIL line " << __LINE__ << ": error was \"" << m_ << "\", wanted \"" << needle << "\"\n"; } } while (0)
#define CHECK_MODEL_ERR(text, needle) do { std::string m_ = "<no error>"; try { fc2lt::Model x_; x_.addSource("m.model", text); } \
    catch (const fc2lt::Error& e) { m_ = e.what(); } if (m_.find(needle) == std::string::npos) { ++failures; \
    std::cerr << "FAIL line " << __LINE__ << ": model error was \"" << m_ << "\", wanted \"" << needle << "\"\n"; } } while (0)

int main() {
    // --- precedence, implicit multiplication, powers -------------------------------------
    CHECK_BODY("1 + 2*3",   "(1.0 + (2.0 * 3.0))");
    CHECK_BODY("2 x y",     "((2.0 * x) * y)");
    CHECK_BODY("a - b - c", "((a - b) - c)");                       // left-associative
    CHECK_BODY("-x^2",      "(-std::pow(x, 2))");                   // -(x^2), not (-x)^2
    CHECK_BODY("x^-1",      "std::pow(x, -1)");
    CHECK_BODY("a^b^c",     "std::pow(std::complex<double>(a), std::pow(std::complex<double>(b), c))");   // right-assoc
    CHECK_BODY("Pi^-1/2",   "(std::pow(3.14159265358979323846, -1) / 2.0)");   // (Pi^-1)/2
    CHECK_BODY("x^(1/2)",   "std::sqrt(std::complex<double>(x))");
    CHECK_BODY("1.5*^-3 x", "(1.5e-3 * x)");                         // Mathematica scientific notation
    CHECK_BODY("1/2",       "(1.0 / 2.0)");                          // never integer division
    CHECK_BODY("Sqrt[s - 4 m^2]", "std::sqrt(std::complex<double>((s - (4.0 * std::pow(m, 2)))))");
    CHECK_BODY("(* a (* nested *) comment *) 1", "1.0");

    // --- symbols and parameters ------------------------------------------------------------
    auto t = fc2lt::translate("(* comment *) int + a$b + int");
    CHECK(t.params.size() == 2 && t.params[0] == "int_" && t.params[1] == "a_b");   // keyword + '$' fixed
    CHECK(fc2lt::translate("x y x").params.size() == 2);                             // no duplicates

    // --- LoopTools scalar integrals: copied through, args stay real ----------------------------
    CHECK_BODY("A0[mt^2]",                   "A0(std::pow(mt, 2))");
    CHECK_BODY("B0[s, m^2, m^2]",            "B0(s, std::pow(m, 2), std::pow(m, 2))");
    CHECK_BODY("C0[0, 0, s, m^2, m^2, m^2]", "C0(0.0, 0.0, s, std::pow(m, 2), std::pow(m, 2), std::pow(m, 2))");
    CHECK_BODY("D0[0, 0, 0, 0, s, t, a, b, c, d]", "D0(0.0, 0.0, 0.0, 0.0, s, t, a, b, c, d)");
    CHECK_BODY("2 B0[s, m, m] (s - 4 m)",    "((2.0 * B0(s, m, m)) * (s - (4.0 * m)))");

    // --- Unicode and Mathematica named characters: normalised to ASCII by the lexer ---------------------------
    CHECK_BODY("B0[s\xEF\xBC\x8C m, m]",  "B0(s, m, m)");        // fullwidth comma
    CHECK_BODY("\xEF\xBB\xBF" "x + 1",     "(x + 1.0)");          // byte-order mark
    CHECK_BODY("a\xC2\xA0" "b",             "(a * b)");            // no-break space
    CHECK_BODY("a \xE2\x88\x92 b",         "(a - b)");            // U+2212 minus
    CHECK_BODY("\xCE\xB1 + \\[Beta]",      "(alpha + beta)");     // alpha (UTF-8) and \[Beta]
    CHECK(fc2lt::translate("\xCE\xB1 + \\[Alpha]").params.size() == 1);        // both spellings are the same symbol
    CHECK_BODY("\xCE\x94 + \xCE\xB4",      "(Delta + delta)");    // capital and small delta stay distinct
    CHECK_BODY("\\[CapitalDelta] + \\[Delta]", "(Delta + delta)");
    CHECK_BODY("\xCE\xBC" "2",             "mu2");                // mu2 is one name
    CHECK_BODY("\xC2\xB5 x",               "(mu * x)");           // micro sign
    CHECK_BODY("2 \xE2\x85\x88",           "(2.0 * std::complex<double>(0.0, 1.0))");     // imaginary i
    CHECK_BODY("\\[ImaginaryI] x",         "(std::complex<double>(0.0, 1.0) * x)");
    CHECK_BODY("\xCF\x80 r",               "(3.14159265358979323846 * r)");               // pi is the constant Pi, not a letter
    CHECK_BODY("\\[Pi]",                   "3.14159265358979323846");
    CHECK_BODY("\\[CapitalPi]",            "CapitalPi");
    CHECK_BODY("\\[ExponentialE]",         "2.71828182845904523536");
    CHECK_ERR("\xD1\x89 x",                "(U+0449)");           // unknown letter: shows the code point
    CHECK_ERR("\\[Foo] + 1",               "unknown named character \\[Foo]");
    CHECK_ERR("\\[Alpha + 1",              "unterminated named character");

    // --- complex numbers --------------------------------------------------------------------------
    CHECK_BODY("I^2", "std::pow(std::complex<double>(0.0, 1.0), 2)");
    const std::complex<double> sanity = std::pow(std::complex<double>(0.0, 1.0), 2);   // does the emitted C++ build?
    CHECK(std::abs(sanity + 1.0) < 1e-12);

    // --- atoms: SMP["m_t"], FCGV["MT"], Subscript[m, t] are ONE symbol --------------------------------------
    auto ta = fc2lt::translate("SMP[\"m_t\"]^2 + FCGV[\"MT\"] + Subscript[m, t] + SMP[\"g'_W\"] + SMP[\"V_ud\", I]");
    CHECK(ta.symbols.size() == 5);
    CHECK(ta.symbols[0] == "SMP[\"m_t\"]" && ta.params[0] == "SMP_m_t");
    CHECK(ta.symbols[1] == "FCGV[\"MT\"]" && ta.params[1] == "FCGV_MT");
    CHECK(ta.symbols[2] == "Subscript[m, t]" && ta.params[2] == "Subscript_m_t");
    CHECK(ta.params[3] == "SMP_gp_W");                                              // apostrophe -> p
    CHECK(ta.symbols[4] == "SMP[\"V_ud\", I]" && ta.params[4] == "SMP_V_ud_I");
    CHECK_ERR("SMP[\"m_t\", x + 1]",       "must be strings, symbols or numbers");
    CHECK_ERR("Pair[p, q] + 1",            "unsupported function Pair");              // not an atom head: still an error
    CHECK_ERR("B0[\"a\", 1, 2]",           "a string is only allowed");
    CHECK_ERR("\"abc",                     "unterminated string");

    // --- model files: one language, one parser -----------------------------------------------------------------
    fc2lt::Model m;
    m.addSource("t.model",
        "(* comment *)\n"
        "Inputs[s, t]\n"
        "mt     = SLHA[MASS, 6]\n"
        "alpha  = 1/SLHA[SMINPUTS, 1]\n"
        "e      = Sqrt[4 Pi alpha]\n"
        "SMP[\"m_t\"] = mt\n"
        "SMP[\"Delta_UV\"] = Runner[Delta]\n"
        "mu     = Runner[Mu2]\n"
        "two    = 1 +\n"                         // continues: the line ends in an operator
        "    1\n"
        "far    = Sqrt[\n  2 ]\n"                // continues: a bracket is open
        "a1 = 1; a2 = 2\n");                      // ';' separates statements
    auto tm = fc2lt::translate("SMP[\"m_t\"]^2 + s*SMP[\"Delta_UV\"]", &m);
    CHECK(tm.body == "(std::pow(slha_0, 2) + (s * rt_delta))");
    CHECK(tm.params.size() == 1 && tm.params[0] == "s" && tm.usesDelta && !tm.usesMu2);
    CHECK(tm.slha.size() == 1 && tm.slha[0].block == "MASS" && tm.slha[0].key == std::vector<int>{6});
    CHECK_BODY_M(m, "e", "std::sqrt(std::complex<double>(((4.0 * 3.14159265358979323846) * (1.0 / slha_0))))");
    CHECK_BODY_M(m, "mt + SMP[\"m_t\"] + alpha", "((slha_0 + slha_0) + (1.0 / slha_1))");      // one slot per entry
    CHECK(fc2lt::translate("mt + alpha + mt", &m).slha.size() == 2);
    CHECK_BODY_M(m, "mu", "rt_mu2");
    CHECK(fc2lt::translate("mu", &m).usesMu2);
    CHECK_BODY_M(m, "two", "(1.0 + 1.0)");
    CHECK_BODY_M(m, "far", "std::sqrt(std::complex<double>(2.0))");
    CHECK_BODY_M(m, "a1 + a2", "(1.0 + 2.0)");
    CHECK_BODY_M(m, "B0[s, mt^2, mt^2]", "B0(s, std::pow(slha_0, 2), std::pow(slha_0, 2))");   // a model symbol inside a loop function
    CHECK_ERR_M(m, "B0[s, e, mt]", "argument 2 of B0 must be real");                        // derived value is complex (Sqrt) -> caught
    CHECK_ERR_M(m, "mtpo + 1",     "unknown symbol 'mtpo' -- did you mean 'mt'?");
    CHECK_ERR_M(m, "zzz",          "unknown symbol 'zzz'");
    CHECK_ERR_M(m, "Inputs[s]",    "belongs in a model file");
    // later model files override earlier ones; a file may not define a symbol twice
    fc2lt::Model o;
    o.addSource("1.model", "x = 1\n");
    o.addSource("2.model", "x = 2\n");
    CHECK_BODY_M(o, "x", "2.0");
    CHECK_MODEL_ERR("x = 1\nx = 2\n",        "'x' is defined twice in this file");
    CHECK_MODEL_ERR("Pi = 3\n",              "'Pi' is a constant");
    CHECK_MODEL_ERR("1 = x\n",               "left side of '='");
    CHECK_MODEL_ERR("x + 1\n",               "must be Inputs[symbol, ...]");
    CHECK_MODEL_ERR("Inputs[1]\n",           "takes symbols only");
    CHECK_MODEL_ERR("a = (1 +\n",            "unexpected end of input");
    // cycles, and errors that belong to a model file are reported in THAT file
    fc2lt::Model c;
    c.addSource("c.model", "a = b + 1\nb = a\nbad = SLHA[MASS, 6.5]\nbad2 = nope\n");
    CHECK_ERR_M(c, "a",    "circular definition: a -> b -> a");
    CHECK_ERR_M(c, "bad",  "SLHA indices must be integers");
    CHECK_ERR_M(c, "bad2", "unknown symbol 'nope'");
    try { fc2lt::translate("bad", &c); CHECK(false); }
    catch (const fc2lt::Error& e) {
        CHECK(e.file() == "c.model");
        const std::string shown = fc2lt::describeError(e, "bad");
        CHECK(shown.find("at c.model line 3, column") != std::string::npos);
        CHECK(shown.find("bad = SLHA[MASS, 6.5]") != std::string::npos);
    }
    CHECK_ERR("SLHA[MASS, 6] + 1", "unsupported function SLHA");                     // without a model SLHA is not understood
    { fc2lt::Model e1; e1.addSource("e.model", "Inputs[s]\n");
      CHECK_ERR_M(e1, "SLHA[6]", "SLHA[...] needs a block name first");
      CHECK_ERR_M(e1, "Runner[Foo]", "Runner[...] takes Delta or Mu2");
      CHECK_BODY_M(e1, "SLHA[\"mass\", 24] + SLHA[Mass, -1]", "(slha_0 + slha_1)"); }  // names are upper-cased; negative indices ok

    // --- errors are specific and carry positions ----------------------------------------------
    CHECK_ERR("B0[s, m]",                    "B0 needs 3 arguments");
    CHECK_ERR("a +",                         "unexpected end of input");
    CHECK_ERR("a b )",                       "unexpected ')'");
    CHECK_ERR("{a}",                         "unexpected character '{'");
    CHECK_ERR("(* oops",                     "unterminated");
    CHECK_ERR("a # b",                       "unexpected character '#'");
    CHECK_ERR("PaVe[0, 0, s, m, m, m]",      "unsupported function PaVe");   // only A0 B0 C0 D0 are supported
    CHECK_ERR("B1[s, m, m]",                 "unsupported function B1");
    CHECK_ERR("B0[s, Sqrt[x], m]",           "argument 2 of B0 must be real");
    CHECK_ERR("A0[I]",                       "argument 1 of A0 must be real");
    CHECK_ERR("a_b + 1",                     "unexpected character '_'");   // Mathematica symbols have no underscore
    std::size_t pos = 0;
    errorOf("a + Pair[p, q]", &pos);
    CHECK(pos == 4);

    const std::string msg = fc2lt::describeError(fc2lt::Error("boom", 4), "a + Pair[p, q]");
    CHECK(msg.find("line 1, column 5") != std::string::npos);
    CHECK(msg.find("    a + Pair[p, q]\n        ^") != std::string::npos);   // caret under 'P'

    // --- rendering -------------------------------------------------------------------------------------
    const std::string out = fc2lt::renderFunction(fc2lt::translate("x + 1"), "f");
    CHECK(out.find("inline std::complex<double> f(double x) {") != std::string::npos);
    CHECK(out.find("#include \"clooptools.h\"") != std::string::npos);
    { std::string m_ = "<none>"; try { fc2lt::renderFunction(tm, "f"); } catch (const fc2lt::Error& e) { m_ = e.what(); }
      CHECK(m_.find("--registry") != std::string::npos); }                         // plain style cannot carry slots

    // pipeline style
    const std::string reg = fc2lt::renderRegistered(tm, "bub");
    CHECK(reg.find("namespace bub {") != std::string::npos);
    CHECK(reg.find("eval([[maybe_unused]] const ampflow::Args& ampflow_args)") != std::string::npos);
    CHECK(reg.find("const double s = ampflow_args.input[0];") != std::string::npos);
    CHECK(reg.find("const double slha_0 = ampflow_args.slha[0];   // MASS[6]") != std::string::npos);
    CHECK(reg.find("const double rt_delta = ampflow_args.delta;") != std::string::npos);
    CHECK(reg.find("rt_mu2") == std::string::npos || reg.find("ampflow_args.mu2") == std::string::npos);   // only if used
    CHECK(reg.find("{\"s\"},\n        {{\"MASS\", {6}}},") != std::string::npos);
    CHECK(reg.find("[](const ampflow::Args& a) { return eval(a); }") != std::string::npos);
    CHECK(reg.find("#include \"ampflow/amplitude.h\"") != std::string::npos);
    const std::string regAtom = fc2lt::renderRegistered(ta, "q");
    CHECK(regAtom.find("{\"SMP[\\\"m_t\\\"]\"") != std::string::npos);              // quotes inside the key are escaped
    CHECK(regAtom.find("const double SMP_m_t = ampflow_args.input[0];") != std::string::npos);
    const std::string reg0 = fc2lt::renderRegistered(fc2lt::translate("1 + 2"), "c");   // nothing needed at all
    CHECK(reg0.find("\"c\",\n        {},\n        {},") != std::string::npos);

    std::cout << (failures ? "FAILED: " + std::to_string(failures) : std::string("all tests passed")) << "\n";
    return failures ? 1 : 0;
}

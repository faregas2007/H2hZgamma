// clooptools.h (builtin) -- a small stand-in for LoopTools' C++ header, so the pipeline builds, runs
// and can be tested on a machine without LoopTools.
//
//   * A0 and B0 are implemented (analytic, with the -i*epsilon prescription), in LoopTools' conventions:
//       - all masses are SQUARED, p is p^2;  mudim is mu^2;  delta is Delta = 1/eps - gamma_E + ln 4pi
//       - A0(m)        = m (Delta + 1 - ln(m/mu^2))
//       - B0(p,m0,m1)  = Delta - Int_0^1 dx ln( (x m1 + (1-x) m0 - x(1-x) p - i eps) / mu^2 )
//   * C0 and D0 are NOT implemented here and throw; use -DAMPFLOW_BACKEND=looptools for those.
//
// The same names exist in LoopTools, so generated code compiles unchanged against either header.
#pragma once
#include <algorithm>
#include <cmath>
#include <complex>
#include <stdexcept>

typedef double RealType;
typedef std::complex<double> ComplexType;

namespace ampflow_builtin {

inline double delta = 0.0;    // Delta, the UV-pole parameter
inline double mudim = 1.0;    // mu^2

// int_0^1 ln(x - r) dx for complex r off the real axis.
//   |r| <= 8 : closed form  (1-r) ln(1-r) + r ln(-r) - 1
//   |r| >  8 : ln(-r) - sum_n 1/(n(n+1) r^n)   -- the closed form loses digits to cancellation when
//              r is huge (that happens when p is tiny compared with the masses)
inline ComplexType logIntegral(ComplexType r) {
    if (std::abs(r) <= 8.0) return (1.0 - r) * std::log(1.0 - r) + r * std::log(-r) - 1.0;
    ComplexType sum = 0.0, rn = 1.0;
    for (int n = 1; n <= 40; ++n) {
        rn *= r;
        sum += 1.0 / (static_cast<double>(n) * (n + 1) * rn);
    }
    return std::log(-r) - sum;
}

// I = int_0^1 ln(f(x) - i*eps) dx   with   f(x) = p x^2 + (m1 - m0 - p) x + m0.
// Strategy: write f = p (x - r1)(x - r2) with roots r1, r2 pushed off the real axis by the (tiny but
// finite) epsilon, integrate each logarithm exactly, and repair the 2*pi*i ambiguity of
// ln(f) = ln p + ln(x-r1) + ln(x-r2) by comparing both sides at x = 0.
inline ComplexType integralLogF(double p, double m0, double m1) {
    const double scale = std::max({std::abs(p), m0, m1});
    const double eps = 1e-20 * scale;

    if (std::abs(p) <= 1e-12 * std::max(m0, m1)) {               // p = 0: f is linear in x
        auto xlogx = [&](double m) { return m > 0 ? ComplexType(m * std::log(m), 0.0) : ComplexType(0.0, 0.0); };
        if (std::abs(m1 - m0) <= 1e-13 * std::max(m0, m1)) return std::log(ComplexType(m0, -eps));
        return (xlogx(m1) - xlogx(m0)) / (m1 - m0) - 1.0;
    }

    const double b = m1 - m0 - p;
    const ComplexType c(m0, -eps);
    const ComplexType sq = std::sqrt(ComplexType(b * b, 0.0) - 4.0 * p * c);
    const double sign = (b * sq.real() >= 0.0) ? 1.0 : -1.0;     // stable quadratic formula
    const ComplexType q = -0.5 * (b + sign * sq);
    const ComplexType r1 = q / p, r2 = c / q;

    const ComplexType viaRoots = std::log(ComplexType(p, 0.0)) + logIntegral(r1) + logIntegral(r2);
    const ComplexType at0 = std::log(ComplexType(p, 0.0)) + std::log(-r1) + std::log(-r2);
    const double k = std::round((std::log(c) - at0).imag() / (2.0 * M_PI));
    return viaRoots + ComplexType(0.0, 2.0 * M_PI * k);
}

// Exact imaginary part. Im Int ln(f - i eps) = -pi * (length of {x in [0,1] : f(x) < 0}), so the
// imaginary part of B0 is  +pi * that length  -- computed from the real roots of f, which makes it
// exactly 0 below threshold instead of rounding noise.
inline double negativeLength(double p, double m0, double m1) {
    if (std::abs(p) <= 1e-12 * std::max(m0, m1)) return 0.0;        // f is linear and f(0), f(1) >= 0
    const double b = m1 - m0 - p;
    const double disc = b * b - 4.0 * p * m0;
    if (disc <= 0.0) return 0.0;                                     // no sign change
    const double sq = std::sqrt(disc);
    const double q = -0.5 * (b + (b >= 0.0 ? sq : -sq));
    double x1 = q / p, x2 = (q != 0.0) ? m0 / q : x1;                // the two real roots
    if (x1 > x2) std::swap(x1, x2);
    auto clip = [](double lo, double hi) { return std::max(0.0, std::min(1.0, hi) - std::max(0.0, lo)); };
    if (p > 0.0) return clip(x1, x2);                                // f < 0 between the roots
    return clip(-1e300, x1) + clip(x2, 1e300);                       // f < 0 outside the roots
}

}  // namespace ampflow_builtin

// ---- the LoopTools-compatible interface -------------------------------------------------------
inline void ltini() {}
inline void ltexi() {}
inline void clearcache() {}
inline void setdelta(double d)  { ampflow_builtin::delta = d; }
inline void setmudim(double m)  { ampflow_builtin::mudim = m; }
inline void setlambda(double)   {}

inline ComplexType A0(double m) {
    if (m < 0) throw std::domain_error("builtin A0: negative mass^2");
    if (m == 0) return 0.0;
    return m * (ampflow_builtin::delta + 1.0 - std::log(m / ampflow_builtin::mudim));
}

inline ComplexType B0(double p, double m0, double m1) {
    if (m0 < 0 || m1 < 0) throw std::domain_error("builtin B0: negative mass^2");
    if (p == 0 && m0 == 0 && m1 == 0) throw std::domain_error("builtin B0(0,0,0) is scaleless");
    const ComplexType I = ampflow_builtin::integralLogF(p, m0, m1);
    return ComplexType(ampflow_builtin::delta + std::log(ampflow_builtin::mudim) - I.real(),
                       M_PI * ampflow_builtin::negativeLength(p, m0, m1));
}

inline ComplexType C0(double, double, double, double, double, double) {
    throw std::runtime_error("the builtin backend has no C0; configure with -DAMPFLOW_BACKEND=looptools");
}
inline ComplexType D0(double, double, double, double, double, double, double, double, double, double) {
    throw std::runtime_error("the builtin backend has no D0; configure with -DAMPFLOW_BACKEND=looptools");
}

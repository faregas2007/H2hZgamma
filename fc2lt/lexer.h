// lexer.h -- stage 1: cut the source text into tokens.
//
// A token is the smallest meaningful piece: a number, a name, a "string", or
// one punctuation character. Whitespace, backslash line-breaks and (* comments
// *) are discarded here.
//
// Unicode is normalised HERE and nowhere else, so that only ASCII ever reaches
// the rest of the program:
//   * Greek letters and Mathematica named characters become ASCII names: alpha,
//   \[Alpha] -> alpha,  Delta -> Delta
//   * the imaginary unit, e and pi become the constants  I, E, Pi (U+2148,
//   U+2147, pi, \[ImaginaryI] ...)
//   * look-alike punctuation (fullwidth comma/brackets, U+2212 minus, ...) and
//   odd spaces are read as plain ASCII
//   * anything else non-ASCII is an error that names the code point (U+XXXX)
//
//   "2 mt^2 B0[s, m, m]"  ->  2 | mt | ^ | 2 | B0 | [ | s | , | m | , | m | ]
#pragma once
#include "ast.h"
#include "tables.h"
#include <cctype>
#include <iomanip>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace fc2lt {

enum class TokenKind { Number, Identifier, String, Op, End };

struct Token {
  TokenKind kind;
  std::string text;
  std::size_t pos;
};

class Lexer {
public:
  explicit Lexer(const std::string &src) : src_(src) {}

  std::vector<Token> run() {
    std::vector<Token> out;
    while (skipTrivia()) {
      const char c = src_[i_];
      if (const tables::Alias *a = aliasAt();
          a && a->kind == tables::AliasKind::Op) {
        out.push_back({TokenKind::Op, std::string(a->ascii), i_});
        i_ += a->utf8.size();
      } else if (const auto g = glyphAt(i_);
                 g && g->constant) { // pi, i, e on their own
        out.push_back({TokenKind::Identifier, g->ascii, i_});
        i_ += g->length;
      } else if (isDigit(c) || (c == '.' && isDigit(at(i_ + 1)))) {
        out.push_back(number());
      } else if (std::isalpha(static_cast<unsigned char>(c)) || c == '$' || g) {
        out.push_back(identifier());
      } else if (c == '"') {
        out.push_back(string());
      } else if (kOps.find(c) != std::string_view::npos) {
        out.push_back({TokenKind::Op, std::string(1, c), i_});
        ++i_;
      } else {
        throw Error("unexpected character " + describeChar(), i_);
      }
    }
    out.push_back({TokenKind::End, "",
                   src_.size()}); // sentinel: the parser never runs off the end
    return out;
  }

private:
  static constexpr std::string_view kOps = "+-*/^()[],=";

  struct Glyph {
    std::string ascii;
    std::size_t length;
    bool constant;
  };

  static bool isDigit(char c) {
    return std::isdigit(static_cast<unsigned char>(c)) != 0;
  }
  char at(std::size_t k) const { return k < src_.size() ? src_[k] : '\0'; }
  std::string_view rest(std::size_t i) const {
    return std::string_view(src_).substr(i);
  }

  static std::string lowered(std::string_view s) {
    std::string r(s);
    for (char &c : r)
      c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return r;
  }

  // Skips blanks, odd Unicode spaces, "\" line continuations and (* comments
  // *). False at end of input.
  bool skipTrivia() {
    while (i_ < src_.size()) {
      const char c = src_[i_];
      if (std::isspace(static_cast<unsigned char>(c))) {
        ++i_;
      } else if (c == '\\' && (at(i_ + 1) == '\n' || at(i_ + 1) == '\r')) {
        ++i_;
      } else if (const tables::Alias *a = aliasAt();
                 a && a->kind == tables::AliasKind::Space) {
        i_ += a->utf8.size();
      } else if (c == '(' && at(i_ + 1) == '*') {
        skipComment();
      } else {
        return true;
      }
    }
    return false;
  }

  void skipComment() { // (* ... *) -- these nest in Mathematica
    const std::size_t start = i_;
    int depth = 0;
    while (i_ < src_.size()) {
      if (at(i_) == '(' && at(i_ + 1) == '*') {
        ++depth;
        i_ += 2;
      } else if (at(i_) == '*' && at(i_ + 1) == ')') {
        --depth;
        i_ += 2;
        if (depth == 0)
          return;
      } else
        ++i_;
    }
    throw Error("unterminated (* comment *)", start);
  }

  const tables::Alias *aliasAt() const {
    if (static_cast<unsigned char>(src_[i_]) < 0x80)
      return nullptr;
    for (const tables::Alias &a : tables::kAliases)
      if (rest(i_).substr(0, a.utf8.size()) == a.utf8)
        return &a;
    return nullptr;
  }

  // A letter or constant written as UTF-8 (alpha, pi, ...) or as a Mathematica
  // named character (\[Alpha]).
  std::optional<Glyph> glyphAt(std::size_t i) const {
    if (i >= src_.size())
      return std::nullopt;
    const std::string_view r = rest(i);
    if (r.substr(0, 2) == "\\[")
      return named(i);
    if (static_cast<unsigned char>(r[0]) < 0x80)
      return std::nullopt;
    for (const tables::Alias &a : tables::kAliases)
      if ((a.kind == tables::AliasKind::Letter ||
           a.kind == tables::AliasKind::Constant) &&
          r.substr(0, a.utf8.size()) == a.utf8)
        return Glyph{std::string(a.ascii), a.utf8.size(),
                     a.kind == tables::AliasKind::Constant};
    for (const tables::Greek &g : tables::kGreek) {
      if (r.substr(0, g.lower.size()) == g.lower)
        return g.name == "Pi" ? Glyph{"Pi", g.lower.size(), true}
                              : Glyph{lowered(g.name), g.lower.size(), false};
      if (r.substr(0, g.upper.size()) == g.upper)
        return Glyph{g.name == "Pi" ? "CapitalPi" : std::string(g.name),
                     g.upper.size(), false};
    }
    return std::nullopt;
  }

  std::optional<Glyph> named(std::size_t i) const { // \[Name]
    const std::string_view r = rest(i);
    const std::size_t end = r.find(']');
    if (end == std::string_view::npos || end > 40)
      throw Error("unterminated named character \\[...]", i);
    const std::string_view name = r.substr(2, end - 2);
    const std::size_t len = end + 1;
    for (const tables::Named &n : tables::kNamed)
      if (n.name == name)
        return Glyph{std::string(n.ascii), len,
                     n.kind == tables::AliasKind::Constant};
    for (const tables::Greek &g : tables::kGreek) {
      if (g.name == name)
        return g.name == "Pi" ? Glyph{"Pi", len, true}
                              : Glyph{lowered(g.name), len, false};
      if (name.size() > 7 && name.substr(0, 7) == "Capital" &&
          name.substr(7) == g.name)
        return Glyph{g.name == "Pi" ? "CapitalPi" : std::string(g.name), len,
                     false};
    }
    throw Error("unknown named character \\[" + std::string(name) + "]", i);
  }

  // 12   3.5   .5   2.   and Mathematica's scientific form  1.5*^-3  (= 1.5e-3)
  Token number() {
    const std::size_t start = i_;
    while (isDigit(at(i_)))
      ++i_;
    if (at(i_) == '.') {
      ++i_;
      while (isDigit(at(i_)))
        ++i_;
    }
    std::string text = src_.substr(start, i_ - start);
    if (at(i_) == '*' && at(i_ + 1) == '^') {
      std::size_t j = i_ + 2;
      if (at(j) == '-' || at(j) == '+')
        ++j;
      const std::size_t firstDigit = j;
      while (isDigit(at(j)))
        ++j;
      if (j > firstDigit) { // only consume "*^" if an exponent follows
        text += "e" + src_.substr(i_ + 2, j - (i_ + 2));
        i_ = j;
      }
    }
    return {TokenKind::Number, text, start};
  }

  // ASCII letters/digits/'$' and Greek letters (each written to the token as
  // its ASCII name).
  Token identifier() {
    const std::size_t start = i_;
    std::string text;
    for (;;) {
      const char c = at(i_);
      if (std::isalnum(static_cast<unsigned char>(c)) || c == '$') {
        text += c;
        ++i_;
        continue;
      }
      const auto g = glyphAt(i_);
      if (!g || g->constant)
        break;
      text += g->ascii;
      i_ += g->length;
    }
    return {TokenKind::Identifier, text, start};
  }

  Token string() { // "text"  with \" and \\ escapes
    const std::size_t start = i_++;
    std::string text;
    while (i_ < src_.size() && src_[i_] != '"') {
      if (src_[i_] == '\\' && i_ + 1 < src_.size())
        ++i_;
      text += src_[i_++];
    }
    if (i_ >= src_.size())
      throw Error("unterminated string", start);
    ++i_;
    return {TokenKind::String, text, start};
  }

  // "'#'" for printable ASCII; "'x' (U+00B5)" for anything else, so you can see
  // exactly what it is.
  std::string describeChar() const {
    const unsigned char lead = static_cast<unsigned char>(src_[i_]);
    if (lead >= 0x20 && lead < 0x7F)
      return std::string("'") + src_[i_] + "'";
    const std::size_t len = lead >= 0xF0   ? 4
                            : lead >= 0xE0 ? 3
                            : lead >= 0xC0 ? 2
                                           : 1;
    unsigned cp = len == 1 ? lead : (lead & (0xFFu >> (len + 1)));
    for (std::size_t k = 1; k < len && i_ + k < src_.size(); ++k)
      cp = (cp << 6) | (static_cast<unsigned char>(src_[i_ + k]) & 0x3Fu);
    std::ostringstream o;
    if (lead >= 0x80)
      o << "'" << src_.substr(i_, len) << "' ";
    o << "(U+" << std::uppercase << std::hex << std::setw(4)
      << std::setfill('0') << cp << ")";
    return o.str();
  }

  const std::string &src_;
  std::size_t i_ = 0;
};

} // namespace fc2lt

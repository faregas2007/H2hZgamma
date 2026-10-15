// ast.h -- the data structures shared by every stage of the translator.
//
//   text --Lexer--> tokens --Parser--> AST --Resolver--> AST --Emitter--> C++
//
// The AST ("abstract syntax tree") is a tree in which every node is a number, a symbol, a string, an
// operator or a function call.   Example:   2 x^2 + B0[s, m, m]
//   Add
//   |- Mul( 2 , Pow(x, 2) )
//   `- Call "B0" ( s, m, m )
#pragma once
#include <cstddef>
#include <memory>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace fc2lt {

constexpr std::size_t kNoPos = static_cast<std::size_t>(-1);

// Every failure the translator reports is an Error. `pos` is the character offset in the source text so the
// command line tool can point at the exact spot. An error raised while reading a model file also carries that
// file's name and text (inFile), so the message can show the right file.
class Error : public std::runtime_error {
public:
    explicit Error(const std::string& message, std::size_t pos = kNoPos, std::string file = {}, std::string source = {})
        : std::runtime_error(message), pos_(pos), file_(std::move(file)), source_(std::move(source)) {}
    std::size_t pos() const { return pos_; }
    const std::string& file() const { return file_; }
    const std::string& source() const { return source_; }
    // Same error, located in `file`. `shift` converts a position inside one statement to the file. An error that
    // already knows its file keeps it (the innermost definition wins).
    Error inFile(const std::string& file, const std::string& source, std::size_t shift = 0) const {
        if (!file_.empty()) return *this;
        return Error(what(), pos_ == kNoPos ? kNoPos : pos_ + shift, file, source);
    }
private:
    std::size_t pos_;
    std::string file_, source_;
};

enum class Kind {
    Number,   // text = literal, e.g. "4" or "1.5e-3"
    Symbol,   // text = name, e.g. "mt", "I", or an atom key such as  SMP["m_t"]
    String,   // text = the characters between the quotes (only legal as an argument: SLHA["MASS", 6])
    Call,     // text = head, kids = arguments:   B0[s, m, m]
    Slot,     // text = a C++ variable made by the resolver:  slha_0, rt_delta   (never written by users)
    Add, Sub, Mul, Div, Pow,   // kids = {left, right}
    Neg       // kids = {operand}
};

struct Node;
using NodePtr = std::shared_ptr<const Node>;   // nodes are immutable once built

struct Node {
    Kind kind;
    std::string text;
    std::vector<NodePtr> kids;
    std::size_t pos;           // where in the source this node starts (for error messages)
};

inline NodePtr makeNode(Kind kind, std::size_t pos, std::string text = {}, std::vector<NodePtr> kids = {}) {
    return std::make_shared<const Node>(Node{kind, std::move(text), std::move(kids), pos});
}

// One entry of an SLHA card the amplitude needs:  MASS[24]  ->  {"MASS", {24}}
struct SlhaRef {
    std::string block;           // upper case
    std::vector<int> key;
    bool operator==(const SlhaRef& o) const { return block == o.block && key == o.key; }
    std::string where() const {
        std::string s = block + "[";
        for (std::size_t i = 0; i < key.size(); ++i) s += (i ? "," : "") + std::to_string(key[i]);
        return s + "]";
    }
};

}  // namespace fc2lt

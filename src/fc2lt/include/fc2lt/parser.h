// parser.h -- stage 2: tokens -> AST (recursive descent). The SAME parser reads amplitude files and model files.
//
// Grammar, lowest precedence first. Each rule is one member function below, and a rule only calls the rules
// BELOW it -- that is how precedence is encoded.
//
//   statement := expr [ '=' expr ]                        <- model files:  symbol = expression   |   Inputs[...]
//   expr      := term   { ('+' | '-') term }
//   term      := unary  { ('*' | '/') unary  |  unary }   <- 2nd form: "2 x" = 2*x (juxtaposition)
//   unary     := ('-' | '+') unary  |  power
//   power     := primary [ '^' unary ]                    <- right-associative: a^b^c = a^(b^c)
//   primary   := NUMBER | STRING | NAME [ '[' [ expr {',' expr} ] ']' ] | '(' expr ')'
//
// A NAME whose head is one of tables::kAtomHeads (SMP, FCGV, Subscript) is not a function call but ONE symbol:
// SMP["m_t"] is the symbol with key  SMP["m_t"]; the arguments may be any expression, e.g. Subscript[g, h*H*H].
// HoldForm[x] is just x.
//
// Consequences that match Mathematica:  -x^2 = -(x^2),  a^-1 is fine,  Pi^-1/2 = (Pi^-1)/2,
// and  a -b  is a subtraction, not a*(-b).
#pragma once
#include "ast.h"
#include "lexer.h"

namespace fc2lt {

// One line of a model file: either  lhs = rhs  (a definition) or just a declaration such as Inputs[s, t].
struct Statement {
    NodePtr lhs;     // null for a declaration
    NodePtr rhs;
};

class Parser {
public:
    explicit Parser(std::vector<Token> tokens) : t_(std::move(tokens)) {}

    NodePtr parseAll() {
        NodePtr root = expr();
        if (cur().kind != TokenKind::End) throw Error("unexpected " + describe(cur()), cur().pos);
        return root;
    }

    Statement parseStatement() {
        NodePtr first = expr();
        Statement s;
        if (isOp('=')) {
            if (first->kind != Kind::Symbol)
                throw Error("the left side of '=' must be a symbol or an atom such as SMP[\"m_t\"]", first->pos);
            if (tables::lookup(tables::kConstants, first->text))
                throw Error("'" + first->text + "' is a constant and cannot be defined", first->pos);
            ++p_;
            s.lhs = first;
            s.rhs = expr();
        } else {
            s.rhs = first;
        }
        if (cur().kind != TokenKind::End) throw Error("unexpected " + describe(cur()), cur().pos);
        return s;
    }

private:
    const Token& cur() const { return t_[p_]; }
    bool isOp(char c) const { return cur().kind == TokenKind::Op && cur().text[0] == c; }
    void expect(char c) {
        if (!isOp(c)) throw Error(std::string("expected '") + c + "'", cur().pos);
        ++p_;
    }
    static std::string describe(const Token& t) {
        if (t.kind == TokenKind::End) return "end of input";
        if (t.kind == TokenKind::String) return "string \"" + t.text + "\"";
        return "'" + t.text + "'";
    }
    bool startsPrimary() const {
        return cur().kind == TokenKind::Number || cur().kind == TokenKind::Identifier ||
               cur().kind == TokenKind::String || isOp('(');
    }

    NodePtr expr() {
        NodePtr left = term();
        while (isOp('+') || isOp('-')) {
            const Token op = cur(); ++p_;
            NodePtr right = term();
            left = makeNode(op.text == "+" ? Kind::Add : Kind::Sub, op.pos, "", {left, right});
        }
        return left;
    }

    NodePtr term() {
        NodePtr left = unary();
        for (;;) {
            if (isOp('*') || isOp('/')) {
                const Token op = cur(); ++p_;
                left = makeNode(op.text == "*" ? Kind::Mul : Kind::Div, op.pos, "", {left, unary()});
            } else if (startsPrimary()) {                       // implicit multiplication
                const std::size_t pos = cur().pos;
                left = makeNode(Kind::Mul, pos, "", {left, unary()});
            } else {
                return left;
            }
        }
    }

    NodePtr unary() {
        if (isOp('-')) { const std::size_t pos = cur().pos; ++p_; return makeNode(Kind::Neg, pos, "", {unary()}); }
        if (isOp('+')) { ++p_; return unary(); }
        return power();
    }

    NodePtr power() {
        NodePtr base = primary();
        if (isOp('^')) {
            const std::size_t pos = cur().pos; ++p_;
            return makeNode(Kind::Pow, pos, "", {base, unary()});   // exponent may carry a sign
        }
        return base;
    }

    // The text of an expression in a fixed, canonical InputForm-like spelling. Atom keys are built from it, so the
    // same atom written in a model file and in an amplitude gets the same key, however it was spaced or wrapped.
    //   "m_t" -> "m_t" (with quotes)   Subscript[m, t]   h*H*H   -I   (a + b)*c
    static std::string canon(const NodePtr& n) {
        auto paren = [](const NodePtr& k, const std::string& s) {
            return (k->kind == Kind::Add || k->kind == Kind::Sub || k->kind == Kind::Neg) ? "(" + s + ")" : s;
        };
        switch (n->kind) {
            case Kind::Number: case Kind::Symbol: case Kind::Slot: return n->text;
            case Kind::String: return "\"" + n->text + "\"";
            case Kind::Neg:    return "-" + paren(n->kids[0], canon(n->kids[0]));
            case Kind::Add:    return canon(n->kids[0]) + " + " + canon(n->kids[1]);
            case Kind::Sub:    return canon(n->kids[0]) + " - " + paren(n->kids[1], canon(n->kids[1]));
            case Kind::Mul:    return paren(n->kids[0], canon(n->kids[0])) + "*" + paren(n->kids[1], canon(n->kids[1]));
            case Kind::Div:    return paren(n->kids[0], canon(n->kids[0])) + "/" + paren(n->kids[1], canon(n->kids[1]));
            case Kind::Pow:    return paren(n->kids[0], canon(n->kids[0])) + "^" + paren(n->kids[1], canon(n->kids[1]));
            case Kind::Call: {
                std::string s = n->text + "[";
                for (std::size_t i = 0; i < n->kids.size(); ++i) s += (i ? ", " : "") + canon(n->kids[i]);
                return s + "]";
            }
        }
        return "";
    }

    NodePtr primary() {
        const Token tok = cur();
        if (tok.kind == TokenKind::Number) { ++p_; return makeNode(Kind::Number, tok.pos, tok.text); }
        if (tok.kind == TokenKind::String) { ++p_; return makeNode(Kind::String, tok.pos, tok.text); }
        if (tok.kind == TokenKind::Identifier) {
            ++p_;
            if (!isOp('[')) return makeNode(Kind::Symbol, tok.pos, tok.text);
            ++p_;
            std::vector<NodePtr> args;
            if (!isOp(']')) {
                args.push_back(expr());
                while (isOp(',')) { ++p_; args.push_back(expr()); }
            }
            expect(']');
            if (tok.text == "HoldForm" && args.size() == 1) return args[0];      // display wrapper: transparent
            for (std::string_view head : tables::kAtomHeads)
                if (head == tok.text) {                          // SMP["m_t"], Subscript[m, t]  ->  one symbol
                    std::string key = tok.text + "[";
                    for (std::size_t i = 0; i < args.size(); ++i) key += (i ? ", " : "") + canon(args[i]);
                    return makeNode(Kind::Symbol, tok.pos, key + "]");
                }
            return makeNode(Kind::Call, tok.pos, tok.text, std::move(args));
        }
        if (isOp('(')) { ++p_; NodePtr e = expr(); expect(')'); return e; }
        throw Error(tok.kind == TokenKind::End ? "unexpected end of input" : "unexpected " + describe(tok), tok.pos);
    }

    std::vector<Token> t_;
    std::size_t p_ = 0;
};

inline NodePtr parse(const std::string& source) { return Parser(Lexer(source).run()).parseAll(); }

}  // namespace fc2lt

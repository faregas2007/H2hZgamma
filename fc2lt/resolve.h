// resolve.h -- stage 3: apply the model to an amplitude, ONCE, at translation time.
//
// Walks the amplitude tree and
//   * replaces every symbol the model defines by its definition (recursively; cycles are errors),
//   * turns  SLHA[BLOCK, i, ...]  into a numbered slot  slha_0, slha_1, ...  (each entry once),
//   * turns  Runner[Delta] / Runner[Mu2]  into the slots  rt_delta / rt_mu2,
//   * leaves constants (I, Pi, E) and declared Inputs[...] alone,
//   * rejects every other symbol, with a "did you mean ...?" hint.
// What comes out has no model symbols left: only numbers, inputs and slots.
#pragma once
#include <algorithm>
#include <map>
#include "ast.h"
#include "model.h"
#include "tables.h"

namespace fc2lt {

struct Resolved {
    NodePtr tree;
    std::vector<SlhaRef> slha;
    bool usesDelta = false, usesMu2 = false;
};

class Resolver {
public:
    explicit Resolver(const Model& model) : model_(model) {}

    Resolved run(const NodePtr& amplitude) {
        slha_.clear(); cache_.clear(); stack_.clear(); delta_ = mu2_ = false;
        NodePtr tree = subst(amplitude);
        return {tree, slha_, delta_, mu2_};
    }

private:
    static bool isPlainInteger(const Node& n) { return n.kind == Kind::Number && n.text.find_first_of(".e") == std::string::npos; }

    static NodePtr relocate(const NodePtr& n, std::size_t pos) {      // errors later point at the use site
        std::vector<NodePtr> kids;
        for (const NodePtr& k : n->kids) kids.push_back(relocate(k, pos));
        return makeNode(n->kind, pos, n->text, std::move(kids));
    }

    static std::size_t distance(const std::string& a, const std::string& b) {     // Levenshtein
        std::vector<std::size_t> prev(b.size() + 1), cur(b.size() + 1);
        for (std::size_t j = 0; j <= b.size(); ++j) prev[j] = j;
        for (std::size_t i = 1; i <= a.size(); ++i) {
            cur[0] = i;
            for (std::size_t j = 1; j <= b.size(); ++j)
                cur[j] = std::min({prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)});
            std::swap(prev, cur);
        }
        return prev[b.size()];
    }

    std::string unknownMessage(const std::string& name) const {
        std::string best;
        std::size_t bestD = (name.size() >= 4 ? 2 : 1) + 1;            // short names: one typo at most, or every pair "looks close"
        for (const std::string& k : model_.knownNames()) {
            const std::size_t d = distance(name, k);
            if (d < bestD) { bestD = d; best = k; }
        }
        std::string m = "unknown symbol '" + name + "'";
        if (!best.empty()) m += " -- did you mean '" + best + "'?";
        return m + " (define it in a model file, or declare it with Inputs[...])";
    }

    NodePtr slotFor(const Node& call) {                               // SLHA[BLOCK, i, ...]
        if (call.kids.empty() || (call.kids[0]->kind != Kind::Symbol && call.kids[0]->kind != Kind::String))
            throw Error("SLHA[...] needs a block name first: SLHA[MASS, 6] or SLHA[\"MASS\", 6]", call.pos);
        SlhaRef ref;
        for (const char c : call.kids[0]->text) ref.block += static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
        for (std::size_t i = 1; i < call.kids.size(); ++i) {
            const Node& k = *call.kids[i];
            if (isPlainInteger(k)) ref.key.push_back(std::stoi(k.text));
            else if (k.kind == Kind::Neg && isPlainInteger(*k.kids[0])) ref.key.push_back(-std::stoi(k.kids[0]->text));
            else throw Error("SLHA indices must be integers", k.pos);
        }
        auto it = std::find(slha_.begin(), slha_.end(), ref);
        if (it == slha_.end()) { slha_.push_back(ref); it = slha_.end() - 1; }
        return makeNode(Kind::Slot, call.pos, "slha_" + std::to_string(it - slha_.begin()));
    }

    NodePtr runnerSlot(const Node& call) {                            // Runner[Delta] / Runner[Mu2]
        if (call.kids.size() == 1 && call.kids[0]->kind == Kind::Symbol) {
            if (call.kids[0]->text == "Delta") { delta_ = true; return makeNode(Kind::Slot, call.pos, "rt_delta"); }
            if (call.kids[0]->text == "Mu2")   { mu2_ = true;   return makeNode(Kind::Slot, call.pos, "rt_mu2"); }
        }
        throw Error("Runner[...] takes Delta or Mu2", call.pos);
    }

    NodePtr subst(const NodePtr& n) {
        switch (n->kind) {
            case Kind::Number: case Kind::String: case Kind::Slot:
                return n;
            case Kind::Symbol: {
                if (tables::lookup(tables::kConstants, n->text)) return n;
                if (const Definition* d = model_.find(n->text)) {
                    if (const auto c = cache_.find(n->text); c != cache_.end()) return relocate(c->second, n->pos);
                    const auto at = std::find(stack_.begin(), stack_.end(), n->text);
                    if (at != stack_.end()) {
                        std::string chain;
                        for (auto k = at; k != stack_.end(); ++k) chain += *k + " -> ";
                        throw Error("circular definition: " + chain + n->text, n->pos);
                    }
                    stack_.push_back(n->text);
                    NodePtr r;
                    try { r = subst(d->tree); }
                    catch (const Error& e) { stack_.pop_back(); throw e.inFile(d->file, d->source, d->shift); }
                    stack_.pop_back();
                    cache_[n->text] = r;
                    return relocate(r, n->pos);
                }
                if (model_.isInput(n->text)) return n;
                throw Error(unknownMessage(n->text), n->pos);
            }
            case Kind::Call: {
                if (n->text == "SLHA") return slotFor(*n);
                if (n->text == "Runner") return runnerSlot(*n);
                if (n->text == "Inputs") throw Error("Inputs[...] belongs in a model file, not in an amplitude", n->pos);
                break;
            }
            default: break;
        }
        std::vector<NodePtr> kids;
        for (const NodePtr& k : n->kids) kids.push_back(subst(k));
        return makeNode(n->kind, n->pos, n->text, std::move(kids));
    }

    const Model& model_;
    std::vector<SlhaRef> slha_;
    std::map<std::string, NodePtr> cache_;
    std::vector<std::string> stack_;
    bool delta_ = false, mu2_ = false;
};

}  // namespace fc2lt

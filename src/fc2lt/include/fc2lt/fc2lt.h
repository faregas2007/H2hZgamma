// fc2lt.h -- the public API: include just this file.
//
//   text --Lexer--> tokens --Parser--> AST --Resolver--> AST --dimension--> AST --Emitter--> C++ --render--> header
//   (lexer.h, parser.h, resolve.h + model.h, dimension.h, emitter.h, render.h; errors are shown by diagnostics.h)
//
//   fc2lt::Model model;  model.addSource("sm.model", text);                       // optional
//   fc2lt::Translation t = fc2lt::translate("2 B0[s, mt^2, mt^2]", &model);
//   std::string header   = fc2lt::renderRegistered(t, "my_amp");
#pragma once
#include <cctype>
#include <sstream>
#include <string>
#include "ast.h"
#include "diagnostics.h"
#include "dimension.h"
#include "emitter.h"
#include "model.h"
#include "parser.h"
#include "render.h"
#include "resolve.h"

namespace fc2lt {

// FeynCalc exports often end with ";" or a newline; neither is part of the expression.
inline std::string trimTrailing(std::string s) {
    while (!s.empty() && (std::isspace(static_cast<unsigned char>(s.back())) || s.back() == ';')) s.pop_back();
    return s;
}

// FeynCalc text -> C++ expression. Throws fc2lt::Error.
//   without a model: every free symbol is an input of the function (the original behaviour)
//   with a model   : symbols are resolved against it (see resolve.h); only declared inputs stay free
//   if the amplitude still contains the dimension D, it is taken to 4 with the rational terms (dimension.h)
inline Translation translate(const std::string& source, const Model* model = nullptr) {
    const NodePtr tree = parse(trimTrailing(source));
    if (!model) return Emitter().run(dimension::limitTo4(tree));
    const Resolved r = Resolver(*model).run(tree);
    Translation t = Emitter().run(dimension::limitTo4(r.tree));
    t.slha = r.slha;
    t.usesDelta = r.usesDelta;
    t.usesMu2 = r.usesMu2;
    return t;
}

}  // namespace fc2lt

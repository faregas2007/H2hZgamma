// diagnostics.h -- how an Error is shown to a person: the message, the offending line and a caret under it.
#pragma once
#include <sstream>
#include <string>
#include "ast.h"

namespace fc2lt {

// "fc2lt: error: message" followed by the offending source line and a caret under it.
inline std::string describeError(const Error& e, const std::string& fallbackSource) {
    std::ostringstream o;
    o << "fc2lt: error: " << e.what() << "\n";
    const std::string& source = e.source().empty() ? fallbackSource : e.source();
    const std::size_t pos = e.pos();
    if (pos == kNoPos || pos > source.size()) return o.str();

    const std::size_t nl = pos == 0 ? std::string::npos : source.rfind('\n', pos - 1);
    const std::size_t lineStart = nl == std::string::npos ? 0 : nl + 1;
    std::size_t lineEnd = source.find('\n', pos);
    if (lineEnd == std::string::npos) lineEnd = source.size();
    std::size_t lineNo = 1;
    for (std::size_t i = 0; i < lineStart; ++i) lineNo += source[i] == '\n';

    const std::size_t from = pos - lineStart > 40 ? pos - 40 : lineStart;     // window long lines
    const std::size_t to   = lineEnd - pos > 40 ? pos + 40 : lineEnd;
    const std::string lead = from > lineStart ? "..." : "";
    o << "  at " << (e.file().empty() ? "" : e.file() + " ") << "line " << lineNo << ", column " << pos - lineStart + 1 << ":\n"
      << "    " << lead << source.substr(from, to - from) << (to < lineEnd ? "..." : "") << "\n"
      << "    " << std::string(lead.size() + (pos - from), ' ') << "^\n";
    return o.str();
}

}  // namespace fc2lt

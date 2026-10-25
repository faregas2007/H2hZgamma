# fc2lt: FeynCalc (Mathematica InputForm) -> C++ translator. Header-only core and a command line tool.
add_library(fc2lt_headers INTERFACE)
target_include_directories(fc2lt_headers INTERFACE include)
target_compile_features(fc2lt_headers INTERFACE cxx_std_17)

add_executable(fc2lt main.cpp)
target_link_libraries(fc2lt PRIVATE fc2lt_headers)
ampflow_enable_warnings(fc2lt)

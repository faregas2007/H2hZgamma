# fc2lt: FeynCalc (Mathematica InputForm) -> C++ translator, plus its unit tests.
add_executable(fc2lt main.cpp)
target_compile_features(fc2lt PRIVATE cxx_std_17)

add_executable(fc2lt_tests test_fc2lt.cpp)
target_compile_features(fc2lt_tests PRIVATE cxx_std_17)
add_test(NAME fc2lt_unit COMMAND fc2lt_tests)

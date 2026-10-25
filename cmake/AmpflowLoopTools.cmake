# ampflow_fetch_looptools(<out_prefix_var>)
#
# Gets LoopTools into the repository when the looptools backend is selected and no installation was found:
#
#   third_party/looptools/LoopTools-<ver>.tar.gz     the archive (downloaded, or put there by hand -- see below)
#   third_party/looptools/src/LoopTools-<ver>/       unpacked, configured and built here
#   third_party/looptools/install/<ver>/             "make install" prefix:  include/clooptools.h, lib*/libooptools.a
#
# It runs at configure time and only once: when install/<ver>/include/clooptools.h exists, nothing is done.
# Needs: a Fortran compiler (gfortran), a C compiler, make, and -- unless the archive is already there -- network access.
#
# Without network access (or if the download fails): download LoopTools-<ver>.tar.gz yourself from
# https://feynarts.de/looptools/ , put it into third_party/looptools/ and configure again. Nothing else is needed.
include_guard(GLOBAL)

# MD5 sums as published at https://feynarts.de/looptools/ (the archive is verified against them)
set(_ampflow_lt_md5_2.16 "9503320a00e7c16b4ac1fd20749d3feb")
set(_ampflow_lt_md5_2.15 "12fed44164ea4e3d74f33a836ee0e5d3")
set(_ampflow_lt_md5_2.14 "a798fd9628734d95a15f4531b204ee4f")

function(ampflow_fetch_looptools out_prefix)
  set(ver  "${AMPFLOW_LOOPTOOLS_VERSION}")
  set(base "${AMPFLOW_LOOPTOOLS_DIR}")
  set(name "LoopTools-${ver}")
  set(tarball "${base}/${name}.tar.gz")
  set(srcdir  "${base}/src/${name}")
  set(prefix  "${base}/install/${ver}")
  set(log     "${base}/build-${ver}.log")
  set(${out_prefix} "${prefix}" PARENT_SCOPE)

  if(EXISTS "${prefix}/include/clooptools.h")
    return()
  endif()

  set(url "${AMPFLOW_LOOPTOOLS_URL}")
  if(url STREQUAL "")
    set(url "https://feynarts.de/looptools/${name}.tar.gz")
  endif()
  set(md5 "${AMPFLOW_LOOPTOOLS_MD5}")
  if(md5 STREQUAL "" AND DEFINED _ampflow_lt_md5_${ver})
    set(md5 "${_ampflow_lt_md5_${ver}}")
  endif()

  set(manual
      "Download ${name}.tar.gz from https://feynarts.de/looptools/ by hand, put it into\n  ${base}/\nand configure again (or install LoopTools yourself and pass -DLOOPTOOLS_ROOT=<prefix>).")

  file(MAKE_DIRECTORY "${base}")

  # 1. the archive ---------------------------------------------------------------------------------------------------
  if(NOT EXISTS "${tarball}")
    message(STATUS "ampflow: downloading ${url}")
    file(DOWNLOAD "${url}" "${tarball}" STATUS dl_status TLS_VERIFY ON SHOW_PROGRESS)
    list(GET dl_status 0 dl_code)
    if(NOT dl_code EQUAL 0)
      list(GET dl_status 1 dl_msg)
      file(REMOVE "${tarball}")
      message(FATAL_ERROR "ampflow: could not download LoopTools (${dl_msg}).\n${manual}")
    endif()
  else()
    message(STATUS "ampflow: using ${tarball}")
  endif()
  if(NOT md5 STREQUAL "")
    file(MD5 "${tarball}" got_md5)
    if(NOT got_md5 STREQUAL md5)
      message(FATAL_ERROR "ampflow: ${tarball} has MD5 ${got_md5}, expected ${md5} (feynarts.de). "
                          "Delete the file and configure again, or set -DAMPFLOW_LOOPTOOLS_MD5= to skip the check.")
    endif()
  else()
    message(WARNING "ampflow: no MD5 known for LoopTools ${ver}; the archive is not verified")
  endif()

  # 2. tools -------------------------------------------------------------------------------------------------------------
  find_program(AMPFLOW_FORTRAN_COMPILER NAMES gfortran)
  find_program(AMPFLOW_MAKE_PROGRAM NAMES make gmake)
  if(NOT AMPFLOW_FORTRAN_COMPILER)
    message(FATAL_ERROR "ampflow: building LoopTools needs a Fortran compiler and none was found.\n"
                        "Install gfortran (e.g. 'sudo apt install gfortran', 'brew install gcc') or pass -DAMPFLOW_FORTRAN_COMPILER=/path/to/gfortran.")
  endif()
  if(NOT AMPFLOW_MAKE_PROGRAM)
    message(FATAL_ERROR "ampflow: building LoopTools needs 'make' and it was not found (-DAMPFLOW_MAKE_PROGRAM=...).")
  endif()

  # 3. unpack, configure, build, install ---------------------------------------------------------------------------
  # LoopTools' "make install" runs a plain 'mkdir <prefix>' (no -p) and then copies into <prefix>/lib64 etc., so the prefix
  # (and the parent install/) must exist beforehand.
  file(MAKE_DIRECTORY "${prefix}")
  # An earlier attempt may have left a built tree: reuse it (configure and make then have nothing left to do).
  if(NOT EXISTS "${srcdir}/configure")
    file(REMOVE_RECURSE "${srcdir}")
    file(ARCHIVE_EXTRACT INPUT "${tarball}" DESTINATION "${base}/src")
  endif()
  if(NOT EXISTS "${srcdir}/configure")
    message(FATAL_ERROR "ampflow: ${tarball} does not contain ${name}/configure -- wrong archive?")
  endif()

  file(WRITE "${log}" "")
  set(env_cmd ${CMAKE_COMMAND} -E env "FC=${AMPFLOW_FORTRAN_COMPILER}")
  if(CMAKE_C_COMPILER)
    list(APPEND env_cmd "CC=${CMAKE_C_COMPILER}")
  endif()
  message(STATUS "ampflow: building LoopTools ${ver} into ${prefix} (a few minutes, once; log: ${log})")
  foreach(step "./configure;--prefix=${prefix}" "${AMPFLOW_MAKE_PROGRAM}" "${AMPFLOW_MAKE_PROGRAM};install")
    execute_process(COMMAND ${env_cmd} ${step}
                    WORKING_DIRECTORY "${srcdir}"
                    OUTPUT_FILE "${log}" ERROR_FILE "${log}"
                    RESULT_VARIABLE rc)
    if(NOT rc EQUAL 0)
      message(FATAL_ERROR "ampflow: '${step}' failed while building LoopTools (exit status ${rc}); see ${log}.\n"
                          "You can also install LoopTools yourself and pass -DLOOPTOOLS_ROOT=<prefix>.")
    endif()
  endforeach()
  if(NOT EXISTS "${prefix}/include/clooptools.h")
    message(FATAL_ERROR "ampflow: LoopTools was built but ${prefix}/include/clooptools.h is missing; see ${log}.")
  endif()
  message(STATUS "ampflow: LoopTools ${ver} installed in ${prefix}")
endfunction()

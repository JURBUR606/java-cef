# Copyright (c) 2016 The Chromium Embedded Framework Authors. All rights
# reserved. Use of this source code is governed by a BSD-style license that
# can be found in the LICENSE file.

# Download the CEF binary distribution for |platform| and |version| to
# |download_dir|. The |CEF_ROOT| variable will be set in global scope pointing
# to the extracted location.
#
# MCEF fork: the official Spotify CDN builds ship without proprietary codecs
# (H.264/AAC), which breaks most live streams and many videos. OBS Project
# publishes standard CEF minimal distributions built with those codecs; we use
# them, verified against the SHA-256 hashes OBS pins in its CMakePresets.json
# (obsproject/obs-studio, dependencies.cef, version 7871).

set(OBS_CEF_BASE_URL "https://cdn-fastly.obsproject.com/downloads")
set(OBS_CEF_FILE_windows64    "cef_binary_7871_windows_x64.zip")
set(OBS_CEF_HASH_windows64    "54cd191a3f56bb1f05be22b95e1fa8041061b38bd5fe94e0776fb34dd599f341")
set(OBS_CEF_FILE_windowsarm64 "cef_binary_7871_windows_arm64.zip")
set(OBS_CEF_HASH_windowsarm64 "3f5b604eab71baab20c08f054d68c6212d06237e172fb8d38271c2384c2eb3a6")
set(OBS_CEF_FILE_macosx64     "cef_binary_7871_macos_x86_64.tar.xz")
set(OBS_CEF_HASH_macosx64     "980783bba509e7e79a671c29040bbe29d832a934c1368b500a17a22e076eb0f4")
set(OBS_CEF_FILE_macosarm64   "cef_binary_7871_macos_arm64.tar.xz")
set(OBS_CEF_HASH_macosarm64   "0343233fc462384c2f1f58a4222028bc6171f05948a822241f89df2faa7cee8d")
set(OBS_CEF_FILE_linux64      "cef_binary_7871_linux_x86_64.tar.xz")
set(OBS_CEF_HASH_linux64      "8ffc64d06ea74da613eeda7f2aa5d4e98661af6fa3ed8c68724c9a6e4e89ea8e")
set(OBS_CEF_FILE_linuxarm64   "cef_binary_7871_linux_aarch64.tar.xz")
set(OBS_CEF_HASH_linuxarm64   "b05cf13b0f482e3b0149ac21268268c536d091b5e6608c742019ebd6c8e8a1e3")

function(DownloadCEF platform version download_dir)
  set(CEF_DISTRIBUTION "cef_binary_${version}_${platform}")
  set(CEF_DOWNLOAD_DIR "${download_dir}")

  # The location where we expect the extracted binary distribution.
  set(CEF_ROOT "${CEF_DOWNLOAD_DIR}/${CEF_DISTRIBUTION}" CACHE INTERNAL "CEF_ROOT")

  if(NOT IS_DIRECTORY "${CEF_ROOT}")
    set(file "${OBS_CEF_FILE_${platform}}")
    set(hash "${OBS_CEF_HASH_${platform}}")
    if(NOT file OR NOT hash)
      message(FATAL_ERROR "No codec-enabled CEF build pinned for platform ${platform}")
    endif()

    set(CEF_DOWNLOAD_PATH "${CEF_DOWNLOAD_DIR}/${file}")
    if(NOT EXISTS "${CEF_DOWNLOAD_PATH}")
      message(STATUS "Downloading ${OBS_CEF_BASE_URL}/${file}...")
      file(
        DOWNLOAD "${OBS_CEF_BASE_URL}/${file}" "${CEF_DOWNLOAD_PATH}"
        EXPECTED_HASH SHA256=${hash}
        SHOW_PROGRESS
        )
    endif()

    # OBS archives may or may not wrap the distribution in a top-level folder
    set(extract_dir "${CEF_DOWNLOAD_DIR}/extract_${platform}")
    file(REMOVE_RECURSE "${extract_dir}")
    file(MAKE_DIRECTORY "${extract_dir}")
    message(STATUS "Extracting ${CEF_DOWNLOAD_PATH}...")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xf "${CEF_DOWNLOAD_PATH}"
      WORKING_DIRECTORY "${extract_dir}"
      RESULT_VARIABLE extract_result
      )
    if(NOT extract_result EQUAL 0)
      message(FATAL_ERROR "Failed to extract ${CEF_DOWNLOAD_PATH}")
    endif()
    file(GLOB entries LIST_DIRECTORIES true "${extract_dir}/*")
    list(LENGTH entries entry_count)
    if(entry_count EQUAL 1 AND IS_DIRECTORY "${entries}")
      file(RENAME "${entries}" "${CEF_ROOT}")
      file(REMOVE_RECURSE "${extract_dir}")
    else()
      file(RENAME "${extract_dir}" "${CEF_ROOT}")
    endif()
    if(NOT EXISTS "${CEF_ROOT}/cmake/FindCEF.cmake")
      message(FATAL_ERROR "${file} is not a CEF binary distribution (no cmake/FindCEF.cmake)")
    endif()
  endif()
endfunction()

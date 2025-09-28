#!/usr/bin/env bash
# ---- Clang Build Scripts ----
# Copyright (C) 2023-2025 fadlyas07 <mhmmdfdlyas@proton.me>

echo -e "[tag]\n${release_tag}" >latest.txt
release_url="https://github.com/xaverodumpster/dv_clang/releases/download/${release_tag}/${release_file}"
touch "clang_notes.txt"
{
    echo -e "[date]\n${release_date}\n"
    echo -e "[clang-ver]\n${clang_version}\n"
    echo -e "[lld-ver]\n${lld_version}\n"
    echo -e "[llvm-commit]\n${llvm_url}\n"
    echo -e "[llvm-commit-msg]\n${lcommit_message}\n"
    echo -e "[host-glibc]\n${glibc_version}\n"
    echo -e "[size-gzip]\n${release_sizeg}\n"
    echo -e "[size-xz]\n${release_sizex}\n"
    echo -e "[link-rel-gzip]\n${release_url}.gz\n"
    echo -e "[link-rel-xz]\n${release_url}.xz\n"
    echo -e "[shasum-gzip]\n${release_shasumg}\n"
    echo -e "[shasum-xz]\n${release_shasumx}"
} >"clang_notes.txt"

touch /tmp/commit_msg
{
    echo -e "CI: Bump to ${release_tag} build\n"
    echo "Clang version: ${clang_version}"
    echo "LLVM repo commit: ${lcommit_message}"
    echo "Link: ${llvm_url}"
} >/tmp/commit_msg

touch get_latest_url.sh
{
    echo -e "#!/usr/bin/env bash\n"
    echo "LATEST_URL_GZ=${release_url}.gz"
    echo "LATEST_URL_XZ=${release_url}.xz"
} >get_latest_url.sh

#!/usr/bin/env bash
# ---- Clang Build Scripts ----
# Copyright (C) 2023-2024 fadlyas07 <mhmmdfdlyas@proton.me>

echo -e "[tag]\n${release_tag}" >latest.txt
touch "${short_clang}-${release_tag}-info.txt"
{
    echo -e "[date]\n${release_date}\n"
    echo -e "[clang-ver]\n${clang_version}\n"
    echo -e "[lld-ver]\n${lld_version}\n"
    echo -e "[llvm-commit]\n${llvm_url}\n"
    echo -e "[llvm-commit-msg]\n${lcommit_message}\n"
    echo -e "[host-glibc]\n${glibc_version}\n"
    echo -e "[size]\n${release_size}\n"
    echo "[shasum]\n${release_shasum}"
} >"${short_clang}-${release_tag}-info.txt"

touch /tmp/commit_msg
{
    echo -e "greenforce: Bump to ${release_tag} build\n"
    echo "Clang version: ${clang_version}"
    echo "LLD version: ${lld_version}"
    echo "LLVM repo commit: ${lcommit_message}"
    echo "Link: ${llvm_url}"
} >/tmp/commit_msg

touch get_latest_url.sh
{
    echo -e "#!/usr/bin/env bash\n"
    echo "LATEST_URL=https://github.com/greenforce-project/greenforce_clang/releases/download/${release_tag}/${release_file}"
} >get_latest_url.sh

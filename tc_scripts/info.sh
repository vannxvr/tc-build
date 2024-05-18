#!/usr/bin/env bash
# ---- Clang Build Scripts ----
# Copyright (C) 2023-2024 fadlyas07 <mhmmdfdlyas@proton.me>

# Remove existing files
rm -rf latest*

# Create latest.txt and populate it with release tag
echo -e "[tag]\n${release_tag}" >latest.txt

# Create release info file and populate it with release information
touch "${release_info}"
{
    echo -e "[date]\n${release_date}\n"
    echo -e "[clang-ver]\n${clang_version}\n"
    echo -e "[lld-ver]\n${lld_version}\n"
    echo -e "[llvm-commit]\n${llvm_url}\n"
    echo -e "[llvm-commit-msg]\n${lcommit_message}\n"
    echo -e "[host-glibc]\n${glibc_version}\n"
    echo -e "[size]\n${release_size}\n"
    echo -e "[shasum]\n${release_shasum}"
} >"${release_info}"

touch /tmp/commit_desc
{
    echo -e "[Scheduled]: Update LLVM from commit ${llvm_hash}\n"
    echo "Tag: ${release_tag}"
    echo "Clang Version: ${short_clang}"
    echo -e "LLD Version: ${lld_version}\n"
    echo "Link: https://github.com/greenforce-project/greenforce_clang/releases/tag/${release_tag}"
} >/tmp/commit_desc

touch /tmp/release_desc
{
    echo "Clang Version: ${short_clang}"
    echo -e "LLD Version: ${lld_version}\n"
    echo "LLVM commit: ${llvm_url}"
} >/tmp/release_desc

touch /tmp/telegram_post
{
    echo -e "<b>New Greenforce Clang Update is Available!</b>\n"
    echo "<b>Host system details</b>"
    echo "<b>Distro:</b> <code>${distro_image}</code>"
    echo "<b>Glibc version:</b> <code>${glibc_version}</code>"
    echo -e "<b>Clang version:</b> <code>${dclang_version}</code>\n"
    echo "<b>Toolchain details</b>"
    echo "<b>Clang version:</b> <code>${short_clang}</code>"
    echo "<b>LLD version:</b> <code>${lld_version}</code>"
    echo -e "<b>LLVM commit:</b> <a href='${llvm_url}'>${lcommit_message}</a>\n"
    echo "<b>Build Date:</b> <code>$(date +'%Y-%m-%d (%H:%M)')</code>"
    echo "<b>Build Tag:</b> <code>${release_tag}</code>"
    echo "<b>Build Release:</b> <a href='${release_url}'>${release_file}</a> (${release_size})"
} >/tmp/telegram_post

touch latest_url.txt
{
    echo "# Latest Clang Link"
    echo "# This file provides the link to the latest successfully compiled Greenforce Clang ${short_clang}."
    echo -e "# It serves as a reference for accessing the most recent version of Clang for use in various projects.\n"
    echo "latest_url=${release_url}"
} >latest_url.txt

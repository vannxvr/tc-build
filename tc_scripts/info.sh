#!/usr/bin/env bash
# ---- Clang Build Scripts ----
# Copyright (C) 2023-2024 fadlyas07 <mhmmdfdlyas@proton.me>

# Remove existing files
rm -rf "${README_path}" latest*

# Create latest.txt and populate it with release tag
echo -e "[tag]\n${release_tag}" > latest.txt

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
} > "${release_info}"

touch /tmp/commit_desc
{
    echo -e "[Scheduled]: Update LLVM from commit ${llvm_hash}\n"
    echo "Tag: ${release_tag}"
    echo "Clang Version: ${short_clang}"
    echo -e "LLD Version: ${lld_version}\n"
    echo "Link: https://github.com/greenforce-project/greenforce_clang/releases/tag/${release_tag}"
} > /tmp/commit_desc

touch /tmp/release_desc
{
    echo "Clang Version: ${short_clang}"
    echo -e "LLD Version: ${lld_version}\n"
    echo "LLVM commit: ${llvm_url}"
} > /tmp/release_desc

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
} > /tmp/telegram_post

touch latest_url.txt
{
    echo "# Latest Clang Link"
    echo "# This file provides the link to the latest successfully compiled Greenforce Clang ${short_clang}."
    echo -e "# It serves as a reference for accessing the most recent version of Clang for use in various projects.\n"
    echo "latest_url=${release_url}"
} > latest_url.txt

# Create README.md file and populate it with content
touch "${README_path}"
{
    echo -e "# Greenforce Clang\n"
    echo -e "## Host compatibility\n"
    echo -e "This toolchain is built on ${distro_image}, which uses glibc ${glibc_version}. Compatibility with older distributions cannot be guaranteed. Other libc implementations (such as musl) are not supported.\n"
    echo -e "## Building Linux\n"
    echo -e "This is how you start initializing the Greenforce Clang to your server, use a command like this:\n"
    echo -e '```bash'
    echo -e "wget -c ${release_url} -O - | tar --use-compress-program=unzstd -xf - -C ~/greenforce-clang\n"
    echo -e '```\n'
    echo -e 'Make sure you have this toolchain in your `PATH`:\n'
    echo -e '```bash\n'
    echo -e 'export PATH="~/greenforce-clang/bin:${PATH}"\n'
    echo -e '```\n'
    echo -e 'For an AArch64 cross-compilation setup, you must set the following variables. Some of them can be environment variables, but some must be passed directly to `make` as a command-line argument. It is recommended to pass **all** of them as `make` arguments to avoid confusing errors:\n'
    echo -e '- `CC=clang` (must be passed directly to `make`)'
    echo -e '- Now GCC/binutils are separate. Set `CROSS_COMPILE` and `CROSS_COMPILE_ARM32` (if your kernel has a 32-bit vDSO) according to the toolchain you have.\n'
    echo -e 'Optionally, you can also choose to use as many LLVM tools as possible to reduce reliance on binutils. All of these must be passed directly to `make`:\n'
    echo -e '- `AR=llvm-ar`'
    echo -e '- `NM=llvm-nm`'
    echo -e '- `OBJCOPY=llvm-objcopy`'
    echo -e '- `OBJDUMP=llvm-objdump`'
    echo -e '- `STRIP=llvm-strip`\n'
    echo -e 'Note, however, that additional kernel patches may be required for these LLVM tools to work. It is also possible to replace the binutils linkers (`lf.bfd` and `ld.gold`) with `lld` and use Clangs integrated assembler for inline assembly in C code, but that will require many more kernel patches and it is currently impossible to use the integrated assembler for *all* assembly code in the kernel.\n'
    echo -e "Android kernels older than 4.14 will require patches for compiling with any Clang toolchain to work; those patches are out of the scope of this project. See [android-kernel-clang](https://github.com/nathanchance/android-kernel-clang) for more information.\n"
    echo -e 'Android kernels 4.19 and newer use the upstream variable `CROSS_COMPILE_COMPAT`. When building these kernels, replace `CROSS_COMPILE_ARM32` in your commands and scripts with `CROSS_COMPILE_COMPAT`.\n'
    echo -e "### Differences from other toolchains\n"
    echo -e "Greenforce Clang has been designed to be easy-to-use compared to other toolchains, such as [AOSP Clang](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/). The differences are as follows:\n"
    echo -e '- `CLANG_TRIPLE` does not need to be set because we dont use AOSP binutils.'
    echo -e '- `LD_LIBRARY_PATH` does not need to be set because we set library load paths in the toolchain.'
} > "${README_path}"

# Fixing typos and grammar
sed -i "s/Clangs/Clang's/g" "${README_path}"
sed -i "s/dont/don't/g" "${README_path}"

#!/usr/bin/env bash
# ---- Clang Build Scripts ----
# Copyright (C) 2023-2024 fadlyas07 <mhmmdfdlyas@proton.me>

# Inherit common function
source "${DIR}/tc_scripts/helper.sh"

# Build LLVM
export llvm_log="${DIR}/build-llvm-${release_tag}.log"
kecho "Building Clang LLVM (step: ${1})..."
./build-llvm.py ${build_flags} \
        --assertions \
        --build-stage1-only \
        --build-target distribution \
        --bolt \
        --defines LLVM_PARALLEL_COMPILE_JOBS=$(nproc --all) LLVM_PARALLEL_LINK_JOBS=$(nproc --all) \
        --install-folder "${install_path}" \
        --install-target distribution \
        --projects clang lld \
        --lto thin \
        --pgo llvm \
        --quiet-cmake \
        --no-update \
        --targets ARM AArch64 X86 \
        --vendor-string "greenforce" 2>&1 | tee "${llvm_log}"

for clang in "${install_path}"/bin/clang; do
    if ! [[ -f "${clang}" || -f "${DIR}/build/llvm/instrumented/profdata.prof" ]]; then
        kerror "Building Clang LLVM failed kindly check errors!"
        telegram_file "${llvm_log}" "Here is the LLVM error log."
        exit 1
    fi
done

if [[ "${1}" == final ]]; then
    # Build binutils
    kecho "Building binutils..."
    export binutils_log="${DIR}/build-binutils-${release_tag}.log"
    ./build-binutils.py \
        --install-folder "${install_path}" \
        --binutils-folder "${DIR}/src/binutils-master" \
        --targets arm aarch64 2>&1 | tee "${binutils_log}"

    for binutils in "${install_path}"/aarch64-linux-gnu/bin/ld; do
        if ! [[ -f "${binutils}" ]]; then
            kerror "Building binutils failed kindly check errors!"
            telegram_file "${binutils_log}" "Here is the binutils error log."
            exit 1
        fi
    done

    # Remove unused products
    rm -rf "${install_path}/include" "${install_path}/lib/cmake"
    rm -f "${install_path}"/lib/*.a "${install_path}"/lib/*.la
    for package in "${DIR}"/src/*.tar.xz; do
        rm -rf "${package}" || exit 1
    done

    # Strip remaining products
    find "${install_path}" -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}' | while read -r f; do
        strip -s "${f: : -1}"
    done

    # Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
    find "${install_path}" -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}' | while read -r bin; do
        # Remove last character from file output (':')
        bin="${bin: : -1}"
        patchelf --set-rpath "${install_path}/lib" "${bin}"
    done

    # Clone the catalogue repository
    if ! pushd "${DIR}/greenforce_clang"; then
        git clone --single-branch -b main "https://${ghuser_name}:${GITHUB_TOKEN}@github.com/greenforce-project/greenforce_clang" --depth=1 || {
            kecho "Failed to clone the catalogue repository!"
            kecho "Please check your server; it's likely that the repository exists."
            exit 1
        }
    fi

    # GitHub push environment
    pushd "${DIR}/src/llvm-project" || exit 1
    export lcommit_message="$(git log --pretty='format:%s' | head -n1)"
    export llvm_hash="$(git rev-parse --verify HEAD)"
    popd || exit 1
    export llvm_url="https://github.com/llvm/llvm-project/commit/${llvm_hash}"
    export clang_version="$(${install_path}/bin/clang --version | head -n1)"
    export short_clang="$(echo ${clang_version} | cut -d' ' -f4)"
    pushd "${DIR}/src/binutils-master" || exit 1
    export bcommit_message="$(git log --pretty='format:%s' | head -n1)"
    export binutils_hash="$(git rev-parse --verify HEAD)"
    popd || exit 1
    export binutils_url="https://github.com/bminor/binutils-gdb/commit/${binutils_hash}"
    export binutils_version="$(ls ${DIR}/src/ | grep "^binutils-" | sed "s/binutils-//g")"
    export ld_version="$(${install_path}/aarch64-linux-gnu/bin/ld --version | head -n1)"
    export release_file="greenforce-clang-${short_clang}-${release_tag}-${release_time}.tar.zst"
    export release_info="clang-${short_clang}-${release_tag}-${release_time}-info.txt"
    export release_url="https://github.com/greenforce-project/greenforce_clang/releases/download/${release_tag}/${release_file}"
    export README_path="${DIR}/greenforce_clang/README.md"

    # Package the final Clang release file
    wget https://raw.githubusercontent.com/greenforce-project/tc-build/backup/build_scripts/zstd
    chmod +x zstd
    pushd "${install_path}" || exit 1
    tar -I'../zstd --ultra -22 -T0' -cf "${release_file}" ./*
    popd || exit 1

    export release_path="${install_path}/${release_file}"
    export release_shasum="$(sha256sum ${release_path} | awk '{print $1}')"
    export release_size="$(du -sh ${release_path} | awk '{print $1}')"

    # Push the commits and releases
    pushd "${DIR}/greenforce_clang" || exit 1
    bash "${DIR}/tc_scripts/info.sh"
    git add .
    git commit -s -m "$(cat /tmp/commit_desc)"
    git push "https://${ghuser_name}:${GITHUB_TOKEN}@github.com/greenforce-project/greenforce_clang" main -f

    if gh release view "${release_tag}"; then
        gh release upload --clobber "${release_tag}" "${release_path}" && {
            kecho "Version ${release_tag} updated!"
        }
    else
        gh release create "${release_tag}" -F /tmp/release_desc "${release_path}" -t "${release_date}" && {
            kecho "Version ${release_tag} released!"
        }
    fi

    git push "https://${ghuser_name}:${GITHUB_TOKEN}@github.com/greenforce-project/greenforce_clang" main -f
    popd || exit 1
    telegram_message "$(cat /tmp/telegram_post)"
fi

#!/usr/bin/env bash
# ---- Clang Build Scripts ----
# Copyright (C) 2023-2024 fadlyas07 <mhmmdfdlyas@proton.me>

# Remove unused products
rm -rf "${install_path}/include" "${install_path}/lib/cmake"
rm -f "${install_path}"/lib/*.a "${install_path}"/lib/*.la
for package in "${DIR}"/src/*.tar.xz; do
    rm -rf "${package}" || exit 1
done

# Strip remaining products
find "${install_path}" -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}' | while read -r f; do
    strip -s "${f::-1}"
done

# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
find "${install_path}" -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}' | while read -r bin; do
    # Remove last character from file output (':')
    bin="${bin::-1}"
    patchelf --set-rpath "${install_path}/lib" "${bin}"
done

# Clone the catalogue repository
if ! pushd "${DIR}/greenforce_clang"; then
    git clone --single-branch -b main "https://${ghuser_name}:${GITHUB_TOKEN}@github.com/greenforce-project/greenforce_clang" --depth=1 ||
        {
            echo "Failed to clone the catalogue repository!"
            echo "Please check your server; it's likely that the repository exists."
            exit 1
        }
fi

# GitHub push environment
pushd "${DIR}/src/llvm-project" || exit 1
export lcommit_message="$(git log --pretty='format:%s' | head -n1)"
export llvm_hash="$(git rev-parse --verify HEAD)"
export llvm_url="https://github.com/llvm/llvm-project/commit/${llvm_hash}"
popd || exit 1

# Package the final Clang release file
pushd "${install_path}" || exit 1
export clang_version="$(bin/clang --version | head -n1)"
export short_clang="$(echo ${clang_version} | cut -d' ' -f4)"
export lld_version="$(bin/ld.lld --version | head -n1)"
export release_file="greenforce-clang-${short_clang}-${release_tag}.tar.zst"
tar -I 'zstd --ultra -22 -T0' -cf "${release_file}" ./*
export release_shasum="$(sha256sum "${release_file}" | awk '{print $1}')"
export release_size="$(du -sh "${release_file}" | awk '{print $1}')b"
popd || exit 1

# Push the commits and releases
pushd "${DIR}/greenforce_clang" || exit 1
bash "${DIR}/tc_scripts/info.sh"
git add .
git commit -s -m "$(cat /tmp/commit_msg)"
git push "https://${ghuser_name}:${GITHUB_TOKEN}@github.com/greenforce-project/greenforce_clang" main -f

if gh release view "${release_tag}"; then
    gh release upload --clobber "${release_tag}" "${install_path}/${release_file}" &&
        {
            echo "Version ${release_tag} updated!"
        }
else
    gh release create "${release_tag}" "${install_path}/${release_file}" -t "${release_date}" &&
        {
            echo "Version ${release_tag} released!"
        }
fi
popd || exit 1

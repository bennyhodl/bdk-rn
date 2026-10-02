[group("Repo")]
[doc("Default command; list all available commands.")]
@list:
  just --list --unsorted

[group("Repo")]
[doc("Open repo on GitHub in your default browser.")]
repo:
  open https://github.com/thunderbiscuit/bdk-rn

[group("Repo")]
[doc("Remove all build files.")]
clean:
  rm -rf ./cpp/
  rm -rf ./src/generated/
  rm -rf ./lib/
  rm -rf ./node_modules/
  rm -rf ./bdk-ffi/bdk-ffi/target/
  rm -rf ./BdkRnFramework.xcframework/
  rm -rf ./site/
  rm -rf ./dist-wasm/
  rm -f ./*.tgz

[group("Submodule")]
[doc("Initialize bdk-ffi submodule to committed hash.")]
submodule-init:
  git submodule update --init

[group("Submodule")]
[doc("Hard reset the bdk-ffi submodule to committed hash.")]
submodule-reset:
  git submodule update --force

[group("Submodule")]
[doc("Checkout the bdk-ffi submodule to the latest commit on master.")]
submodule-to-master:
  cd ./bdk-ffi/ \
  && git fetch origin \
  && git checkout master \
  && git pull origin master

[group("Submodule")]
[doc("Regenerate the async-sync patches from the current submodule working tree.")]
submodule-regen-patch:
  cd ./bdk-ffi/ \
  && git diff --unified=3 HEAD -- bdk-ffi/Cargo.toml > ../patches/bdk-ffi-async-sync-cargo.patch \
  && git diff --unified=3 HEAD -- bdk-ffi/src/lib.rs > ../patches/bdk-ffi-async-sync-lib.patch \
  && git diff --unified=3 HEAD -- bdk-ffi/src/esplora.rs > ../patches/bdk-ffi-async-sync-esplora.patch \
  && git diff --unified=3 HEAD -- bdk-ffi/src/electrum.rs > ../patches/bdk-ffi-async-sync-electrum.patch \
  && git diff --unified=3 HEAD -- bdk-ffi/src/tests/tx_builder.rs > ../patches/bdk-ffi-async-sync-tests.patch

[group("Submodule")]
[doc("Apply the async-sync patches to the bdk-ffi submodule.")]
submodule-apply-patch:
  cd ./bdk-ffi/ \
  && git reset --hard HEAD \
  && git apply -C1 ../patches/bdk-ffi-async-sync-cargo.patch \
  && git apply -C1 ../patches/bdk-ffi-async-sync-lib.patch \
  && git apply -C1 ../patches/bdk-ffi-async-sync-esplora.patch \
  && git apply -C1 ../patches/bdk-ffi-async-sync-electrum.patch \
  && git apply -C1 ../patches/bdk-ffi-async-sync-tests.patch

[group("Build")]
[doc("Build the tarball for Android only. Pass ABIs to override ubrn.config.yaml, e.g. `just build-tarball-android x86_64` for a CI emulator.")]
build-tarball-android targets="":
  pnpm install --ignore-scripts
  pnpm ubrn:android --config ubrn.config.yaml {{ if targets == "" { "" } else { "--targets " + targets } }}
  pnpm pack

[group("Build")]
[doc("Build the tarball for iOS only.")]
build-tarball-ios:
  pnpm install --ignore-scripts
  pnpm ubrn:ios --config ubrn.config.yaml
  pnpm pack

# ubrn 0.31.0-5 stages the module with wasm-bindgen 0.2.100 built in, and the
# crate must link that exact version. Nothing in bdk-ffi needs newer, so the
# lockfile is pinned down before the build. Drop this once ubrn uses the
# installed wasm-bindgen-cli. The same release also leaves `// @ts-nocheck` off
# the generated index.ts, which then fails tsc inside ubrn's own types.
[group("Build")]
[doc("Build the wasm bindings into src/web/generated. Needs the wasm32-unknown-unknown target and a clang with a wasm backend (macOS: brew install llvm).")]
build-wasm:
  cd ./bdk-ffi/bdk-ffi && cargo update -p wasm-bindgen --precise 0.2.100 -p js-sys -p web-sys -p wasm-bindgen-futures
  CC_wasm32_unknown_unknown={{ env("CC_wasm32_unknown_unknown", "/opt/homebrew/opt/llvm/bin/clang") }} \
  AR_wasm32_unknown_unknown={{ env("AR_wasm32_unknown_unknown", "/opt/homebrew/opt/llvm/bin/llvm-ar") }} \
  pnpm ubrn:wasm --config ubrn.config.yaml
  sed -i.bak '1s#^#// @ts-nocheck\n#' src/web/generated/index.ts && rm src/web/generated/index.ts.bak

[group("Build")]
[doc("Build the release tarball with ready for both iOS and Android.")]
build-tarball:
  pnpm install --ignore-scripts
  pnpm ubrn:android --config ubrn.config.yaml
  pnpm ubrn:ios --config ubrn.config.yaml
  pnpm pack

[group("Build")]
[doc("Build the web bindings from scratch and pack them as @bennyblader/bdk-wasm (bennyblader-bdk-wasm-<version>.tgz). Publish with `npm publish bennyblader-bdk-wasm-<version>.tgz`.")]
pack-wasm:
  pnpm install --frozen-lockfile --ignore-scripts
  just submodule-apply-patch
  rustup target add wasm32-unknown-unknown
  just build-wasm
  pnpm prepare
  node scripts/pack-wasm.js

[group("Docs")]
[doc("Serve the docs locally.")]
docs:
  uv run zensical serve

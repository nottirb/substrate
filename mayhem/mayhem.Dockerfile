# Build Stage
FROM ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang curl binutils-dev libunwind8-dev
RUN curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN ${HOME}/.cargo/bin/rustup default nightly
RUN ${HOME}/.cargo/bin/cargo install honggfuzz --version "0.5.54"

## Add source code to the build stage.
ADD . /substrate
WORKDIR /substrate
RUN cd frame/bags-list/fuzzer && \
	RUSTFLAGS="-Znew-llvm-pass-manager=no" HFUZZ_RUN_ARGS="--run_time $run_time --exit_upon_crash" ${HOME}/.cargo/bin/cargo +nightly hfuzz build
RUN cd primitives/arithmetic/fuzzer && \
	RUSTFLAGS="-Znew-llvm-pass-manager=no" HFUZZ_RUN_ARGS="--run_time $run_time --exit_upon_crash" ${HOME}/.cargo/bin/cargo +nightly hfuzz build
RUN cd primitives/npos-elections/fuzzer && \
	RUSTFLAGS="-Znew-llvm-pass-manager=no" HFUZZ_RUN_ARGS="--run_time $run_time --exit_upon_crash" ${HOME}/.cargo/bin/cargo +nightly hfuzz build

# Package Stage
FROM ubuntu:20.04

COPY --from=builder substrate/frame/bags-list/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/bags-list /
COPY --from=builder substrate/primitives/arithmetic/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/normalize /
COPY --from=builder substrate/primitives/arithmetic/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/fixed_point /
# COPY --from=builder substrate/primitives/arithmetic/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/biguint /
# COPY --from=builder substrate/primitives/arithmetic/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/per_thing_rational /
# COPY --from=builder substrate/primitives/arithmetic/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/multiply_by_rational /
COPY --from=builder substrate/primitives/npos-elections/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/reduce /
COPY --from=builder substrate/primitives/npos-elections/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/phragmms_balancing /
# COPY --from=builder substrate/primitives/npos-elections/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/phragmen_balancing /
# COPY --from=builder substrate/primitives/npos-elections/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/phragmen_pjr /
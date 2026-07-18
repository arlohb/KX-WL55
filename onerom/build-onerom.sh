#!/usr/bin/env bash

mkdir output
chmod a+rw output

docker run --rm -v $(pwd)/output:/home/build/output \
    --name onerom-build \
    ghcr.io/piersfinlayson/onerom-build:latest \
    sh -c './clone.sh &&
        cd one-rom/rust/cli && \
        cargo build --release && \
        cd &&
        cp one-rom/rust/target/release/onerom output'

mv output/onerom onerom
rmdir output


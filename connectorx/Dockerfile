FROM python:3.12-slim AS builder

RUN apt update
RUN apt install -y curl

RUN mkdir /wheeler
WORKDIR /wheeler

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="$PATH:/root/.cargo/bin"

RUN rustup install 1.78.0
RUN rustup override set 1.78.0

RUN apt-get install -y git

RUN git clone https://github.com/sfu-db/connector-x.git
WORKDIR /wheeler/connector-x
RUN git checkout tags/v0.3.3

RUN pip install maturin[patchelf]==0.14.15

# Install the dependencies
RUN apt-get install -y clang build-essential libkrb5-dev

RUN maturin build -m connectorx-python/Cargo.toml -i python3.12 --release

FROM builder AS base

COPY --from=builder /wheeler/connector-x/connectorx-python/target/wheels/connectorx-0.3.3-*.whl ./
# RUN pip install connectorx-0.3.3-*.whl

# Copying the wheel into the host system
# the below didn't work for me
# COPY /wheeler/connector-x/connectorx-python/target/wheels/connectorx-* files/connectorx/
# instead use the below to copy the wheel into the host systemcopy # use the below to copy the wheel into the host systemcopy # use the below to copy the wheel into the host system
# docker run --rm -v ./:/root vnijs/connectorx /bin/bash -c "cp *.whl ~/files/connectorx/"


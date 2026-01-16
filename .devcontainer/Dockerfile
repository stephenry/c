ARG VARIANT="jammy"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}
RUN apt-get update \
  && DEBIAN_FRONTEND=noninterative \
    apt-get install --no-install-recommends -y \
      autoconf \
      bc \
      bison \
      build-essential \
      default-jre \
      flex \
      lcov \
      libfl-dev \
      libgoogle-perftools-dev \
      help2man \
      pkg-config \
      gdb \
      cmake \
      python3-dev \
      python3-orderedmultidict \
      python3-pip \
      python3-psutil \
      python3-venv \
      clangd-14 \
      clang-tidy-14 \
      clang-format-14 \
      tclsh \
      swig \
      uuid-dev \
      zlib1g-dev \
      libreadline-dev \
      yosys \
      curl \
      jq \
      tar \
      wget \
      libeigen3-dev \
      tcl-dev \
      tcl-tclreadline \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Switch to vscode user
WORKDIR /tools

# Install poetry
RUN pip install poetry

# Synlig - Download and extract to the tools subdir
RUN wget https://github.com/chipsalliance/synlig/releases/download/2024-12-10-2d838ed/synlig-2d838ed-2024-12-10.tar.gz \
    && tar -xzf synlig-2d838ed-2024-12-10.tar.gz \
    && chown -R vscode synlig/ \
    && rm synlig-2d838ed-2024-12-10.tar.gz
ENV SYNLIG_ROOT=/tools/synlig

# Install volare PDK manager
RUN pip install volare

# CUDD library (dependency for OpenSTA)
RUN git clone https://github.com/davidkebo/cudd.git \
  && cd cudd/cudd_versions \
  && tar -xvf cudd-3.0.0.tar.gz \
  && cd cudd-3.0.0 \
  && ./configure --prefix=/tools/cudd-3.0.0 \
  && make \
  && make install \
  && rm -rf /tools/cudd

# OpenSTA
RUN git clone https://github.com/parallaxsw/OpenSTA \
  && cd OpenSTA \
  && mkdir build && cd build \
  && cmake -DCUDD_DIR=/tools/cudd-3.0.0 .. \
  && make
ENV OPENSTA_ROOT=/tools/OpenSTA

ARG VERILATOR_VER="5.034"
RUN wget https://github.com/verilator/verilator/archive/refs/tags/v${VERILATOR_VER}.tar.gz \
  && tar -zxf v${VERILATOR_VER}.tar.gz \`
  && cd verilator-${VERILATOR_VER} \
  && autoconf \
  && ./configure \
  && make \
  && cd .. \
  && rm -rf v${VERILATOR_VER}.tar.gz
ENV VERILATOR_ROOT=/tools/verilator-${VERILATOR_VER}

# Install Skywater 130nm PDK to user
USER vscode
RUN volare enable --pdk sky130 78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc

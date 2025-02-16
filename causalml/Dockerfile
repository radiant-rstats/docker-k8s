# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM python:3.12.7-slim as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    patch \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Install latest pip and build tools
RUN pip install --upgrade pip setuptools wheel

# Install dependencies with Python 3.12 support
RUN pip install \
    'numpy>=1.26.4' \
    'cython>=3.0.12' \
    'scipy>=1.15.1' \
    'scikit-learn>=1.5.2'


# Update the setup.py file with Python 3.12 compatibility flags
RUN cd causalml/inference/tree/_tree && \
    echo 'import numpy\n\
from numpy.distutils.misc_util import Configuration\n\
import os\n\
\n\
os.environ["CFLAGS"] = "-DPY_CALL_TRAMPOLINE -fno-strict-aliasing"\n\
\n\
def configuration(parent_package="", top_path=None):\n\
    config = Configuration("_tree", parent_package, top_path)\n\
    config.add_extension("_tree",\n\
                      sources=["_tree.pyx"],\n\
                      include_dirs=[numpy.get_include()],\n\
                      define_macros=[(\"PY_CALL_TRAMPOLINE\", None)],\n\
                      extra_compile_args=[\"-fno-strict-aliasing\"])\n\
    return config\n\
\n\
if __name__ == "__main__":\n\
    from numpy.distutils.core import setup\n\
    setup(**configuration(top_path="").todict())' > setup.py

# Set environment variables for the build
ENV CFLAGS="-DPY_CALL_TRAMPOLINE -fno-strict-aliasing"
ENV LDFLAGS="-fno-strict-aliasing"
ENV PYTHONPATH="/build"

# Build wheel with debug output
RUN CYTHON_TRACE=1 python setup.py bdist_wheel -v

# Create a clean final image
FROM scratch as export
COPY --from=builder /build/dist/*.whl .
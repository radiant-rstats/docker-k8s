FROM vnijs/rsm-msba-k8s:2.0.0
USER root

# Install CUDA repository and keys
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg2 \
    && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb \
    && dpkg -i cuda-keyring_1.1-1_all.deb \
    && rm cuda-keyring_1.1-1_all.deb

# Install CUDA 12.8 (system CUDA, which is backward compatible)
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-toolkit-12-8 \
    cuda-libraries-12-8 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set CUDA environment variables
ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}

# add github setup script
COPY files/zsh/github.sh /usr/local/bin/github

EXPOSE 22 8765

CMD ["/usr/local/bin/start-container.sh"]

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
ENV HOME=/home/${NB_USER}
WORKDIR "${HOME}"

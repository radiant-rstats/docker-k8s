# Multi-platform Dockerfile for rsm-msba-k8s
# Supports both ARM64 and AMD64 architectures
# Build with: docker buildx build --platform linux/amd64,linux/arm64 -t your-image:tag .

# Use the latest tag and let Docker buildx handle platform selection automatically
FROM quay.io/jupyter/pyspark-notebook:2024-12-02

USER root

# Define build argument and set it as an environment variable in one step
ARG DOCKERHUB_VERSION
ENV DOCKERHUB_VERSION=${DOCKERHUB_VERSION}

# Get platform info for conditional logic
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Set platform-specific environment variables using RUN with shell conditions
RUN case "${TARGETARCH}" in \
    "arm64") \
    echo "rsm-msba-k8s-arm" > /tmp/dockerhub_name && \
    echo "/usr/lib/jvm/java-17-openjdk-arm64/" > /tmp/java_home && \
    echo "pgweb_linux_arm64_v7.zip" > /tmp/pgweb_file \
    ;; \
    "amd64") \
    echo "rsm-msba-k8s-intel" > /tmp/dockerhub_name && \
    echo "/usr/lib/jvm/java-17-openjdk-amd64/" > /tmp/java_home && \
    echo "pgweb_linux_amd64.zip" > /tmp/pgweb_file \
    ;; \
    *) \
    echo "Unsupported architecture: ${TARGETARCH}" && exit 1 \
    ;; \
    esac

# Set environment variables from the temp files
RUN export DOCKERHUB_NAME=$(cat /tmp/dockerhub_name) && \
    export JAVA_HOME=$(cat /tmp/java_home) && \
    export PGWEB_FILE=$(cat /tmp/pgweb_file) && \
    echo "DOCKERHUB_NAME=$DOCKERHUB_NAME" >> /etc/environment && \
    echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment && \
    echo "PGWEB_FILE=$PGWEB_FILE" >> /etc/environment

# Python env variables
ENV PYARROW_VERSION="20.0.0"

# R and Posit related env variables
ENV QUARTO_VERSION="1.7.32"
ENV R_VERSION=4.4.3
ENV TERM=xterm
ENV R_HOME=/opt/conda/lib/R
ENV PATH="/usr/local/bin:$PATH"

# Postgres env variables
ENV POSTGRES_VERSION=16
ENV PGPASSWORD=postgres

# Jupyter and shell environment setup
ARG RSMBASE=/home/${NB_USER}/.rsm-msba
ENV RSMBASE=${RSMBASE} \
    SHELL=/bin/zsh \
    ZDOTDIR=/home/${NB_USER}/.rsm-msba/zsh

# Add autojump to initial package installation
COPY files/init-apt.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# Install PostgreSQL FIRST (with fixed script that cleans data directory)
COPY files/postgres/install-postgres-fixed.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# THEN copy config files (after directories exist)
COPY files/postgres/postgresql.conf /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf
COPY files/postgres/pg_hba.conf /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf

# Setting condarc for the container
COPY files/conda/condarc /opt/conda/.condarc
RUN fix-permissions "${CONDA_DIR}"

COPY files/install-sshd.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

COPY files/install-quarto.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

COPY files/install-uv.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

COPY files/install-radiant.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# Setup hadoop with platform-specific Java path
# Java path is set via platform detection above
ENV HADOOP_VERSION=3.3.4
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
COPY files/install-hadoop.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# Hadoop configuration
ADD files/scalable_analytics/core-site.xml $HADOOP_HOME/etc/hadoop/
ADD files/scalable_analytics/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
ADD files/scalable_analytics/init-dfs.sh /opt/hadoop/
ADD files/scalable_analytics/start-dfs.sh /opt/hadoop/
ADD files/scalable_analytics/stop-dfs.sh /opt/hadoop/
RUN chown -R ${NB_USER} ${HADOOP_HOME} && \
    chmod 755 ${HADOOP_HOME}/*.sh && \
    chmod 755 /usr/bin/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin

# Install pgweb with platform-specific binary
# Run pgweb from the terminal use pgweb --bind=0.0.0.0 --listen=8000
# Once setup has been run inside the container there should be an alias pgw
RUN . /etc/environment && \
    wget -O pgweb.zip https://github.com/sosedoff/pgweb/releases/download/v0.11.11/$PGWEB_FILE && \
    unzip pgweb.zip -d pgweb_dir && \
    mv pgweb_dir/* /usr/local/bin/pgweb0 && \
    rm -rf pgweb_dir pgweb.zip

# Create log directories with proper permissions
RUN mkdir -p /var/log/postgresql /var/log/sshd && \
    chown postgres:postgres /var/log/postgresql && \
    chmod 750 /var/log/postgresql

# Oh-my-zsh and other zsh setup
COPY files/install-ohmyzsh.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# Copying over CLI scripts (platform-specific launch script)
RUN . /etc/environment && \
    cp launch-${DOCKERHUB_NAME}.sh /opt/launch.sh
COPY files/zsh/zshrc /etc/skel/.zshrc
COPY files/zsh/p10k.zsh /etc/skel/.p10k.zsh
COPY files/zsh/usethis /usr/local/bin/usethis
COPY files/zsh/interactive-usethis.sh /usr/local/bin/iusethis
COPY files/zsh/github.sh /usr/local/bin/github
COPY files/zsh/scripts/radiant.sh /usr/local/bin/radiant
COPY files/zsh/setup.sh /usr/local/bin/setup
COPY files/zsh/menu.sh /usr/local/bin/menu
RUN fix-permissions /etc/skel && \
    fix-permissions /usr/local/bin && \
    chmod 755 /usr/local/bin/*

# Startup script that starts sshd and postgres and manages permissions
COPY files/start-container.sh /usr/local/bin/
COPY files/sshd/sshd_config /etc/ssh/sshd_config
RUN chmod +x /usr/local/bin/start-container.sh

# Setup the GitHub CLI
COPY files/install-gh.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# Setup webscrapers (commented out in original)
# COPY files/install-webscrapers.sh setup.sh
# RUN chmod +x setup.sh && \
#     ./setup.sh && \
#     rm setup.sh

EXPOSE 22 8765

CMD ["/usr/local/bin/start-container.sh"]

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
ENV HOME=/home/${NB_USER}
WORKDIR "${HOME}"

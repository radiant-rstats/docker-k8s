# find all here: https://quay.io/repository/jupyter/pyspark-notebook
# 2025-6-16
# FROM quay.io/jupyter/pyspark-notebook@sha256:b5f757d298647b15ad3f72f893df9895b9dfa4421594c1b2b00e83855cdb3b87
FROM quay.io/jupyter/pyspark-notebook@sha256:30be0eb3354af84b3ccb6a653db86fda19cf1c0c530360702706f00ab7f821f0

USER root

# Define build argument and set it as an environment variable in one step
ARG DOCKERHUB_VERSION
ENV DOCKERHUB_VERSION=${DOCKERHUB_VERSION}
ENV DOCKERHUB_NAME="rsm-msba-k8s-arm"

# python env variables
ENV PYARROW_VERSION="20.0.0"

# R and Posit related env variables
ENV QUARTO_VERSION="1.7.32"
ENV R_VERSION=4.4.3
ENV TERM=xterm
ENV R_HOME=/opt/conda/lib/R
ENV PATH="/usr/local/bin:$PATH"

# postgres env variables
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

COPY files/postgres/postgresql.conf /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf
COPY files/postgres/pg_hba.conf /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf

COPY files/postgres/install-postgres.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

COPY files/install-sshd.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

COPY files/install-quarto.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

COPY files/install-radiant.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# setup hadoop
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-arm64/"
ENV HADOOP_VERSION=3.3.4
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
COPY files/install-hadoop.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# hadoop configuration
ADD files/scalable_analytics/core-site.xml $HADOOP_HOME/etc/hadoop/
ADD files/scalable_analytics/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
ADD files/scalable_analytics/init-dfs.sh /opt/hadoop/
ADD files/scalable_analytics/start-dfs.sh /opt/hadoop/
ADD files/scalable_analytics/stop-dfs.sh /opt/hadoop/
RUN chown -R ${NB_USER} ${HADOOP_HOME} && \
    chmod 755 ${HADOOP_HOME}/*.sh && \
    chmod 755 /usr/bin/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin

# run pgweb from the terminal use pgweb --bind=0.0.0.0 --listen=8000
# once setup has been run inside the container there should be an alias pgw
RUN wget -O pgweb.zip https://github.com/sosedoff/pgweb/releases/download/v0.11.11/pgweb_linux_arm64_v7.zip && \
    unzip pgweb.zip -d pgweb_dir && \
    mv pgweb_dir/* /usr/local/bin/pgweb0 && \
    rm -rf pgweb_dir pgweb.zip

# setting condarc for the container
COPY files/conda/condarc /opt/conda/.condarc
RUN fix-permissions "${CONDA_DIR}"

# Copy the launch script into the image
COPY launch-${DOCKERHUB_NAME}.sh /opt/launch.sh
COPY files/zsh/setup.sh /usr/local/bin/setup
RUN fix-permissions /etc/skel && \
    fix-permissions /usr/local/bin && \
    chmod 755 /usr/local/bin/*

# Create log directories with proper permissions
RUN mkdir -p /var/log/postgresql /var/log/sshd && \
    chown postgres:postgres /var/log/postgresql && \
    chmod 750 /var/log/postgresql

# Oh-my-zsh and other zsh setup
COPY files/install-ohmyzsh.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

COPY files/zsh/zshrc /etc/skel/.zshrc
COPY files/zsh/p10k.zsh /etc/skel/.p10k.zsh
COPY files/zsh/usethis /usr/local/bin/usethis
COPY files/zsh/github.sh /usr/local/bin/github
COPY files/zsh/scripts/radiant.sh /usr/local/bin/radiant
RUN chmod +x /usr/local/bin/radiant

# startup script that starts sshd and postgres and manages permissions
COPY files/start-container.sh /usr/local/bin/
COPY files/sshd/sshd_config /etc/ssh/sshd_config
RUN chmod +x /usr/local/bin/start-container.sh

# setup the GitHub CLI
COPY files/install-gh.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# setup UV
COPY files/install-uv.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# setup webscrapers
COPY files/install-webscrapers.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

EXPOSE 22 8765

CMD ["/usr/local/bin/start-container.sh"]

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
ENV HOME=/home/${NB_USER}
WORKDIR "${HOME}"

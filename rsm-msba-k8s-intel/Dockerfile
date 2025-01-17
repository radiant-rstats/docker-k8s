# find all here: https://quay.io/repository/jupyter/pyspark-notebook?tab=tags
# x86_64-2024-10-28
FROM quay.io/jupyter/pyspark-notebook@sha256:5f93a810a742783edbccb394c51baa5d3a653b64b333880146d7c8adc8ea7ad7 

USER root

# Define build argument and set it as an environment variable in one step
ARG DOCKERHUB_VERSION
ENV DOCKERHUB_VERSION=${DOCKERHUB_VERSION}
ENV DOCKERHUB_NAME="rsm-msba-k8s-intel"

# python env variables
# ENV PANDAS_VERSION="2.2.2"
ENV PYARROW_VERSION="17.0.0"
# needed to install gensim
ENV SCIPY_VERSION="1.12.0"

# R and Posit related env variables
ENV QUARTO_VERSION="1.7.5"
ENV R_VERSION=4.4.2
ENV TERM=xterm
ENV R_HOME=/opt/conda/lib/R
ENV PATH="/usr/local/bin:$PATH"

# postgres env variables
ENV POSTGRES_VERSION=16
ENV PGPASSWORD=postgres

# Jupyter and shell environment setup
ARG PYBASE=/home/${NB_USER}/.rsm-msba
ENV PYBASE=${PYBASE} \
    PYTHONUSERBASE=${PYBASE} \
    POETRY_VERSION="1.8.5" \
    JUPYTER_PATH=${PYBASE}/share/jupyter \
    JUPYTER_DATA_DIR=${PYBASE}/share/jupyter \
    JUPYTER_CONFIG_DIR=${PYBASE}/jupyter \
    JUPYTER_RUNTIME_DIR=/tmp/jupyter/runtime \
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

COPY files/install-python-packages.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

# connectorx is default for sql stuff in polars but is not built for aarch64
# had to do that manually with a docker file
# see https://github.com/sfu-db/connector-x/issues/386
RUN pip install --no-cache-dir --root-user-action=ignore "connectorx==0.3.3"

# setup hadoop
ENV JAVA_HOME "/usr/lib/jvm/java-17-openjdk-amd64/"
ENV HADOOP_VERSION 3.3.4
ENV HADOOP_HOME /opt/hadoop
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
ENV PATH $PATH:$HADOOP_HOME/bin

# run pgweb from the terminal use pgweb --bind=0.0.0.0 --listen=8000
# once setup has been run inside the container there should be an alias pgw
RUN wget -O pgweb.zip https://github.com/sosedoff/pgweb/releases/download/v0.11.11/pgweb_linux_arm64_v7.zip && \
    unzip pgweb.zip -d pgweb_dir && \
    mv pgweb_dir/* /usr/local/bin/pgweb0 && \
    rm -rf pgweb_dir pgweb.zip

# setting condarc for the container
COPY files/conda/condarc /opt/conda/.condarc
RUN fix-permissions "${CONDA_DIR}"
COPY files/conda/ccenv.sh /usr/local/bin/ccenv
COPY files/conda/cl.sh /usr/local/bin/cl
COPY files/conda/cr.sh /usr/local/bin/cr
COPY files/conda/ci.sh /usr/local/bin/ci
COPY files/conda/ce.sh /usr/local/bin/ce

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
COPY files/zsh/clean.sh /usr/local/bin/clean
COPY files/zsh/scripts/radiant.sh /usr/local/bin/radiant
COPY files/zsh/scripts/gitgadget.sh /usr/local/bin/gitgadget
RUN chmod +x /usr/local/bin/radiant /usr/local/bin/gitgadget

# startup script that starts sshd and postgres and manages permissions
COPY files/start-container.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-container.sh

EXPOSE 22 8765

CMD ["/usr/local/bin/start-container.sh"]

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
ENV HOME /home/${NB_USER}
WORKDIR "${HOME}"
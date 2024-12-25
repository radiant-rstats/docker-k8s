# find all here: https://quay.io/repository/jupyter/pyspark-notebook?tab=tags
# x86_64-2024-10-28
FROM quay.io/jupyter/pyspark-notebook@sha256:5f93a810a742783edbccb394c51baa5d3a653b64b333880146d7c8adc8ea7ad7 
# for the arm version use: sha256:b5f757d298647b15ad3f72f893df9895b9dfa4421594c1b2b00e83855cdb3b87

ARG DOCKERHUB_VERSION_UPDATE
ENV DOCKERHUB_VERSION=$DOCKERHUB_VERSION_UPDATE
ENV DOCKERHUB_NAME="rsm-msba-k8s-intel"

# python env variables
ENV PANDAS_VERSION="2.2.2"
ENV PYARROW_VERSION="16.1.0"
# needed to install gensim
ENV SCIPY_VERSION="1.12.0"

# postgres env variables
ENV POSTGRES_VERSION=16
ENV PGPASSWORD=postgres

# Jupyter and shell environment setup
ARG PYBASE=/home/${NB_USER}/.rsm-msba
ENV PYBASE=${PYBASE} \
    PYTHONUSERBASE=${PYBASE} \
    JUPYTER_PATH=${PYBASE}/share/jupyter \
    JUPYTER_DATA_DIR=${PYBASE}/share/jupyter \
    JUPYTER_CONFIG_DIR=${PYBASE}/jupyter \
    JUPYTER_RUNTIME_DIR=/tmp/jupyter/runtime \
    RSTUDIO_WHICH_R=/usr/local/bin/R \
    SHELL=/bin/zsh \
    ZDOTDIR=/home/${NB_USER}/.rsm-msba/zsh

COPY files/init-apt.sh setup.sh
RUN chmod +x setup.sh \
    && ./setup.sh \
    && rm setup.sh

COPY files/postgres/postgresql.conf /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf
COPY files/postgres/pg_hba.conf /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf

COPY files/postgres/install-postgres.sh setup.sh
RUN chmod +x setup.sh \
    && ./setup.sh \
    && rm setup.sh

COPY files/install-sshd.sh setup-ssh.sh
RUN chmod +x setup-ssh.sh \
    && ./setup-ssh.sh \
    && rm setup-ssh.sh

# startup script that starts sshd and postgres and manages permissions
COPY files/start-container.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-container.sh

# Create log directories with proper permissions
RUN mkdir -p /var/log/postgresql /var/log/jupyter /var/log/sshd && \
    chown postgres:postgres /var/log/postgresql && \
    chmod 750 /var/log/postgresql && \
    chown ${NB_USER}:users /var/log/jupyter && \
    chmod 750 /var/log/jupyter

EXPOSE 22 8765 8989 8181 8282

CMD ["/usr/local/bin/start-container.sh"]

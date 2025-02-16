FROM vnijs/rsm-msba-k8s-intel:1.1.0

USER root

ARG DOCKERHUB_VERSION
ENV DOCKERHUB_VERSION=${DOCKERHUB_VERSION}
ENV DOCKERHUB_NAME="rsm-msba-k8s-gpu"

COPY files/install-cuda.sh setup.sh
RUN chmod +x setup.sh && \
    ./setup.sh && \
    rm setup.sh

EXPOSE 22 8765

CMD ["/usr/local/bin/start-container.sh"]

# switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
ENV HOME /home/${NB_USER}
WORKDIR "${HOME}"
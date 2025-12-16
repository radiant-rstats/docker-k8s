IMAGE_VERSION="latest"
NB_USER="jovyan"
ID="vnijs"
if [ "$(uname -m)" = "arm64" ]; then
    LABEL="rsm-msba-k8s-arm"
else
    LABEL="rsm-msba-k8s-intel"
fi
NETWORK="rsm-network"
IMAGE=${ID}/${LABEL}
HOMEDIR=/Users/vnijs
TIMEZONE=America/Los_Angeles
POSTGRES_VERSION=16
PGPASSWORD=postgres
MNT=""
NB_USER=jovyan

{
    # check if network already exists
    docker network inspect ${NETWORK} >/dev/null 2>&1
} || {
    # if network doesn't exist create it
    echo "--- Creating docker network: ${NETWORK} ---"
    docker network create ${NETWORK}
}

docker run --name ${LABEL} --net ${NETWORK} \
    -p 127.0.0.1:2222:22 -p 127.0.0.1:8765:8765 -p 127.0.0.1:8181:8181 -p 127.0.0.1:8282:8282 \
    -e TZ=${TIMEZONE} \
    -v "${HOMEDIR}":/home/${NB_USER} $MNT \
    -v pg_data:/var/lib/postgresql/${POSTGRES_VERSION}/main \
    ${IMAGE}:${IMAGE_VERSION}

# docker run -d --name ${LABEL} --net ${NETWORK} \
#     -p 127.0.0.1:2222:22 -p 127.0.0.1:8765:8765 -p 127.0.0.1:8181:8181 -p 127.0.0.1:8282:8282 -p 127.0.0.1:8000:8000 \
#     -e TZ=${TIMEZONE} \
#     -v "${HOMEDIR}":/home/${NB_USER} $MNT \
#     -v pg_data:/var/lib/postgresql/${POSTGRES_VERSION}/main \
#     ${IMAGE}:${IMAGE_VERSION}

# docker exec -it ${LABEL} /bin/zsh

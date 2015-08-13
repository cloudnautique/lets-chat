#!/bin/bash
set -e

IMAGE=cloudnautique/lets-chat:${DRONE_BUILD_NUMBER:-latest}
export IMAGE

wrapdocker >/dev/null 2>&1

docker build -t $IMAGE -f docker/Dockerfile .

if [[ "$DOCKER_HUB_USER" && -n "$DOCKER_HUB_PASS" && -n "$DOCKER_HUB_EMAIL" ]]; then
    docker login -u "$DOCKER_HUB_USER" -p "$DOCKER_HUB_PASS" -e "$DOCKER_HUB_EMAIL"

    echo Pushing $IMAGE
    docker push $IMAGE
fi

if [[ -n "$RANCHER_SECRET_KEY" ]]; then
    mkdir -p dist
    sed 's!sdelements/lets-chat:latest!'$IMAGE'!' docker/docker-compose.yml > dist/docker-compose.yml
    curl -X GET -o rancher-compose.tar.gz -L https://github.com/rancher/rancher-compose/releases/download/v0.2.5/rancher-compose-linux-amd64-v0.2.5.tar.gz
    ls ./
    tar -xvzf ./rancher-compose.tar.gz -C /usr/bin/
    ln -s /usr/bin/rancher-compose-v0.2.5/rancher-compose /usr/bin/rancher-compose
    sed -i "s@APPIMAGE@${IMAGE}@" dist/docker-compose.yml
    rancher-compose -f dist/docker-compose.yml -p lets-chat-${DRONE_BUILD_NUMBER} up -d
fi

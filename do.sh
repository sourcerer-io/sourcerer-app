#!/bin/bash

# Copyright 2017 Sourcerer, Inc. All Rights Reserved.
# Author: Maxim Rusak (maxim@sourcerer.io)

set -x

fn_exists() {
  type $1 2>/dev/null | grep -q 'is a function'
}

COMMAND=$1
shift
ARGUMENTS=${@}

CONTAINER_TAG="${CONTAINER_TAG:-latest}"
NAMESPACE="${NAMESPACE:-sandbox}"
LOG="${LOG:-debug}"
VOLUME="${BUILD_VOLUME:-$PWD}"
PROJECT=sourcerer-app
PORT=3182
REPO_NAME=gcr.io/sourcerer-1377/$PROJECT:$CONTAINER_TAG
GRADLE_VERSION=4.2.0

#--------------------#
#----- Commands -----#
#--------------------#

# run only inside build container
build_jar_inside() {
  if [ "${NAMESPACE}" == "sandbox" ]; then
    API="https://sandbox.sourcerer/api/commit"
    LOG="debug"
  elif [ "${NAMESPACE}" == "staging" ]; then
    API="https://staging.sourcerer/api/commit"
    LOG="info"
  elif [ "${NAMESPACE}" == "local" ]; then
    API="http://localhost:3181"
    LOG="debug"
  else
    API="https://sourcerer.io/api/commit"
    LOG="info"
  fi
  gradle -Penv=${NAMESPACE} -Plog=${LOG} -Papi=${API} build
}

build_jar() {
  docker run -i -v ${VOLUME}:/home/gradle/app --workdir=/home/gradle/app \
    -e LOG=${LOG} -e NAMESPACE=${NAMESPACE} \
    gradle:${GRADLE_VERSION} \
    ./do.sh build_jar_inside
}

build_prod_inside() {
  docker build -t ${REPO_NAME} .
}

deploy() {
  source ./deploy/${NAMESPACE}_env.sh
  envsubst < ./deploy/sourcerer-app.yaml > /tmp/deploy.yaml
  kubectl --namespace=${NAMESPACE} apply -f /tmp/deploy.yaml
}

######################

run_jar() {
  docker run -i -v ${VOLUME}:/app --workdir=/app gradle:${GRADLE_VERSION} \
    java -jar build/libs/app.jar
}

run_prod() {
  docker run -i -p ${PORT}:80 ${REPO_NAME}
}

push() {
  gcloud docker -- push ${REPO_NAME}
}

#---------------------#
#----- Execution -----#
#---------------------#

fn_exists ${COMMAND}
if [ $? -eq 0 ]; then
  ${COMMAND} ${ARGUMENTS}
else
  echo "Command not found"
fi

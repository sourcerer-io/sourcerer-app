#!/bin/bash

#-------------------#
#----- Helpers -----#
#-------------------#

usage() {
    echo "$0 [COMMAND] [ARGUMENTS]"
    echo "  Commands:"
    echo "  - build_jar: build jar"
    echo "  - build_prod_inside: build nginx container"
    echo "  - run_jar: run jar"
    echo "  - run_prod: start nginx container"
}

fn_exists() {
    type $1 2>/dev/null | grep -q 'is a function'
}

COMMAND=$1
shift
ARGUMENTS=${@}

TAG="${CONTAINER_TAG:-latest}"
NAMESPACE="${NAMESPACE:-staging}"
ENV="${ENV:-development}"
VOLUME="${BUILD_VOLUME:-$PWD}"
PROJECT=sourcerer-app
PORT=3182
REPO_NAME=gcr.io/sourcerer-1377/$PROJECT:$TAG
GRADLE_VERSION=4.2.0

#--------------------#
#----- Commands -----#
#--------------------#

# run only inside build container
build_jar_inside() {
  gradle build -Penv $ENV
}

build_jar() {
  docker run -i -v $VOLUME:/home/gradle/app --workdir=/home/gradle/app -e ENV=$ENV \
  gradle:$GRADLE_VERSION \
    ./do.sh build_jar_inside
}

build_prod_inside() {
  docker build -t $REPO_NAME .
}

deploy() {
  sed "s#CONTAINER_TAG#$TAG#" ./deploy/sourcerer-app-$NAMESPACE.yaml > /tmp/deploy.yaml
  kubectl --namespace=$NAMESPACE apply -f /tmp/deploy.yaml
}

######################

run_jar() {
  docker run -i -v $VOLUME:/app --workdir=/app gradle:$GRADLE_VERSION \
    java -jar build/libs/app.jar
}

run_prod() {
  docker run -i -p $PORT:80 $REPO_NAME
}

push() {
  gcloud docker -- push $REPO_NAME
}

#---------------------#
#----- Execution -----#
#---------------------#

fn_exists $COMMAND
if [ $? -eq 0 ]; then
    $COMMAND $ARGUMENTS
else
    usage
fi

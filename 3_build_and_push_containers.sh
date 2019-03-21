#!/bin/bash
set -euo pipefail

. utils.sh

docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH

announce "Building and pushing cityapp images."

  pushd build
    ./build.sh

    test_app_image_registry_name=$(platform_image $TEST_APP_IMAGE)
    docker tag $TEST_APP_IMAGE $test_app_image_registry_name
    docker push $test_app_image_registry_name
  popd

announce "Pusing conjur-kubernetes-authenticator image"

authenticator_image_registry_name=$(platform_image conjur-kubernetes-authenticator:latest)
docker tag $AUTHENTICATOR_IMAGE $authenticator_image_registry_name
docker push $authenticator_image_registry_name

announce "Pusing secretless-broker image"

secretless_image_registry_name=$(platform_image secretless-broker:latest)
docker tag $SECRETLESS_IMAGE $secretless_image_registry_name
docker push $secretless_image_registry_name

#!/bin/bash
set -eo pipefail

. utils.sh

main() {
  announce "Deploying test apps for $TEST_APP_NAMESPACE_NAME."

  set_namespace $TEST_APP_NAMESPACE_NAME
  init_registry_creds
  init_connection_specs

  IMAGE_PULL_POLICY='Always'

  deploy_app cityapp-hardcode
  deploy_app cityapp-restapi-sidecar
  deploy_app cityapp-summon-init
  deploy_app cityapp-secretless
}

###########################
init_registry_creds() {
  if [ $PLATFORM = 'kubernetes' ]; then
    if ! [ "${DOCKER_EMAIL}" = "" ]; then
      announce "Creating image pull secret."
    
      kubectl delete --ignore-not-found secret dockerpullsecret

      kubectl create secret docker-registry dockerpullsecret \
        --docker-server=$DOCKER_REGISTRY_URL \
        --docker-username=$DOCKER_USERNAME \
        --docker-password=$DOCKER_PASSWORD \
        --docker-email=$DOCKER_EMAIL
    fi
  elif [ $PLATFORM = 'openshift' ]; then
    announce "Creating image pull secret."
    
    $cli delete --ignore-not-found secrets dockerpullsecret
  
    $cli secrets new-dockercfg dockerpullsecret \
      --docker-server=${DOCKER_REGISTRY_PATH} \
      --docker-username=_ \
      --docker-password=$($cli whoami -t) \
      --docker-email=_
  
    $cli secrets add serviceaccount/default secrets/dockerpullsecret --for=pull    
  fi
}

###########################
init_connection_specs() {
  test_app_image_registry_name=$(platform_image $TEST_APP_IMAGE)

  conjur_appliance_url=https://conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local/api
  conjur_authenticator_url=https://conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local/api/authn-k8s/$AUTHENTICATOR_ID
  conjur_authn_login_prefix=host/conjur/authn-k8s/$AUTHENTICATOR_ID/apps/$TEST_APP_NAMESPACE_NAME

  authenticator_image_registry_name=$(platform_image conjur-kubernetes-authenticator:latest)
  secretless_image_registry_name=$(platform_image secretless-broker:latest)

}

###########################
deploy_app() {
  if [[ $# != 1 ]]; then
    printf "Error in %s/%s - expecting 1 arg.\n" $(pwd) $0
    exit -1
  fi
  APP_NAME=$1

  $cli delete service $TEST_APP_NAMESPACE_NAME --ignore-not-found
  $cli delete route $TEST_APP_NAMESPACE_NAME --ignore-not-found
  $cli delete service $APP_NAME --ignore-not-found
  $cli delete route $APP_NAME --ignore-not-found
  $cli delete --ignore-not-found \
    deployment/$APP_NAME \
    serviceaccount/$APP_NAME
  $cli delete configmap $APP_NAME-config --ignore-not-found

  $cli delete --ignore-not-found deploymentconfig/$APP_NAME
  echo "Wait 5 second for deletion to complete"
  sleep 5

#Create configmap for secretless broker if APP_NAME contain secretless

  if [[ $APP_NAME == *"secretless"* ]]; then

    mkdir -p ./etc/generated

    sed -e "s#{{ DB_ADDRESS }}#$DB_ADDRESS#g" ./etc/template/secretless.yml |
      sed -e "s#{{ DB_ADDRESS }}#$DB_ADDRESS#g" |
      sed -e "s#{{ DB_PORT }}#$DB_PORT#g" |
      sed -e "s#{{ DB_NAME }}#$DB_NAME#g" |
      sed -e "s#{{ DB_USERNAME_CONJUR_VAR }}#$DB_USERNAME_CONJUR_VAR#g" |
      sed -e "s#{{ DB_PASSWORD_CONJUR_VAR }}#$DB_PASSWORD_CONJUR_VAR#g" > ./etc/generated/secretless.yml

    $cli create configmap $APP_NAME-config \
      --from-file=etc/generated/secretless.yml
  fi

#Create configmap for summon if APP_NAME contain summon

  if [[ $APP_NAME == *"summon"* ]]; then

    mkdir -p ./etc/generated

    sed -e "s#{{ DB_ADDRESS }}#$DB_ADDRESS#g" ./etc/template/secrets.yml |
      sed -e "s#{{ DB_ADDRESS }}#$DB_ADDRESS#g" |
      sed -e "s#{{ DB_PORT }}#$DB_PORT#g" |
      sed -e "s#{{ DB_NAME }}#$DB_NAME#g" |
      sed -e "s#{{ DB_USERNAME_CONJUR_VAR }}#$DB_USERNAME_CONJUR_VAR#g" |
      sed -e "s#{{ DB_PASSWORD_CONJUR_VAR }}#$DB_PASSWORD_CONJUR_VAR#g" > ./etc/generated/secrets.yml

    $cli create configmap $APP_NAME-config \
      --from-file=etc/generated/secrets.yml
  fi


  mkdir -p ./openshift/generated

  sed -e "s#{{ TEST_APP_DOCKER_IMAGE }}#$test_app_image_registry_name#g" ./openshift/template/$APP_NAME.yml.template |
    sed -e "s#{{ AUTHENTICATOR_DOCKER_IMAGE }}#$authenticator_image_registry_name#g" |
    sed -e "s#{{ SECRETLESS_DOCKER_IMAGE }}#$secretless_image_registry_name#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    sed -e "s#{{ CONJUR_VERSION }}#$CONJUR_VERSION#g" |
    sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
    sed -e "s#{{ CONJUR_AUTHN_LOGIN_PREFIX }}#$conjur_authn_login_prefix#g" |
    sed -e "s#{{ CONJUR_APPLIANCE_URL }}#$conjur_appliance_url#g" |
    sed -e "s#{{ CONJUR_AUTHN_URL }}#$conjur_authenticator_url#g" |
    sed -e "s#{{ TEST_APP_NAMESPACE_NAME }}#$TEST_APP_NAMESPACE_NAME#g" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ CONFIG_MAP_NAME }}#$TEST_APP_NAMESPACE_NAME#g" |
    sed -e "s#{{ OSHIFT_CLUSTER_URL }}#$OSHIFT_CLUSTER_URL#g" |
    sed -e "s#{{ DB_ADDRESS }}#$DB_ADDRESS#g" |
    sed -e "s#{{ DB_PORT }}#$DB_PORT#g" |
    sed -e "s#{{ DB_NAME }}#$DB_NAME#g" |
    sed -e "s#{{ DB_USERNAME }}#$DB_USERNAME#g" |
    sed -e "s#{{ DB_PASSWORD }}#$DB_PASSWORD#g" |
    sed -e "s#{{ DB_USERNAME_CONJUR_VAR }}#$DB_USERNAME_CONJUR_VAR#g" |
    sed -e "s#{{ DB_PASSWORD_CONJUR_VAR }}#$DB_PASSWORD_CONJUR_VAR#g" |
    sed -e "s#{{ CONJUR_VERSION }}#'$CONJUR_VERSION'#g" > ./openshift/generated/$APP_NAME.yml


  $cli create -f ./openshift/generated/$APP_NAME.yml

  echo "Test app $APP_NAME deployed."
}

main $@

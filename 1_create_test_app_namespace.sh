#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Creating Test App namespace."

if [[ $PLATFORM == openshift ]]; then
  $cli login -u $OSHIFT_CLUSTER_ADMIN_USERNAME
fi

set_namespace default

if has_namespace "$TEST_APP_NAMESPACE_NAME"; then
  echo "Namespace '$TEST_APP_NAMESPACE_NAME' exists, not going to create it."
  set_namespace $TEST_APP_NAMESPACE_NAME
else
  echo "Creating '$TEST_APP_NAMESPACE_NAME' namespace."

  if [ $PLATFORM = 'kubernetes' ]; then
    $cli create namespace $TEST_APP_NAMESPACE_NAME
  elif [ $PLATFORM = 'openshift' ]; then
    $cli new-project $TEST_APP_NAMESPACE_NAME
  fi
  
  set_namespace $TEST_APP_NAMESPACE_NAME
fi

$cli delete --ignore-not-found rolebinding app-conjur-authenticator-role-binding-$CONJUR_NAMESPACE_NAME

sed -e "s#{{ TEST_APP_NAMESPACE_NAME }}#$TEST_APP_NAMESPACE_NAME#g" openshift/app-conjur-authenticator-role-binding.yml |
  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" |
  $cli create -f -

if [[ $PLATFORM == openshift ]]; then
  # add permissions for Conjur admin user
  $cli adm policy add-role-to-user system:registry $OSHIFT_CONJUR_ADMIN_USERNAME
  $cli adm policy add-role-to-user system:image-builder $OSHIFT_CONJUR_ADMIN_USERNAME

  $cli adm policy add-role-to-user admin $OSHIFT_CONJUR_ADMIN_USERNAME -n default
  $cli adm policy add-role-to-user admin $OSHIFT_CONJUR_ADMIN_USERNAME -n $TEST_APP_NAMESPACE_NAME
  echo "Logging in as Conjur Openshift admin. Provide password as needed."
  $cli login -u $OSHIFT_CONJUR_ADMIN_USERNAME
fi

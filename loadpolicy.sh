#!/bin/bash
set -euo pipefail

. utils.sh

announce "Generating Conjur policy."

pushd policy
  mkdir -p ./generated

  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" ./template/cluster-authn-svc.template.yml > ./generated/cluster-authn-svc.yml


  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" ./template/projects-authn.template.yml |
    sed -e "s#{{ TEST_APP_NAMESPACE_NAME }}#$TEST_APP_NAMESPACE_NAME#g" > ./generated/projects-authn.yml


  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" ./template/app-identity.template.yml |
    sed -e "s#{{ TEST_APP_NAMESPACE_NAME }}#$TEST_APP_NAMESPACE_NAME#g" > ./generated/app-identity.yml


  sed -e "s#{{ VCS_VAULT }}#$VCS_VAULT#g" ./template/safe-permission.yml |
    sed -e "s#{{ VCS_LOB }}#$VCS_LOB#g" |
    sed -e "s#{{ VCS_SAFE }}#$VCS_SAFE#g" > ./generated/safe-permission.yml
popd


announce "Loading Conjur policy."

# Create the random database password

sudo docker run --rm -v $PWD/policy:/root -it cyberark/conjur-cli:5 init -u https://$CONJUR_MASTER_DNS_NAME -a $CONJUR_ACCOUNT --force=yes
sudo docker run --rm -v $PWD/policy:/root -it cyberark/conjur-cli:5 authn login -u admin -p $CONJUR_ADMIN_PASSWORD
sudo docker run --rm -v $PWD/policy:/root -it cyberark/conjur-cli:5 policy load root /root/generated/projects-authn.yml
sudo docker run --rm -v $PWD/policy:/root -it cyberark/conjur-cli:5 policy load root /root/generated/cluster-authn-svc.yml
sudo docker run --rm -v $PWD/policy:/root -it cyberark/conjur-cli:5 policy load root /root/generated/app-identity.yml
sudo docker run --rm -v $PWD/policy:/root -it cyberark/conjur-cli:5 policy load root /root/generated/safe-permission.yml

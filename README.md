# CityApp Demo App
A simple Ruby  application to demonstrate how applicaton in OpenShift environment can fetch database credential when application running in OpenShift environment

This app respond to web request with a random city name and population info from MySQL database. 

## Prerequisite
1. A Conjur V5 Cluster with Followers in OpenShift   
refer to https://github.com/jeepapichet/conjur-openshift-follower-deploy to deploy followers in openshift
2. MySQL Database with sample world database  
refer to https://dev.mysql.com/doc/world-setup/en/
3. MySQL account for application is available as secret in Conjur
4. Docker host with docker-compose installed

## Running the demo

### Running in Dev Environment

A docker-compose is prepared which will start application in dev environment. 
This start application on local docker host and connect to test mysql database which run in another container.

1. run `docker-compose build` to build cityapp image. This will create `cityapp:latest` image
2. Start this application by executing `docker-compose up`
3. Verify that the application is running by browse to your docker host on port 3000 or use `curl your-docker-host:3000`
4. You may modify ruby application in `build/cityapp.rb` i.e. reformat html output format then rebuild and retest the app
5. After finish, clean up test containers using  `docker-compose down`


### Running in OpenShift Environment

Now we will deploy the application in OpenShift (as production) and will fetch city data from production database.
The same container image `cityapp:latests` will be deployed in OpenShift with Conjur Authenticator Sidecar. Application fetch database username/password from Conjur using access token which is made available transparently by Conjur authenticator sidecar.

1. Modify `policy/safe-permission.yml` with appropriate vault synchronized safe name
2. Load policy by running `./loadpolicy.sh`
3. Initialize CA of k8s authenticator service if you have not already done so
```docker exec conjur-master chpst -u conjur conjur-plugin-service possum rake authn_k8s:ca_init["conjur/authn-k8s/sg-cluster"]```
Replace sg-cluster with your cluster id
4. Modify `bootstrap.env` per your environment and run `source bootstrap.env` to load parameters  
5. Modify openshift deployment yaml template in `openshift/template/*.yml` per your environment  
       - host under route definition - hostname to access test application on openshift  
       - DBAddress - hostname or address of production database  
       - DBName - database name of production database e.g. world  
       - DBUsername_CONJUR_VAR - Conjur variable reference to production database username  
       - DBPassword_CONJUR_VAR - Conjur variable reference to production database password  
6. Follow the deployment script from step 0 - 4
7. The test web application should now be availble via url defined in previous step

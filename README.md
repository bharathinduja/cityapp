# CityApp Demo App
A simple Ruby  application to demonstrate how to leverage Conjur to secure database credential when application running in OpenShift environment

This app respond to web request with a random city name and population info from MySQL database. 


## Prerequisite
1. A Conjur V5 Cluster with Followers in OpenShift - refer to https://github.com/jeepapichet/ to deploy follower for openshift authenticator
2. MySQL Database installed with sample world database
refer to https://dev.mysql.com/doc/world-setup/en/
3. MySQL account for application is available as secrets in Conjur.
4. Docker host with docker-compose installed

## Running the demo

### Running in Dev Environment

A docker-compose is prepared which will start application in dev environment. 
This start application on local docker host and connect to test mysql database which run in another container.

1. run `docker-compose build` to build cityapp image. This will create `cityapp:latest` image
2. Start this application by executing `docker-compose up`
3. Verify that the application is running by browse to your docker host on port 3000 or use `curl your-docker-host:3000`
4. You may modify the application in `build/cityapp.rb` i.e. reformat output and and re do the test
5. After finish teseting, clean up container by executing `docker-compose down`


### Running in OpenShift Environment
Now we will deploy the application in OpenShift (as production) and will fetch city data from production database.
The same container image `cityapp:latests` will be deployed in OpenShift with Conjur Authenticator Sidecar. Application fetch database username/password from Conjur using access token which is made available transparently by Conjur authenticator sidecar.

1. Modify `conjur-cityapp-policy.yml` with appropriate clustername and secret variable and load it to your Conjur Master 
2. Modify `bootstrap.env` per your environment and run `source bootstrap.env` to load parameters
3. Modify openshift deployment yaml file in `openshift/city-restapi-sidecar` per your environment. 
       - host under route definition - this is url to accesst test application on openshift
       - DBAddress - Address or hostname of production database
       - DBName - Database name of production database e.g. world
       - DBUsername_CONJUR_VAR - Conjur variable reference to production database username
       - DBPassword_CONJUR_VAR - Conjur variable reference to production database password
4. Follow the deployment script from step 0 - 4
5. The test web application should now be availble via url defined in previous step


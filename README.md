# cityapp Demo App
This is a simple Ruby demo application to show how to secure database secret with Conjur in OpenShift environment

This app reply to web query with a random city name and its population from database. 
The demo start with application running locally on dev environment and connect to local test mysql database which also run as container.

Once developer commit and to release the code, the same container image will be deployed in OpenShift with Conjur Authenticator Sidecar. Application will fetch database username/password from Conjur using Conjur access token provided by Conjur authenticator sidecar.

##Prerequisite
1. A Conjur V5 Cluster with Followers in OpenShift - refer to https://github.com/jeepapichet/ to deploy follower for openshift authenticator
2. MySQL Database installed with sample world database
refer to https://dev.mysql.com/doc/world-setup/en/
3. MySQL account for application is available as secrets in Conjur.
4. Conjur already loaded with policy to allow cityapp openshift namespace access to MySQL account in Conjur.
5. Docker host with docker-compose installed


##Running the demo
###Running in Dev Environment
A docker-compose is prepared which will start dev mysql database to test web application

1. run `docker-compose build` to build cityapp image. This will create image under cityapp:latest
2. Start the app in dev environment by executing `docker-compose up`
3. Verify that the application is running by browse to your docker host on port 3000 or use `curl your-docker-host:3000`
4. You may modify the application in `build/cityapp.rb` i.e. reformat output and and re do the test


###Running in OpenShift Environmetn
Now we will deploy the application in OpenShift (as production) and will fetch data from production database.

1. Modify `bootstrap.env` per your environment
2. Modify openshift deployment yaml file in `openshift/city-restapi-sidecar` per your environment. 
       - host under route definition - this is url to  accesst test application on openshift
       - DBAddress - Address or hostname of production database
       - DBName - Database name of production database e.g. world
       - DBUsername_CONJUR_VAR - Conjur variable reference to production database username
       - DBPassword_CONJUR_VAR - Conjur variable reference to production database password
3. Run `source bootstrap.env` to load parameter
4. Follow the deployment script from step 0 - 4
5. Our web application should be availble in [your-cluster-name].

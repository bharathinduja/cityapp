FROM ruby:2.3.8 as app-builder
MAINTAINER CyberArk
LABEL builder="app-builder"

#---some useful tools for interactive usage---#
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl

#---install summon and summon-conjur---#
RUN curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh \
      | env TMPDIR=$(mktemp -d) bash && \
    curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/master/install.sh \
      | env TMPDIR=$(mktemp -d) bash
# as per https://github.com/cyberark/summon#linux
# and    https://github.com/cyberark/summon-conjur#install
ENV PATH="/usr/local/lib/summon:${PATH}"

# ============= MAIN CONTAINER ============== #

FROM ruby:2.3.8
RUN apt-get update -y
RUN apt-get install -y apt-file
RUN apt-file update 
RUN apt-get install -y vim 

RUN gem install -N activesupport --version 4.2.7.1
RUN gem install -N conjur-api conjur-cli sinatra
RUN gem install mysql2 --platform=ruby

#---copy summon into image---#
COPY --from=app-builder /usr/local/lib/summon /usr/local/lib/summon
COPY --from=app-builder /usr/local/bin/summon /usr/local/bin/summon

WORKDIR /usr/src

COPY cityapp.rb cityapp_summon.rb secrets.yml printvars.sh /usr/src/


ENV PORT 3000
EXPOSE 3000

CMD [ "ruby", "/usr/src/cityapp.rb", "-o", "0.0.0.0" ]
#CMD [ "sleep", "infinity" ]


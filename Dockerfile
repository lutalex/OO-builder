FROM timbru31/java-node:17-jdk-14
RUN apt-get -y update
RUN apt-get -y install git
VOLUME ["/out"]
COPY docker-entypoint.sh .
ENTRYPOINT ["/docker-entypoint.sh"]
FROM node:10
VOLUME ["/out"]
COPY docker-entypoint.sh .
ENTRYPOINT ["/docker-entypoint.sh"]
FROM node:14
VOLUME ["/out"]
COPY docker-entypoint.sh .
ENTRYPOINT ["/docker-entypoint.sh"]
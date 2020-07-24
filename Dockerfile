FROM alpine:3.9.5

RUN apk update && apk add \
    bash \
    curl \
    subversion

RUN echo "PS1='\n\[\e[32m\]\u \[\e[33m\]in \w\[\e[0m\] \n> '" >> ~/.bashrc
ENTRYPOINT [ "bash" ]

WORKDIR /usr/local/src

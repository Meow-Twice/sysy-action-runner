# based on python:3.8-slim-buster
FROM sysy-test:latest

ARG url
ARG token
ARG name
# same with host user
ARG uid

COPY actions-runner /actions-runner
WORKDIR /actions-runner

RUN apt-get update
RUN ./bin/installdependencies.sh

# create a non-root user
RUN useradd git -d /home/git -m -s /bin/bash -u ${uid}
RUN chown git /actions-runner && chgrp git /actions-runner
USER git

RUN ./config.sh --unattended --url ${url} --token ${token} --name ${name} --labels sysy-runner --work /home/git/runner

ENTRYPOINT [ "bin/Runner.Listener", "run" ]

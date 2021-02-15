FROM docker:19.03.11 as static-docker-source

FROM debian:buster
ARG CLOUD_SDK_VERSION=318.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV PATH "$PATH:/opt/google-cloud-sdk/bin/"
COPY --from=static-docker-source /usr/local/bin/docker /usr/local/bin/docker
RUN apt-get -qqy update && apt-get install -qqy \
        wget \
        curl \
        python3-dev \
        python3-crcmod \
        python-crcmod \
        apt-transport-https \
        lsb-release \
        openssh-client \
        git \
        make \
        gnupg && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-python=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-python-extras=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-java=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-go=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datalab=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datastore-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-pubsub-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-bigtable-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-firestore-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-spanner-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-cbt=${CLOUD_SDK_VERSION}-0 \
        kubectl && \
    gcloud --version && \
    docker --version && kubectl version --client
RUN apt-get install -qqy \
        gcc \
        python3-pip
RUN git config --system credential.'https://source.developers.google.com'.helper gcloud.sh

RUN apt-get -y --only-upgrade install google-cloud-sdk-firestore-emulator google-cloud-sdk-app-engine-go google-cloud-sdk-datalab google-cloud-sdk-anthos-auth google-cloud-sdk-pubsub-emulator google-cloud-sdk-kind google-cloud-sdk-app-engine-python-extras google-cloud-sdk-app-engine-java google-cloud-sdk-datastore-emulator google-cloud-sdk-skaffold google-cloud-sdk-app-engine-python google-cloud-sdk-bigtable-emulator google-cloud-sdk google-cloud-sdk-cloud-build-local google-cloud-sdk-minikube kubectl google-cloud-sdk-cbt google-cloud-sdk-app-engine-grpc google-cloud-sdk-spanner-emulator google-cloud-sdk-kpt

USER 0
# Set permissions on /etc/passwd and /home to allow arbitrary users to write
COPY --chown=0:0 entrypoint.sh /
RUN mkdir -p /home/user && chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home && chmod +x /entrypoint.sh

# Install chectl
RUN curl -sL  https://www.eclipse.org/che/chectl/ | bash

# Install common terminal editors in container to aid development process
COPY install-editor-tooling.sh /tmp
RUN /tmp/install-editor-tooling.sh && rm -f /tmp/install-editor-tooling.sh

USER 10001
ENV HOME=/home/user
ENV SHELL=/bin/bash
WORKDIR /home/user
RUN wget https://raw.github.com/git/git/master/contrib/completion/git-completion.bash && \
    wget https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh

ADD bashrc /home/user/.bashrc

WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]

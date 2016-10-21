FROM quay.io/gravitational/debian-grande:0.0.1

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    KUBECTL_VERSION=1.3.8

RUN apt-get update && \
    apt-get install --no-install-recommends --yes \
        curl \
        gcc \
        groff \
        python3 \
        python3-dev \
        python3-pip && \
    apt-get clean

RUN pip3 install awscli

RUN curl -sSL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

RUN mkdir -p /opt/gravitational/pithos/content-generate
WORKDIR /opt/gravitational/pithos/content-generate
COPY . /opt/gravitational/pithos/content-generate

CMD ["bash", "run.sh"]

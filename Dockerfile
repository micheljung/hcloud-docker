FROM alpine:latest

ARG VERSION

RUN wget -O hcloud.tar.gz https://github.com/hetznercloud/cli/releases/download/$VERSION/hcloud-linux-amd64.tar.gz && \
    tar -xzf hcloud.tar.gz && \
    mv hcloud /usr/local/bin/hcloud && \
    rm hcloud.tar.gz

ENTRYPOINT ["/usr/local/bin/hcloud"]

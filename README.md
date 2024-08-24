# hcloud-docker

Provides a Docker image with the Hetzner Cloud CLI pre-installed.

## Starting a GitLab CI runner

This image was created to start one or more GitLab CI runners on Hetzner Cloud on demand.

The following .gitlab-ci.yml demonstrates how it can be used:

```
variables:
  HCLOUD_ARM64_SERVER: cax31
  HCLOUD_AMD64_SERVER: cpx41
  HCLOUD_LOCATION: ash
  HCLOUD_IMAGE: ubuntu-22.04
  HCLOUD_LABEL: type=ci-runner
  
Start runner:
  image:
    name: micheljung/hcloud:latest
    entrypoint: [""]
  stage: start-runners
  only:
    - branches
    - tags
  # Don't clone the git repository
  variables:
    GIT_STRATEGY: none
  # Don't download caches
  cache: []
  parallel:
    matrix:
      - ARCH: arm64
        GITLAB_RUNNER_TOKEN: $GITLAB_NATIVE_ARM64_CI_RUNNER_TOKEN
        HCLOUD_SERVER_TYPE: $HCLOUD_ARM64_SERVER
      - ARCH: amd64
        GITLAB_RUNNER_TOKEN: $GITLAB_NATIVE_AMD64_CI_RUNNER_TOKEN
        HCLOUD_SERVER_TYPE: $HCLOUD_AMD64_SERVER
  script:
    - |
      hcloud server list | grep "gitlab-$ARCH-runner" || \
      envsubst < .ci-cloudinit.yml | \
      hcloud server create \
        --name "gitlab-$ARCH-runner" \
        --location $HCLOUD_LOCATION \
        --type $HCLOUD_SERVER_TYPE \
        --image $HCLOUD_IMAGE \
        --label $HCLOUD_LABEL \
        --label "arch=$ARCH" \
        --user-data-from-file -
```

Your `.ci-cloudinit.yml` could look like this:

```yaml
#cloud-config

package_update: true
package_upgrade: true

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - unattended-upgrades

runcmd:
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - systemctl enable docker
  - systemctl start docker
  - docker run --rm -v gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner register --non-interactive --executor "docker" --url "https://gitlab.com/" --docker-image docker:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock --token "$GITLAB_RUNNER_TOKEN"
  - docker run -d --restart unless-stopped --name gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock -v gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner
```
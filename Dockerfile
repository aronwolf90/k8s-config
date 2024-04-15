FROM ubuntu:22.04

WORKDIR /app

ENV TZ=Europe/Berlin
ENV SHELL=bash
ENV BASH_ENV=/root/.asdf/asdf.sh

RUN apt-get update -y && apt-get install -y git curl unzip build-essential

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

COPY .tool-versions .
RUN bash -c "asdf plugin add golang https://github.com/asdf-community/asdf-golang.git"
RUN bash -c "asdf plugin add opentofu https://github.com/defenseunicorns/asdf-opentofu.git"
RUN bash -c "asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git"
RUN bash -c "asdf install"

RUN mkdir -p ~/.ssh
COPY tests/fixtures/ssh_host_first_key /root/.ssh/id_rsa
COPY tests/fixtures/ssh_host_first_key.pub /root/.ssh/id_rsa.pub
COPY --from=registry.gitlab.com/components/opentofu/gitlab-opentofu:0.18.0-rc5-opentofu1.6.2 /usr/bin/gitlab-tofu /usr/bin/gitlab-tofu

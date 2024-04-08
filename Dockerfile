FROM ubuntu:22.04

WORKDIR /app

ENV TZ=Europe/Berlin
ENV SHELL=bash
ENV BASH_ENV=/root/.asdf/asdf.sh

RUN apt-get update -y && apt-get install -y git curl unzip build-essential

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

COPY .tool-versions .
RUN bash -c "asdf plugin add golang https://github.com/asdf-community/asdf-golang.git"
RUN bash -c "asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git"
RUN bash -c "asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git"
RUN bash -c "asdf install"

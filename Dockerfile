FROM ubuntu

WORKDIR /app

ENV TZ=Europe/Berlin
ENV SHELL=bash

RUN apt-get update -y && \
  DEBIAN_FRONTEND="noninteractive" apt-get install curl gnupg2 xclip \
  software-properties-common tmux universal-ctags default-jre git gcc jq python3-pip -y && \
  curl https://dl.google.com/go/go1.17.3.linux-amd64.tar.gz --output go.tar.gz && \
  tar -C /usr/local -xzf go.tar.gz

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
  apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" -y && \
   apt-get install terraform -y

RUN pip3 install neovim-remote

RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage && \
  chmod u+x nvim.appimage && \
  ./nvim.appimage --appimage-extract && \
  mv squashfs-root / && \
  ln -s /squashfs-root/AppRun /usr/local/bin/nvim

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  mv kubectl /usr/local/bin/ && \
  chmod +x /usr/local/bin/kubectl

ENV PATH=$PATH:/usr/local/go/bin

RUN echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile && \
  echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc

COPY go.mod go.sum ./

RUN go mod download

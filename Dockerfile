FROM ubuntu

WORKDIR /app

ENV TZ=Europe/Berlin

RUN apt-get update -y && \
  DEBIAN_FRONTEND="noninteractive" apt-get install curl gnupg2 software-properties-common tmux vim-gtk ctags default-jre git gcc -y && \
  curl https://dl.google.com/go/go1.17.3.linux-amd64.tar.gz --output go.tar.gz && \
  tar -C /usr/local -xzf go.tar.gz

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
  apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" -y && \
   apt-get install terraform -y

RUN echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile && \
  echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc

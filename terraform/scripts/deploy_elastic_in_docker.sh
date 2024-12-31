#!/bin/bash

  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

  # Add Docker's official GPG key:
  sudo apt-get -y update
  sudo apt-get -y install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get -y update

  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  #######elastic

  sudo docker network create elastic
  sudo docker pull docker.elastic.co/elasticsearch/elasticsearch:8.16.0
  sudo docker run -d --name es01 --net elastic -p 9200:9200 -it -m 3GB docker.elastic.co/elasticsearch/elasticsearch:8.16.0
  sleep 15
  ##########copy certificate
  sudo docker cp es01:/usr/share/elasticsearch/config/certs/http_ca.crt .
  sudo docker pull docker.elastic.co/kibana/kibana:8.16.0
  sudo docker run -d --name kib01 --net elastic -p 5601:5601 -m 2GB docker.elastic.co/kibana/kibana:8.16.0

  # Get auth data
  sudo docker ps -a | grep elasticsearch | awk '{print $1}' | xargs sudo docker container logs | grep -a1 'Copy the following enrollment token and paste it into Kibana in your browser'
  sudo docker ps -a | grep elasticsearch | awk '{print $1}' | xargs sudo docker container logs | grep -a1 Password
  sleep 15
  sudo docker container ps | grep kibana | awk '{print $1}' | xargs sudo docker container logs | grep  'Go to'
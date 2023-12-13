terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
}

resource "docker_network" "jenkins" {
  name = "jenkins"
}

resource "docker_volume" "jenkins_docker_certs" {
  name = "jenkins-docker-certs"
}

resource "docker_volume" "jenkins_data" {
  name = "jenkins-data"
}

resource "docker_image" "dind" {
  name         = "docker:dind"
  keep_locally = false
}

resource "docker_container" "dind" {
  image      = docker_image.dind.image_id
  name       = "jenkins-docker"
  rm         = true
  privileged = true
  networks_advanced {
    name = docker_network.jenkins.name
    aliases = [
      "${var.alias_network_docker}"
    ]
  }
  env = [
    "DOCKER_TLS_CERTDIR=${var.ruta_cont_TLS}"
  ]
  volumes {
    volume_name    = docker_volume.jenkins_docker_certs.name
    container_path = "${var.ruta_cont_TLS}/client"
  }
  volumes {
    volume_name    = docker_volume.jenkins_data.name
    container_path = var.ruta_datos_jenkins
  }
  ports {
    internal = 2376
    external = 2376
  }
  ports {
    internal = 3000
    external = 3000
  }
  ports {
    internal = 5000
    external = 5000
  }

}

resource "docker_container" "jenkins_blueocean" {
  image   = "myjenkins-blueocean"
  name    = "jenkins-blueocean"
  restart = "on-failure"
  networks_advanced {
    name = docker_network.jenkins.name
  }
  env = [
    "DOCKER_HOST=tcp://${var.alias_network_docker}:2376",
    "DOCKER_CERT_PATH=${var.ruta_cont_TLS}/client",
    "DOCKER_TLS_VERIFY=1"
  ]
  ports {
    internal = 8080
    external = 8081
  }
  ports {
    internal = 50000
    external = 50000
  }
  volumes {
    volume_name    = docker_volume.jenkins_data.name
    container_path = var.ruta_datos_jenkins
  }
  volumes {
    volume_name    = docker_volume.jenkins_docker_certs.name
    container_path = "${var.ruta_cont_TLS}/client"
  }
}
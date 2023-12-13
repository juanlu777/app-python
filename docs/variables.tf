variable "alias_network_docker" {
  description = "Alias del contenedor dind dentro de la red jenkins"
  type        = string
  default     = "docker"
}

variable "ruta_cont_TLS" {
  description = "Ruta del contenedor dind en la que se almacenará el directorio que contendrá los certificados TLS"
  type        = string
  default     = "/certs"
}

variable "ruta_datos_jenkins" {
  description = "Ruta de los contenedores, tanto en dind como en el de jenkins, donde se almacenan los datos de Jenkins"
  type        = string
  default     = "/var/jenkins_home"
}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "cluster_name" {}
variable "alb_listener_arn" {}
variable "service_definitions" {
  type = list(object({
    name           = string
    image_url      = string
    container_port = number
  }))
}
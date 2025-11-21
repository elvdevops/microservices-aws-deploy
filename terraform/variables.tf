variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"  # CHANGE IF NEEDED
}

variable "project" {
  type        = string
  description = "Project name used for tagging and resource naming"
}

variable "env" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "cluster_name" {
  type        = string
  description = "ECS Cluster Name"
}

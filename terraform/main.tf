module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"   # PLACEHOLDER
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
  env     = var.env 
}

module "ecr" {
  source = "./modules/ecr"

  repositories = [
    "frontend-repo",  # PLACEHOLDER
    "auth-repo",      # PLACEHOLDER
    "product-repo"    # PLACEHOLDER
  ]
}

module "alb" {
  source = "./modules/alb"

  public_subnets      = module.vpc.public_subnets
  vpc_id              = module.vpc.vpc_id
  alb_security_group  = module.vpc.alb_sg
  environment         = "dev"  # PLACEHOLDER
}

module "ecs" {
  source = "./modules/ecs"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  cluster_name    = "microservices-cluster" # PLACEHOLDER

  alb_listener_arn = module.alb.listener_arn

  service_definitions = [
    {
      name         = "frontend"
      container_port = 80
      image_url    = "<FRONTEND_ECR_REPO_URL>:latest" # PLACEHOLDER
    },
    {
      name         = "auth"
      container_port = 4001
      image_url    = "<AUTH_ECR_REPO_URL>:latest"    # PLACEHOLDER
    },
    {
      name         = "product"
      container_port = 4002
      image_url    = "<PRODUCT_ECR_REPO_URL>:latest" # PLACEHOLDER
    }
  ]
}

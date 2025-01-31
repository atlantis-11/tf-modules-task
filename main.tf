terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = var.bucket_name
  queue_arn   = module.messaging.queue_arn
}

module "messaging" {
  source          = "./modules/messaging"
  queue_name_base = var.queue_name_base
  bucket_arn      = module.storage.bucket_arn
}

module "compute" {
  source    = "./modules/compute"
  queue_arn = module.messaging.queue_arn
  queue_url = module.messaging.queue_url
}

module "monitoring" {
  source                  = "./modules/monitoring"
  queue_name              = module.messaging.queue_name
  dlq_name                = module.messaging.dlq_name
  asg_id                  = module.compute.asg_id
  asg_name                = module.compute.asg_name
  asg_increase_policy_arn = module.compute.asg_increase_policy_arn
  asg_decrease_policy_arn = module.compute.asg_decrease_policy_arn
}

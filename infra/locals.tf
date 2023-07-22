locals {
  ## Common
  prefix       = "pipeline"
  public_cidrs = "221.151.163.17/32"

  ## VPC
  vpc_cidr = "10.0.0.0/16"
  public_subnets = {
    "ap-northeast-2a" : "10.0.1.0/24",
    "ap-northeast-2b" : "10.0.2.0/24"
  }

  ## ECS TaskDefinition Role
  ecs_task_role_arn = "arn:aws:iam::182024812696:role/pipeline-ecs-task-definition"

}
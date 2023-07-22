#############################################################
# ALB (ECS + Backend)
#############################################################
resource "aws_security_group" "todolist-alb-sg" {
  name   = "${local.prefix}-todolist-alb-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.public_cidrs]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.public_cidrs]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-todolist-alb-sg"
  }
}

module "alb-todolist" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${local.prefix}-todolist-alb"

  vpc_id = aws_vpc.vpc.id
  subnets = values({
    for i, v in aws_subnet.publics :
    i => v.id
  })
  security_groups = [aws_security_group.todolist-alb-sg.id]

  target_groups = [
    {
      name             = "${local.prefix}-todolist-tg"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]

  #   https_listeners = [
  #     {
  #       port               = 443
  #       protocol           = "HTTPS"
  #       certificate_arn    = ""
  #       target_group_index = 0
  #     }
  #   ]

  #   http_tcp_listeners = [
  #     {
  #       port        = 80
  #       protocol    = "HTTP"
  #       action_type = "redirect"
  #       redirect = {
  #         port        = "443"
  #         protocol    = "HTTPS"
  #         status_code = "HTTP_301"
  #       }
  #     }
  #   ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Name = "${local.prefix}-todolist-alb-sg"
  }
}

#############################################################
# ECR
#############################################################
resource "aws_ecr_repository" "todolist" {
  name                 = "todolist-repository" // repository_url
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.todolist.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

#############################################################
# ECS
#############################################################
resource "aws_security_group" "todolist-ecs-sg" {
  name   = "${local.prefix}-todolist-ecs-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.todolist-alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-todolist-ecs-sg"
  }
}

#############################################################
# ECS Cluster
#############################################################
resource "aws_kms_key" "kms" {
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "todolist-log-group" {
  name = "${local.prefix}-todolist-logs"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${local.prefix}-todolist-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.kms.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.todolist-log-group.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster-provider" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 3
  }
}

#############################################################
# ECS Task Definition
#############################################################
variable "DB_HOST" {}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "todolist-family"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  execution_role_arn = local.ecs_task_role_arn
  task_role_arn      = local.ecs_task_role_arn
  network_mode       = "awsvpc"

  container_definitions = jsonencode([
    {
      name      = "todolist-container"
      image     = "${aws_ecr_repository.todolist.repository_url}:build-7.0"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [{
        "containerPort" : 3000,
        "hostPort" : 3000,
        "protocol" : "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/todolist-ecs-family" # CloudWatch 로그 그룹 이름
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "ap-northeast-2" # AWS 리전 이름
          "awslogs-stream-prefix" = "ecs"            # 로그 스트림의 접두사
        }
      },
      environment = [
        {
          "name" : "PORT"
          "value" : "3000"
        },
        {
          "name" : "DB_PORT"
          "value" : "3306"
        },
        {
          "name" : "DB_HOST"
          "value" : "${var.DB_HOST}"
        },
        {
          "name" : "DB_USER"
          "value" : "root"
        },
        {
          "name" : "DB_PASSWORD"
          "value" : "12341234"
        },
        {
          "name" : "DB_NAME"
          "value" : "todomini"
        }
      ]
    }
  ])
}

#############################################################
# ECS Service
#############################################################
resource "aws_ecs_service" "service" {
  launch_type     = "FARGATE"
  name            = "todolist-service"
  cluster         = aws_ecs_cluster.cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = true
    subnets = values({
      for i, v in aws_subnet.publics :
      i => v.id
    })
    security_groups = [aws_security_group.todolist-ecs-sg.id]
  }

  load_balancer {
    target_group_arn = module.alb-todolist.target_group_arns[0]
    container_name   = "todolist-container"
    container_port   = 3000
  }

}
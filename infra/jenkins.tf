##########################################################################
# ALB (Jenkins)
##########################################################################
resource "aws_security_group" "jenkins-alb-sg" {
  name   = "${local.prefix}-jenkins-alb-sg"
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
    Name = "${local.prefix}-jenkins-alb-sg"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${local.prefix}-jenkins-alb"

  vpc_id = aws_vpc.vpc.id
  subnets = values({
    for i, v in aws_subnet.publics :
    i => v.id
  })
  security_groups = [aws_security_group.jenkins-alb-sg.id]

  target_groups = [
    {
      name             = "${local.prefix}-jenkins-tg"
      backend_protocol = "HTTP"
      backend_port     = "80"
      target_type      = "instance"
      targets = {
        jenkins = {
          target_id = aws_instance.jenkins.id
          port      = 80
        }
      }
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "403"
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
    Name = "${local.prefix}-jenkins-alb-sg"
  }
}

##########################################################################
# Jenkins EC2
##########################################################################
resource "aws_security_group" "jenkins-sg" {
  name   = "jenkins-ec2-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [local.public_cidrs]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins-alb-sg.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins-alb-sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.public_cidrs]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "jenkins_key_pair" {
  key_name   = "jenkins-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Name = "${local.prefix}-jenkins-keypiar"
  }
}

resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "${local.prefix}-jenkine-eip"
  }
}

resource "aws_instance" "jenkins" {
  ami           = "ami-00d253f3826c44195"
  instance_type = "t3.small"
  key_name      = aws_key_pair.jenkins_key_pair.key_name

  availability_zone = "ap-northeast-2a"
  subnet_id = values({
    for i, v in aws_subnet.publics :
    i => v.id
  })[0]

  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${local.prefix}-jenkins-ec2"
  }

}
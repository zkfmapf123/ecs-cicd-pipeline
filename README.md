## ecs-cicd-pipeline

![arch](./public/arch.png)

### Todo

- [ ] Application
  - [x] Create Node Backend Server
  - [ ] Create Static Page
- [ ] AWS Resource
  - [x] VPC
  - [x] EC2 (Jenkins)
  - [x] ALB (Jenkins + ECS)
  - [x] ECR
  - [ ] ECS (Blue/green + Auto Scaling)
  - [ ] CloudFront
  - [ ] S3
- [ ] CI/CD
  - [ ] Git Webhoook trigger on Jenkins
  - [ ] Slack Notification
- [ ] Test
  - [ ] Stress Test (Auto Scaling)
  - [ ] Deploy Test (Blue/Green)

### ...

- DockerFile에서 BuildStage는 가벼운 이미지를 쓰는게좋음... 근데 실제 Production 이미지는 alpine이미지를 쓰면안됨
  - alpine 이미지는 exec format error 가 난다. (docker exec -it <container> /bin/bash)
  - ECS TaskDefinition에서 awslogs를 설정하면 TaskDefinition이 직접 /bin/bash로 들어가서 로그를 추출하는데, alpine이미지는 그게 안됨...
- ECS 에서 RDS 연결할때는 host가 localhost다. 생각해보면 같은 subnet내에서동작한다면 localhost지...
- RDS에서 SG를 ECS에 SG로 연결을 해야 함 (3306 - ECS SG) => ALB가 아님
- ECS ERROR

  ```
  1. exec /usr/local/bin/docker-entrypoint.sh: exec format error
  ENTRY_POINT를 그냥 node dist/index.js로 수정

  2. exec /usr/local/bin/node: exec format error
  BASE Image의 Platform을 수정했음
  FROM --platform=linux/amd64 node:16-alpine

  3. MYSQL Error가 난다...
  HOST를 ... rds의 endpoint로 뒀어야 했음...

  - vpc의 dns 설정을 했어야 했음
  resource "aws_vpc" "vpc" {
    cidr_block           = local.vpc_cidr
    enable_dns_support   = true # Enable DNS resolution for the VPC
    enable_dns_hostnames = true # Enable DNS hostnames for the VPC
    tags = {
      Name = "${local.prefix}-vpc"
    }
  }

  - RDS의 public_asssible = true, SG를 허용 해야 함

  resource "aws_db_instance" "rds" {
    ...
    publicly_accessible = true
    ...
  }

  ```

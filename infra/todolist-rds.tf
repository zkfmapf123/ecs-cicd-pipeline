#############################################################
# RDS

## RDS SG는 ECS가 직접 접근해야 함 (subnet 내부)
#############################################################
resource "aws_security_group" "todolist-rds-sg" {
  name   = "${local.prefix}-todolist-rds-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.todolist-ecs-sg.id]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "${local.prefix}-todolist-rds-sg"
  }
}

resource "aws_db_subnet_group" "todolist-subnet-group" {
  description = "Created from the RDS Management Console"
  subnet_ids = values({
    for i, v in aws_subnet.publics :
    i => v.id
  })
}

resource "aws_db_instance" "todolist-rds" {

  # RDS 인스턴스 설정
  allocated_storage         = 20                                           # 할당 스토리지 크기 (기본값: 20GB)
  apply_immediately         = false                                        # 설정 변경을 즉시 적용하지 않음
  availability_zone         = "ap-northeast-2a"                            # 사용 가능한 가용 영역
  backup_retention_period   = 1                                            # 백업 보존 기간 (일 단위)
  backup_target             = "region"                                     # 백업 대상 (region: 지역 전체)
  backup_window             = "17:44-18:14"                                # 백업 창 시간 (UTC 기준)
  ca_cert_identifier        = "rds-ca-2019"                                # RDS SSL 인증서 식별자
  copy_tags_to_snapshot     = true                                         # 스냅샷 생성시 태그 복사 여부
  customer_owned_ip_enabled = false                                        # 고객 소유 IP 사용 여부 (VPC Peering 등)
  db_subnet_group_name      = aws_db_subnet_group.todolist-subnet-group.id # DB 서브넷 그룹 ID

  # RDS 인스턴스 식별자 및 유형 설정
  identifier     = "leedonggyu-todolist-rds" # RDS 인스턴스 식별자
  instance_class = "db.t3.micro"             # 인스턴스 유형 (t3.micro)

  # 데이터베이스 엔진과 버전 설정
  engine         = "mysql"  # 데이터베이스 엔진 (MySQL)
  engine_version = "5.7.42" # 데이터베이스 엔진 버전 (MySQL 5.7.42)

  # IAM 데이터베이스 인증 사용 여부 설정
  iam_database_authentication_enabled = false # IAM 데이터베이스 인증 비활성화

  # RDS 인스턴스 삭제 보호 설정 (해제)
  deletion_protection = false # 삭제 보호 해제

  # CloudWatch 로그 내보내기 설정 (비어있음)
  enabled_cloudwatch_logs_exports = []

  # 최대 할당 스토리지 크기 설정
  max_allocated_storage = 100 # 최대 100GB 할당 스토리지 크기

  # 스토리지 암호화 설정
  storage_encrypted = true # 스토리지 암호화 활성화

  # RDS 인스턴스 종료 시 최종 스냅샷 생략 설정
  skip_final_snapshot = true # 종료 시 최종 스냅샷 생략

  # RDS 인스턴스 접속 정보 설정
  username     = "root" # RDS 인스턴스의 기본 관리자 사용자 이름
  storage_type = "gp2"  # 스토리지 유형 (일반용 프로비저닝 SSD)

  # RDS 인스턴스에 할당할 보안 그룹 설정
  vpc_security_group_ids = [aws_security_group.todolist-rds-sg.id]

  publicly_accessible = true

  # 리소스에 태그 지정
  tags = {
    Name = "${local.prefix}-todolist-rds" # 리소스 이름 태그 (local.prefix로 지정된 값 사용)
  }
}
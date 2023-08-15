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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.eip.id
}
resource "aws_iam_role" "ecs" {
  name = "pipeline-ecs-task-definition"

  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name       = "${local.prefix}-ecs-execution"
    Properties = "${local.prefix}"
  }
}

resource "aws_iam_policy" "cloudwatch-group" {
  name = "cloudwatch-group"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "get_ecr_list" {
  name = "get-ecr-list"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_group_attachment" {
  for_each = {
    for i, v in [aws_iam_policy.cloudwatch-group, aws_iam_policy.get_ecr_list] :
    i => v
  }

  policy_arn = each.value.arn
  role       = aws_iam_role.ecs.name
}
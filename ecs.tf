#-----------------------------------
# 1. ECS Cluster
#-----------------------------------
resource "aws_ecs_cluster" "main" {
  name = "todoapp-ecs-cluster"
}

#-----------------------------------
# 2. CloudWatch Log Group
#-----------------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/todoapp"
  retention_in_days = 7
}

#-----------------------------------
# 3. Fetch an existing IAM Role from your AWS account
#-----------------------------------
data "aws_iam_role" "ecs_execution_role" {
  name = "ecs-task-execution-role" # Replace with the exact name of your existing role in AWS
}

#-----------------------------------
# 4. Fetch an existing ECR Repository from your AWS account
#-----------------------------------
data "aws_ecr_repository" "app" {
  name = "todoapp" # Replace with the exact name of your existing ECR repository in AWS
}

#-----------------------------------
# 5. ECS Task Definition
#-----------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = "todoapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "todoapp"
      image     = "${data.aws_ecr_repository.app.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = "ap-southeast-4"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

#-----------------------------------
# 6. Fetch existing subnets in your default VPC
#-----------------------------------
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = ["vpc-06e719820f8b9a0e3"] # Replace with your VPC ID
  }
}

#-----------------------------------
# 7. Fetch existing Security Group
#-----------------------------------
data "aws_security_group" "http_sg" {
  name = "allow-http" # Replace with exact name in AWS
}

#-----------------------------------
# 8. ECS Service (Fargate)
#-----------------------------------
resource "aws_ecs_service" "app" {
  name            = "todoapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.public.ids # Use the public subnet created in network.tf
    security_groups  = [data.aws_security_group.http_sg.id]
    assign_public_ip = true
  }
}
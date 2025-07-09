provider "aws" {
  region = var.region
}

resource "aws_vpc" "ahmad-vpc-terra" {
  cidr_block = var.vpc-cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "ahmad-vpc-terra"
    "owner" = "ahmad"
  }
}

resource "aws_internet_gateway" "ahmad-igw-terra" {  
    vpc_id = aws_vpc.ahmad-vpc-terra.id
    tags = {
        "Name" = "ahmad-igw-terra"
        "owner" = var.owner
    }
}

resource "aws_subnet" "ahmad-public-subnet1-terra" {
  vpc_id = aws_vpc.ahmad-vpc-terra.id
  cidr_block = var.subnet1-cidr
  availability_zone = "us-east-2c"

  map_public_ip_on_launch = true

  tags = {
    "Name" = "ahmad-public-subnet1-terra"
    "owner" = var.owner
  }
}

resource "aws_subnet" "ahmad-public-subnet2-terra" {
  vpc_id = aws_vpc.ahmad-vpc-terra.id
  cidr_block = var.subnet2-cidr
  availability_zone = "us-east-2a"

  map_public_ip_on_launch = true

  tags = {
    "Name" = "ahmad-public-subnet2-terra"
    "owner" = var.owner
  }
}

resource "aws_route_table" "ahmad-public-sub-rt-terra" {
  vpc_id = aws_vpc.ahmad-vpc-terra.id
  route {
    cidr_block = var.all-traffic-cidr
    gateway_id = aws_internet_gateway.ahmad-igw-terra.id
  }
  tags = {
    "Name" = "ahmad-public-sub-rt-terra"
    "owner" = var.owner
  }
}

resource "aws_route_table_association" "ahmad-subnet1-association" {
  subnet_id = aws_subnet.ahmad-public-subnet1-terra.id
  route_table_id = aws_route_table.ahmad-public-sub-rt-terra.id
}

resource "aws_route_table_association" "ahmad-subnet2-association" {
  subnet_id = aws_subnet.ahmad-public-subnet2-terra.id
  route_table_id = aws_route_table.ahmad-public-sub-rt-terra.id
}

resource "aws_security_group" "ahmad-sg-terra" {
  name = "Http and SSH"
  vpc_id = aws_vpc.ahmad-vpc-terra.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.all-traffic-cidr]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.all-traffic-cidr]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [var.all-traffic-cidr]
  }  

  tags = {
    "Name" = "ahmad-sg-terra"
    "owner" = var.owner
  }
}


##################    ECS Resources    ##########################
resource "aws_ecs_cluster" "ahmad-ecs-cluster-terra" {
  name = "ahmad-ecs-cluster-terra"
  tags = {
    "Name" = "ahmad-ecs-cluster-terra"
    "owner" = "ahmad"
  }
}

resource "aws_ecs_task_definition" "ahmad-taskdef-terra" {
  family = "ahmad-taskdef-terra"
  requires_compatibilities = ["EC2"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  execution_role_arn = "arn:aws:iam::504649076991:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
        name = "nginx-terra"
        image = "nginxdemos/hello:latest"
        cpu = 256
        memory = 512
        essential = true
        portMappings = [
            {
                containerPort = 80
                hostPort = 80
            }
        ]
    }
  ])

  tags = {
    "Name" = "ahmad-taskdef-terra"
    "owner" = "ahmad"
  }
}

resource "aws_ecs_service" "ahmad-service-terra-deploy" {
  name = "ahmad-service-terra-deploy"
  launch_type = "EC2"
  cluster = aws_ecs_cluster.ahmad-ecs-cluster-terra.id
  task_definition = aws_ecs_task_definition.ahmad-taskdef-terra.arn
  desired_count = 2
  
  network_configuration {
    subnets = [aws_subnet.ahmad-public-subnet1-terra.id, aws_subnet.ahmad-public-subnet2-terra.id]
    security_groups = [aws_security_group.ahmad-sg-terra.id]
    assign_public_ip = false
  }

  deployment_controller {
      type = "CODE_DEPLOY"
  }

  # deployment_circuit_breaker {
  #   enable = true
  #   rollback = false
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.ahmad-lb-targroup-terra.arn
    container_name = "nginx-terra"
    container_port = 80
  }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.ahmad-lb-targroup2-terra.arn
  #   container_name   = "nginx-terra"
  #   container_port   = 80
  # }

  lifecycle {
    ignore_changes = [load_balancer, task_definition]
  }
  
  depends_on = [ aws_lb_listener.ahmad-lb-listener-terra ]
  tags = {
    "Name" = "ahmad-service-terra"
    "owner" = "ahmad"
  }
}


####################################################
# Create an IAM role - ecsInstanceRole  
####################################################
data "aws_iam_policy" "ecsInstanceRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ecsInstanceRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsInstanceRole-ahmad" {
  name               = "ecsInstanceRole-ahmad"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecsInstanceRolePolicy.json
}

resource "aws_iam_role_policy_attachment" "ecsInstancePolicy" {
  role       = aws_iam_role.ecsInstanceRole-ahmad.name
  policy_arn = data.aws_iam_policy.ecsInstanceRolePolicy.arn
}

resource "aws_iam_instance_profile" "ecsInstanceRoleProfile" {
  name = aws_iam_role.ecsInstanceRole-ahmad.name
  role = aws_iam_role.ecsInstanceRole-ahmad.name
}

resource "aws_iam_role_policy_attachment" "ecsInstanceECRPullPolicy" {
  role       = aws_iam_role.ecsInstanceRole-ahmad.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecsInstanceSSMPolicy" {
  role       = aws_iam_role.ecsInstanceRole-ahmad.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

############ ASG Group for EC2 Instances ##############
resource "aws_launch_template" "ahmad-launch-template-terra" {
  name_prefix   = "ahmad-launch-template-terra"
  image_id      = "ami-0878cd100d0689adf"
  instance_type = "t2.micro"
 
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.ahmad-ecs-cluster-terra.name}" >> /etc/ecs/ecs.config
    EOF
    )

  iam_instance_profile {
    name = aws_iam_instance_profile.ecsInstanceRoleProfile.name
  }

  tags = {
    "Name" = "ahmad-launch-template-terra"
    "owner" = "ahmad"
  }
}

resource "aws_autoscaling_group" "ahmad-autoscale-group-terra" {
  name = "ahmad-autoscale-group-terra"

  vpc_zone_identifier = [
    aws_subnet.ahmad-public-subnet1-terra.id, 
    aws_subnet.ahmad-public-subnet2-terra.id
  ]

  # availability_zones = ["us-east-2a", "us-east-2c"]

  desired_capacity   = 4
  max_size           = 6
  min_size           = 2
  
  launch_template {
    id      = aws_launch_template.ahmad-launch-template-terra.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

}


############ ALB Logic  ###############
resource "aws_lb" "ahmad-lb-terra" {
  name = "ahmad-lb-terra"
  load_balancer_type = "application"
  security_groups = [ aws_security_group.ahmad-sg-terra.id ]
  subnets = [ aws_subnet.ahmad-public-subnet1-terra.id, aws_subnet.ahmad-public-subnet2-terra.id ]

  tags = {
    "Name" = "ahmad-lb-terra"
    "owner" = "ahmad"
  }
}

resource "aws_lb_target_group" "ahmad-lb-targroup-terra" {
  name = "ahmad-lb-targroup-terra"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.ahmad-vpc-terra.id
}

resource "aws_lb_target_group" "ahmad-lb-targroup2-terra" {
  name = "ahmad-lb-targroup2-terra"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.ahmad-vpc-terra.id
}

resource "aws_lb_listener" "ahmad-lb-listener-terra" {
  load_balancer_arn = aws_lb.ahmad-lb-terra.arn
  port              = 80
  protocol          = "HTTP"

   default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.ahmad-lb-targroup-terra.arn 
        weight = 100
      }
    }
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}
################### Permissions for CodeBuild ######################

resource "aws_iam_role" "ahmad-codebuild-role-terra" {
   name = "ahmad-codebuild-role-terra"

   assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
      ]
    })

    tags = {
    "Name" = "ahmad-codebuild-role-terra"
    "owner" = "ahmad"
  }
}


resource "aws_iam_role_policy_attachment" "ahmad-s3-readonly-codebuild-perm" {
  role = aws_iam_role.ahmad-codebuild-role-terra.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ahmad-ecr-codebuild-perm" {
  role = aws_iam_role.ahmad-codebuild-role-terra.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy" "ahmad-codeconnect-codebuild-perm" {
  name = "ahmad-codeconnect-codebuild-perm"
  role = aws_iam_role.ahmad-codebuild-role-terra.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codestar-connections:GetConnectionToken",
                "codestar-connections:GetConnection",
                "codeconnections:GetConnectionToken",
                "codeconnections:GetConnection",
                "codeconnections:UseConnection"
            ],
            "Resource": [
                "arn:aws:codestar-connections:us-east-2:504649076991:connection/bfac014c-01cc-4fdf-a5d2-b4362fe928bf",
                "arn:aws:codeconnections:us-east-2:504649076991:connection/bfac014c-01cc-4fdf-a5d2-b4362fe928bf"
            ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ahmad-codebuild-other-perms" {
  name = "ahmad-codebuild-other-perms"
  role = aws_iam_role.ahmad-codebuild-role-terra.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "s3:PutObject"
            ],
            "Resource": "*"
        }
      ]
  })
}

resource "aws_iam_role_policy" "ahmad-codebuild-base-perms" {
  name = "ahmad-codebuild-other-perms"
  role = aws_iam_role.ahmad-codebuild-role-terra.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:us-east-2:504649076991:log-group:/aws/codebuild/ahmad-ecs-build",
                "arn:aws:logs:us-east-2:504649076991:log-group:/aws/codebuild/ahmad-ecs-build:*",
                # aws_codebuild_project.project-using-github-app-ahmad.arn
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-east-2-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:us-east-2:504649076991:report-group/ahmad-ecs-build-*"
            ]
        }
      ]
  })
}



##################### CodeBuild Code ###################
resource "aws_codebuild_project" "project-using-github-app-ahmad" {
  name         = "project-using-github-app"
  description  = "gets_source_from_github_via_the_github_app"
  service_role = "arn:aws:iam::504649076991:role/service-role/codebuild-ahmad-ecs-build-service-role"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true
    environment_variable {
      name = "REPOSITORY_URI"
      value = "504649076991.dkr.ecr.us-east-2.amazonaws.com/ahmad-codepipe-repo"
    }

    environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = "us-east-2"
    }

    environment_variable {
      name = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name = "TASK_FAMILY"
      value = aws_ecs_task_definition.ahmad-taskdef-terra.family
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/project-using-github-app"
    }
  }
  source {
    type     = "GITHUB"
    location = "https://github.com/AhmadMudassir/demo-node-app.git"
    auth {
      type     = "CODECONNECTIONS"
      resource = "arn:aws:codeconnections:us-east-2:504649076991:connection/bfac014c-01cc-4fdf-a5d2-b4362fe928bf"
    }
  }

  tags = {
    "Name" = "project-using-github-app-ahmad"
    "owner" = "ahmad"
  }
}

################## CodePipeline Code ###############
resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = "arn:aws:iam::504649076991:role/service-role/AWSCodePipelineServiceRole-us-east-2-MyECSBuild"

  artifact_store {
    location = "flowlogs-bucket-ahmad"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = "arn:aws:codeconnections:us-east-2:504649076991:connection/bfac014c-01cc-4fdf-a5d2-b4362fe928bf"
        FullRepositoryId = "AhmadMudassir/aws-codepipline-ecs"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.project-using-github-app-ahmad.name
      }
    }
  }  

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ApplicationName  = aws_codedeploy_app.ahmad-deploy-app-terra.name
        DeploymentGroupName = aws_codedeploy_deployment_group.ahmad-deploy-group-terra.deployment_group_name
      }
    }
  }

  # stage {
  #   name = "Deploy"
  #   action {
  #     name            = "Deploy"
  #     category        = "Deploy"
  #     owner           = "AWS"
  #     provider        = "ECS"
  #     input_artifacts = ["build_output"]
  #     version         = "1"
  #     configuration = {
  #       ClusterName = aws_ecs_cluster.ahmad-ecs-cluster-terra.name
  #       ServiceName = aws_ecs_service.ahmad-service-terra-deploy.name
  #       FileName    = "imagedefinitions.json"
  #     }
  #   }
  # }
}

resource "aws_codedeploy_app" "ahmad-deploy-app-terra" {
  compute_platform = "ECS"
  name             = "ahmad-deploy-app-terra"
}

resource "aws_codedeploy_deployment_group" "ahmad-deploy-group-terra" {
  app_name               = aws_codedeploy_app.ahmad-deploy-app-terra.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "ahmad-deploy-group-terra"
  service_role_arn       = "arn:aws:iam::504649076991:role/AWSCodeDeployServiceRole"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ahmad-ecs-cluster-terra.name
    service_name = aws_ecs_service.ahmad-service-terra-deploy.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.ahmad-lb-listener-terra.arn]
      }

      target_group {
        name = aws_lb_target_group.ahmad-lb-targroup-terra.name
      }

      target_group {
        name = aws_lb_target_group.ahmad-lb-targroup2-terra.name
      }
    }
  }
}





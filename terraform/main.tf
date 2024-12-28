    provider "aws" {
    region = "ap-south-1"
    }

   
    resource "aws_s3_bucket" "data_bucket" {
    bucket = var.s3_bucket_name
    }

  
    resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    }

   
    resource "aws_subnet" "subnet_1" {
    vpc_id                  = aws_vpc.main_vpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "ap-south-1a"
    map_public_ip_on_launch = true
    }

    resource "aws_subnet" "subnet_2" {
    vpc_id                  = aws_vpc.main_vpc.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "ap-south-1b"
    map_public_ip_on_launch = true
    }

   
    resource "aws_db_subnet_group" "default" {
    name       = "default-db-subnet-group"
    subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
    }

    
    resource "aws_internet_gateway" "main_gateway" {
    vpc_id = aws_vpc.main_vpc.id
    }

    
    resource "aws_route_table" "main_route_table" {
    vpc_id = aws_vpc.main_vpc.id
    }

    resource "aws_route" "internet_access" {
    route_table_id         = aws_route_table.main_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.main_gateway.id
    }

    resource "aws_route_table_association" "subnet_1_association" {
    subnet_id      = aws_subnet.subnet_1.id
    route_table_id = aws_route_table.main_route_table.id
    }

    resource "aws_route_table_association" "subnet_2_association" {
    subnet_id      = aws_subnet.subnet_2.id
    route_table_id = aws_route_table.main_route_table.id
    }

    
    resource "aws_security_group" "rds_security_group" {
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        from_port   = 5432
        to_port     = 5432
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

   
    resource "aws_db_instance" "rds_instance" {
    allocated_storage    = 10
    engine               = "postgres"
    engine_version       = "15.4"
    instance_class       = "db.t3.micro"
    db_name              = var.rds_db_name
    username             = var.rds_username
    password             = var.rds_password
    publicly_accessible  = true 
    db_subnet_group_name = aws_db_subnet_group.default.name
    vpc_security_group_ids = [aws_security_group.rds_security_group.id]

   
    backup_retention_period = 7 
    skip_final_snapshot      = true 
    deletion_protection      = false
    tags = {
        Name = "RDS PostgreSQL Instance"
    }
    }

  
    resource "aws_glue_catalog_database" "glue_db" {
    name = var.glue_database_name
    }


    resource "aws_ecr_repository" "data_pipeline_repo" {
    name = "aws-data-pipeline"
    }

    
    resource "aws_iam_role" "lambda_role" {
    name = "aws-data-pipeline-lambda-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Action    = "sts:AssumeRole",
            Effect    = "Allow",
            Principal = { Service = "lambda.amazonaws.com" }
        }
        ]
    })
    }

    resource "aws_lambda_function" "data_pipeline_lambda" {
    function_name = "data-pipeline-lambda"
    role          = aws_iam_role.lambda_role.arn
    package_type  = "Image" 
    image_uri     = "${aws_ecr_repository.data_pipeline_repo.repository_url}:latest"

    environment {
        variables = {
        S3_BUCKET_NAME = var.s3_bucket_name 
        RDS_DB_NAME    = var.rds_db_name
        }
    }

    timeout     = 900  
    memory_size = 512 
    tags = {
        Name = "Data Pipeline Lambda Function"
    }
    }

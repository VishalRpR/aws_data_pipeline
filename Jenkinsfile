pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        ECR_REPOSITORY = 'aws-data-pipeline'
        IMAGE_TAG = 'latest'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')  
    }
    stages {
        stage('Clone GitHub Repo') {
            steps {
                git 'https://github.com/VishalRpR/aws_data_pipeline.git' 
            }
        }
        stage('Terraform Init and Apply') {
            steps {
                script {
                    dir('terraform') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build --build-arg AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} --build-arg AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} --build-arg AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} -t s3tords .'
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    
                    sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin 890742604940.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com'

                    
                    sh 'docker tag s3tords:latest 890742604940.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG'
                    sh 'docker push 890742604940.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG'
                }
            }
        }
        stage('Deploy Lambda Function') {
            steps {
                script {
                    dir('terraform') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
}

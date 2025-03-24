pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/karan9637/Finance-Project.git'
        DOCKER_IMAGE = 'ujjwalsharma3201/finance_app'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: "${https://github.com/karan9637/Finance-Project.git}"
            }
        }
        stage('Provision Infrastructure with Terraform') {
            steps {
                script {
                    sh '''
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }
        stage('Build and Test') {
            steps {
                sh 'mvn clean package'
                sh 'mvn test'
            }
        }
        stage('Dockerize') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${env.BUILD_ID}")
                }
            }
        }
        stage('Deploy to Test Server') {
            steps {
                script {
                    sh '''
                    TEST_SERVER_IP=$(cd terraform && terraform output -raw test_server_ip)
                    ssh -o StrictHostKeyChecking=no ec2-user@$TEST_SERVER_IP "docker run -d -p 8080:8080 ${DOCKER_IMAGE}:${env.BUILD_ID}"
                    '''
                }
            }
        }
        stage('Run Selenium Tests') {
            steps {
                sh 'mvn verify -P selenium-tests'
            }
        }
        stage('Deploy to Production Server') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    sh '''
                    PROD_SERVER_IP=$(cd terraform && terraform output -raw prod_server_ip)
                    ssh -o StrictHostKeyChecking=no ec2-user@$PROD_SERVER_IP "docker run -d -p 8080:8080 ${DOCKER_IMAGE}:${env.BUILD_ID}"
                    '''
                }
            }
        }
    }
}

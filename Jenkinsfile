pipeline {
    agent any

    tools {
    jdk 'JDK-17'
    maven 'Maven-3.9.6'
    }

    environment {
        REPO_URL = "https://github.com/karan9637/Finance-Project.git"    
        DOCKER_IMAGE = 'ujjwalsharma3201/finance_app'
        TEST_SERVER_IP = "3.110.90.201"  // Replace with actual test server IP
        PROD_SERVER_IP = "65.2.73.133"  // Replace with actual production server IP
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: REPO_URL
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
                    ssh -o StrictHostKeyChecking=no ec2-user@${TEST_SERVER_IP} "docker stop finance_app || true && docker rm finance_app || true"
                    ssh -o StrictHostKeyChecking=no ec2-user@${TEST_SERVER_IP} "docker pull ${DOCKER_IMAGE}:${env.BUILD_ID}"
                    ssh -o StrictHostKeyChecking=no ec2-user@${TEST_SERVER_IP} "docker run -d --name finance_app -p 8080:8080 ${DOCKER_IMAGE}:${env.BUILD_ID}"
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
                    ssh -o StrictHostKeyChecking=no ec2-user@${PROD_SERVER_IP} "docker stop finance_app || true && docker rm finance_app || true"
                    ssh -o StrictHostKeyChecking=no ec2-user@${PROD_SERVER_IP} "docker pull ${DOCKER_IMAGE}:${env.BUILD_ID}"
                    ssh -o StrictHostKeyChecking=no ec2-user@${PROD_SERVER_IP} "docker run -d --name finance_app -p 8080:8080 ${DOCKER_IMAGE}:${env.BUILD_ID}"
                    '''
                }
            }
        }
    }
}

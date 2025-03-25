pipeline {
    agent any

    tools {
        jdk 'JDK-17'
        maven 'Maven-3.9.6'
    }

    environment {
        REPO_URL = "https://github.com/karan9637/Finance-Project.git"
        DOCKER_IMAGE = 'ujjwalsharma3201/finance_app'
        TEST_SERVER_IP = "13.232.10.182"
        PROD_SERVER_IP = "3.110.165.178"
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
                    docker.build("${DOCKER_IMAGE}:${BUILD_ID}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker login -u 'ujjwalsharma3201' -p 'bhole@123'"
                sh "docker push ${DOCKER_IMAGE}:${BUILD_ID}"
            }
        }


        stage('Deploy to Test Server') {
            steps {
                script {
                    sh """
                    /usr/bin/ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ec2-user@${TEST_SERVER_IP} \\
                    "docker login -u "ujjwalsharma3201" -p "bhole@123" && \\
                    /usr/bin/docker stop finance_app || true && \\
                    /usr/bin/docker rm finance_app || true && \\
                    /usr/bin/docker pull ${DOCKER_IMAGE}:${BUILD_ID} && \\
                    /usr/bin/docker run -d --name finance_app -p 8080:8080 ${DOCKER_IMAGE}:${BUILD_ID}"
                    """
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
                    sh """
                    /usr/bin/ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ec2-user@${PROD_SERVER_IP} << EOF
                    /usr/bin/docker stop finance_app || true
                    /usr/bin/docker rm finance_app || true
                    /usr/bin/docker pull ${DOCKER_IMAGE}:${BUILD_ID}
                    /usr/bin/docker run -d --name finance_app -p 8080:8080 ${DOCKER_IMAGE}:${BUILD_ID}
                    EOF
                    """
                }
            }
        }
    }
}

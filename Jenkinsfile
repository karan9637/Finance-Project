pipeline {
    agent any

    tools {
        jdk 'JDK_17'
        maven 'maven-3.8'
    }

    environment {  
        REPO_URL = "https://github.com/karan9637/Finance-Project.git"
        DOCKER_IMAGE = 'ujjwalsharma3201/finance_app'
        DOCKER_USER = 'ujjwalsharma3201'
        DOCKER_PASS = 'bhole@123'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: REPO_URL
            }
        }

        stage('Terraform - Provision Infrastructure') {
            steps {
                script {
                    sh """
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                    echo "TEST_SERVER_IP=\$(terraform output -raw test_server_ip)" >> env.properties
                    echo "PROD_SERVER_IP=\$(terraform output -raw prod_server_ip)" >> env.properties
                    """
                }
                script {
                    def props = readProperties file: 'env.properties'
                    env.TEST_SERVER_IP = props['TEST_SERVER_IP']
                    env.PROD_SERVER_IP = props['PROD_SERVER_IP']
                }
            }
        }

        stage('Ansible - Configure Servers') {
            steps {
                script {
                    sh """
                    echo "[test]" > ansible/inventory
                    echo "\${TEST_SERVER_IP} ansible_ssh_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_rsa" >> ansible/inventory
                    echo "[prod]" >> ansible/inventory
                    echo "\${PROD_SERVER_IP} ansible_ssh_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_rsa" >> ansible/inventory
                    """
                    sh "cat ansible/inventory"
                }
                script {
                    sh "ansible-playbook -i ansible/inventory ansible/playbook.yml"
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
                    docker.build("${DOCKER_IMAGE}:${BUILD_ID}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker login -u '${DOCKER_USER}' -p '${DOCKER_PASS}'"
                sh "docker push ${DOCKER_IMAGE}:${BUILD_ID}"
            }
        }

        stage('Deploy to Test Server') {
            steps {
                script {
                    sh """
                    /usr/bin/ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ec2-user@\${TEST_SERVER_IP} << EOF
                    docker login -u "\${DOCKER_USER}" -p "\${DOCKER_PASS}"
                    docker stop finance_app || true
                    docker rm finance_app || true
                    docker pull \${DOCKER_IMAGE}:\${BUILD_ID}
                    docker run -d --name finance_app -p 8080:8080 \${DOCKER_IMAGE}:\${BUILD_ID}
                    EOF
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
                    /usr/bin/ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ec2-user@\${PROD_SERVER_IP} << EOF
                    docker stop finance_app || true
                    docker rm finance_app || true
                    docker pull \${DOCKER_IMAGE}:\${BUILD_ID}
                    docker run -d --name finance_app -p 8080:8080 \${DOCKER_IMAGE}:\${BUILD_ID}
                    EOF
                    """
                }
            }
        }
    }
}

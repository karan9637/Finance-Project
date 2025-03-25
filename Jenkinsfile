pipeline {
    agent any

    tools {
        jdk 'JDK_17'
        maven 'maven-3.8'
    }

    environment {  
        REPO_URL = "https://github.com/karan9637/Finance-Project.git"
        DOCKER_IMAGE = 'ujjwalsharma3201/finance_app'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: REPO_URL
            }
        }

        stage('Terraform - Provision Infrastructure') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        sh """
                        set -e
                        cd terraform
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
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
        }

        stage('Ansible - Configure Servers') {
            steps {
                script {
                    sh """
                    set -e
                    echo "[test]" > ansible/inventory
                    echo "\${TEST_SERVER_IP} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/mykey.pem" >> ansible/inventory
                    echo "[prod]" >> ansible/inventory
                    echo "\${PROD_SERVER_IP} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/mykey.pem" >> ansible/inventory
                    """
                    sh "cat ansible/inventory"
                }
                withCredentials([sshUserPrivateKey(credentialsId: 'SSH_KEY', keyFileVariable: 'SSH_KEY')]) {
                    sh "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/inventory ansible-playbook.yml --private-key=$SSH_KEY"
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
                withCredentials([
                    string(credentialsId: 'DOCKER_USER', variable: 'DOCKER_USER'),
                    string(credentialsId: 'DOCKER_PASS', variable: 'DOCKER_PASS')
                ]) {
                    sh """
                    set -e
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push ${DOCKER_IMAGE}:${BUILD_ID}
                    """
                }
            }
        }

        stage('Deploy to Test Server') {
            steps {
                script {
                    sh """
                    set -e
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
                    set -e
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

pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ACCOUNT_ID = "552993617387"
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecs-namespace/poc-ecr"

        BUILD_NUMBER = "${env.BUILD_NUMBER}"

        AUTH_IMAGE = "${ECR_REPO}:auth-service-${BUILD_NUMBER}"
        API_IMAGE = "${ECR_REPO}:invoice-api-${BUILD_NUMBER}"
        WORKER_IMAGE = "${ECR_REPO}:invoice-worker-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

        stage('Build Auth Service') {
            steps {
                dir('auth-service') {
                    sh '''
                    docker build -t $AUTH_IMAGE .
                    docker push $AUTH_IMAGE
                    '''
                }
            }
        }

        stage('Build Invoice API') {
            steps {
                dir('invoice-api') {
                    sh '''
                    docker build -t $API_IMAGE .
                    docker push $API_IMAGE
                    '''
                }
            }
        }

        stage('Build Invoice Worker') {
            steps {
                dir('invoice-worker') {
                    sh '''
                    docker build -t $WORKER_IMAGE .
                    docker push $WORKER_IMAGE
                    '''
                }
            }
        }

    }

    post {
        success {
            echo "All images pushed successfully to ECR"
        }
        failure {
            echo "Build failed"
        }
    }
}

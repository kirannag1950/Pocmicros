pipeline {
    agent any

    options {
        timestamps()
    }

    parameters {
        choice(
            name: 'SERVICE',
            choices: ['auto', 'auth-service', 'invoice-api', 'invoice-worker'],
            description: 'auto = detect from git, or select service manually'
        )
    }

    environment {
        AWS_REGION = "ap-south-1"
        ACCOUNT_ID = "552993617387"
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecs-namespace/poc-ecr"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Detect Service') {
            steps {
                script {

                    if (params.SERVICE != "auto") {
                        env.SERVICE_TO_BUILD = params.SERVICE
                        echo "Manual build selected: ${env.SERVICE_TO_BUILD}"
                        return
                    }

                    echo "Auto-detecting changed service..."

                    def changedFiles = ""

                    for (changeLog in currentBuild.changeSets) {
                        for (entry in changeLog.items) {
                            for (file in entry.affectedFiles) {
                                changedFiles += file.path + "\n"
                            }
                        }
                    }

                    changedFiles = changedFiles.trim()

                    if (!changedFiles) {
                        changedFiles = sh(
                            script: "git diff --name-only origin/main HEAD || true",
                            returnStdout: true
                        ).trim()
                    }

                    if (changedFiles.contains("auth-service")) {
                        env.SERVICE_TO_BUILD = "auth-service"
                    }
                    else if (changedFiles.contains("invoice-api")) {
                        env.SERVICE_TO_BUILD = "invoice-api"
                    }
                    else if (changedFiles.contains("invoice-worker")) {
                        env.SERVICE_TO_BUILD = "invoice-worker"
                    }
                    else {
                        echo "No service changes detected. Exiting pipeline."
                        currentBuild.result = 'SUCCESS'
                        return
                    }

                    echo "Detected service: ${env.SERVICE_TO_BUILD}"
                }
            }
        }

        stage('Login to AWS ECR') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

        stage('Build Docker Image') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {
                script {

                    env.VERSION_TAG = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-${env.BUILD_NUMBER}"
                    env.LATEST_TAG  = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-latest"

                    echo "Building image: ${VERSION_TAG}"

                    dir("${env.SERVICE_TO_BUILD}") {

                        sh """
                        docker build -t ${VERSION_TAG} .
                        """
                    }
                }
            }
        }

        stage('Trivy Security Scan') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {
                script {

                    echo "Running Trivy scan on ${VERSION_TAG}"

                    sh """
                    trivy image \
                    --exit-code 1 \
                    --severity CRITICAL,HIGH \
                    ${VERSION_TAG}
                    """
                }
            }
        }

        stage('Tag Latest Image') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {

                sh """
                docker tag ${VERSION_TAG} ${LATEST_TAG}
                """
            }
        }

        stage('Push Images to ECR') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {

                sh """
                docker push ${VERSION_TAG}
                docker push ${LATEST_TAG}
                """
            }
        }

    }

    post {

        success {

            echo "Build and scan successful"
            echo "Service: ${env.SERVICE_TO_BUILD}"
            echo "Version image: ${env.VERSION_TAG}"
            echo "Latest image: ${env.LATEST_TAG}"
        }

        failure {

            echo "Build failed due to security vulnerabilities or build error"
        }

        always {

            cleanWs()
        }
    }
}
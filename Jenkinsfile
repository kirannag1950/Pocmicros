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

                    def changedFiles = sh(
                        script: "git diff --name-only HEAD~1 HEAD",
                        returnStdout: true
                    ).trim()

                    echo "Changed files: ${changedFiles}"

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
                        echo "No service changes detected. Skipping build."
                        currentBuild.result = 'SUCCESS'
                        return
                    }

                    echo "Auto detected service: ${env.SERVICE_TO_BUILD}"
                }
            }
        }

        stage('Login to ECR') {
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

        stage('Build & Push Latest Image') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {
                script {

                    def LATEST_TAG = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-latest"

                    echo "Building image: ${LATEST_TAG}"

                    dir("${env.SERVICE_TO_BUILD}") {

                        sh "docker build -t ${LATEST_TAG} ."
                    }

                    sh "docker push ${LATEST_TAG}"

                    echo "Successfully pushed: ${LATEST_TAG}"
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully"
        }
        failure {
            echo "Pipeline failed"
        }
    }
}

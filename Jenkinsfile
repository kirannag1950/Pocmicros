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

                    // Manual override
                    if (params.SERVICE != "auto") {
                        env.SERVICE_TO_BUILD = params.SERVICE
                        echo "Manual build selected: ${env.SERVICE_TO_BUILD}"
                        return
                    }

                    echo "Auto-detecting changed service from Git changes..."

                    def changedFiles = ""

                    // Use Jenkins changeSets (safe for webhook)
                    for (changeLog in currentBuild.changeSets) {
                        for (entry in changeLog.items) {
                            for (file in entry.affectedFiles) {
                                changedFiles += file.path + "\n"
                            }
                        }
                    }

                    changedFiles = changedFiles.trim()

                    echo "Changed files:\n${changedFiles}"

                    if (!changedFiles) {
                        echo "No changes detected from Jenkins changeSets."
                        echo "Fallback to git diff..."

                        changedFiles = sh(
                            script: "git diff --name-only origin/main HEAD || true",
                            returnStdout: true
                        ).trim()

                        echo "Fallback changed files:\n${changedFiles}"
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
                        echo "No service changes detected. Skipping build."
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

        stage('Build & Push Version Image') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {
                script {

                    env.VERSION_TAG = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-${env.BUILD_NUMBER}"

                    echo "Building VERSION image: ${env.VERSION_TAG}"

                    dir("${env.SERVICE_TO_BUILD}") {

                        sh """
                        docker build -t ${VERSION_TAG} .
                        docker push ${VERSION_TAG}
                        """
                    }
                }
            }
        }

        stage('Build & Push Latest Image') {
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }
            steps {
                script {

                    env.LATEST_TAG = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-latest"

                    echo "Building LATEST image: ${env.LATEST_TAG}"

                    dir("${env.SERVICE_TO_BUILD}") {

                        sh """
                        docker build -t ${LATEST_TAG} .
                        docker push ${LATEST_TAG}
                        """
                    }
                }
            }
        }

    }

    post {

        success {
            echo "Build successful"
            echo "Service built: ${env.SERVICE_TO_BUILD}"
            echo "Version image: ${env.VERSION_TAG}"
            echo "Latest image: ${env.LATEST_TAG}"
        }

        failure {
            echo "Build failed"
        }

        always {
            cleanWs()
        }
    }
}

pipeline {

    // Run pipeline on any available Jenkins agent/node
    agent any

    options {
        // Adds timestamp to each log line (useful for debugging and audit)
        timestamps()
    }

    parameters {

        // Parameter to choose which service to build
        // auto = detect automatically from git changes
        // manual = user selects service explicitly
        choice(
            name: 'SERVICE',
            choices: ['auto', 'auth-service', 'invoice-api', 'invoice-worker'],
            description: 'auto = detect from git, or select service manually'
        )
    }

    environment {

        // AWS region where ECR repository exists
        AWS_REGION = "ap-south-1"

        // AWS account ID
        ACCOUNT_ID = "552993617387"

        // Full ECR repository URL
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecs-namespace/poc-ecr"
    }

    stages {

        stage('Checkout') {

            steps {

                // Checkout source code from GitHub repository configured in Jenkins
                checkout scm
            }
        }

        stage('Detect Service') {

            steps {

                script {

                    // If user manually selected service, use it directly
                    if (params.SERVICE != "auto") {

                        env.SERVICE_TO_BUILD = params.SERVICE

                        echo "Manual build selected: ${env.SERVICE_TO_BUILD}"

                        return
                    }

                    // Auto-detect service based on changed files in Git commit
                    echo "Auto-detecting changed service..."

                    def changedFiles = ""

                    // Get list of changed files from Jenkins changeSets (webhook trigger)
                    for (changeLog in currentBuild.changeSets) {

                        for (entry in changeLog.items) {

                            for (file in entry.affectedFiles) {

                                changedFiles += file.path + "\n"
                            }
                        }
                    }

                    changedFiles = changedFiles.trim()

                    // Fallback method if changeSets are empty (manual build or polling)
                    if (!changedFiles) {

                        changedFiles = sh(

                            script: "git diff --name-only origin/main HEAD || true",

                            returnStdout: true

                        ).trim()
                    }

                    // Determine which service needs build based on folder change
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

                        // No relevant service changes, exit pipeline safely
                        echo "No service changes detected. Exiting pipeline."

                        currentBuild.result = 'SUCCESS'

                        return
                    }

                    echo "Detected service: ${env.SERVICE_TO_BUILD}"
                }
            }
        }

        stage('Login to AWS ECR') {

            // Only run if a service was detected
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }

            steps {

                // Authenticate Docker with AWS ECR using AWS CLI
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

                    // Create version-specific tag using Jenkins build number
                    env.VERSION_TAG = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-${env.BUILD_NUMBER}"

                    // Create "latest" tag
                    env.LATEST_TAG  = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-latest"

                    echo "Building Docker image: ${VERSION_TAG}"

                    // Navigate into service folder containing Dockerfile
                    dir("${env.SERVICE_TO_BUILD}") {

                        // Build Docker image with version tag
                        sh """
                        docker build -t ${VERSION_TAG} .
                        """
                    }
                }
            }
        }

        stage('Trivy Security Scan') {

            // Run vulnerability scan before pushing image to ECR
            when {
                expression { env.SERVICE_TO_BUILD != null }
            }

            steps {

                script {

                    echo "Running Trivy security scan on image: ${VERSION_TAG}"

                    // Scan Docker image for CRITICAL and HIGH vulnerabilities
                    // If vulnerabilities found, pipeline will fail automatically
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

                // Tag same image as "latest"
                // This avoids rebuilding image twice
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

                // Push version tag and latest tag to AWS ECR
                sh """
                docker push ${VERSION_TAG}
                docker push ${LATEST_TAG}
                """
            }
        }

    }

    post {

        success {

            // Display success message with image details
            echo "Build and security scan successful"

            echo "Service built: ${env.SERVICE_TO_BUILD}"

            echo "Version image pushed: ${env.VERSION_TAG}"

            echo "Latest image pushed: ${env.LATEST_TAG}"
        }

        failure {

            // Display failure reason
            echo "Build failed due to vulnerabilities or build error"
        }

        always {

            // Clean Jenkins workspace after build
            cleanWs()
        }
    }
}
pipeline {

    agent any

    options {
        timestamps()                 // show timestamps in logs
        ansiColor('xterm')          // enable colored console output
        disableConcurrentBuilds()   // prevent parallel job conflicts
    }

    environment {

        AWS_REGION = "ap-south-1"

        ACCOUNT_ID = "552993617387"

        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecs-namespace/poc-ecr"

        TRIVY_REPORT_DIR = "trivy-reports"
    }

    stages {

        stage('Checkout Source') {

            steps {

                echo "Checking out source code..."

                checkout scm
            }
        }

        stage('Detect Changed Services (Branch Safe)') {

            steps {

                script {

                    echo "Detecting changed files from last commit..."

                    def changedFiles = sh(
                        script: '''
                        if [ -n "$GIT_PREVIOUS_SUCCESSFUL_COMMIT" ]; then
                            git diff --name-only $GIT_PREVIOUS_SUCCESSFUL_COMMIT $GIT_COMMIT
                        else
                            git diff --name-only HEAD~1 HEAD || true
                        fi
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Changed files:\n${changedFiles}"

                    def services = []

                    if (changedFiles.contains("auth-service")) {
                        services.add("auth-service")
                    }

                    if (changedFiles.contains("invoice-api")) {
                        services.add("invoice-api")
                    }

                    if (changedFiles.contains("invoice-worker")) {
                        services.add("invoice-worker")
                    }

                    if (services.isEmpty()) {

                        echo "No service changes detected. Skipping build."

                        currentBuild.result = 'SUCCESS'

                        return
                    }

                    env.SERVICES_TO_BUILD = services.join(",")

                    echo "Services detected: ${env.SERVICES_TO_BUILD}"
                }
            }
        }

        stage('Login to AWS ECR') {

            when {
                expression { env.SERVICES_TO_BUILD != null }
            }

            steps {

                echo "Logging into AWS ECR..."

                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

        stage('Build, Scan & Push Services') {

            when {
                expression { env.SERVICES_TO_BUILD != null }
            }

            steps {

                script {

                    sh "mkdir -p ${TRIVY_REPORT_DIR}"

                    def serviceList = env.SERVICES_TO_BUILD.split(",")

                    for (svc in serviceList) {

                        echo "======================================"
                        echo "Processing service: ${svc}"
                        echo "======================================"

                        def VERSION_TAG = "${ECR_REPO}:${svc}-${BUILD_NUMBER}"

                        def LATEST_TAG  = "${ECR_REPO}:${svc}-latest"

                        echo "Building image: ${VERSION_TAG}"

                        dir("${svc}") {

                            sh """
                            docker build -t ${VERSION_TAG} .
                            """

                            echo "Running Trivy scan..."

                            sh """
                            trivy image \
                              --exit-code 1 \
                              --severity CRITICAL,HIGH \
                              --scanners vuln \
                              --format json \
                              -o ../${TRIVY_REPORT_DIR}/${svc}-trivy-report.json \
                              ${VERSION_TAG}
                            """

                            echo "Tagging latest image..."

                            sh """
                            docker tag ${VERSION_TAG} ${LATEST_TAG}
                            """

                            echo "Pushing version image..."

                            sh """
                            docker push ${VERSION_TAG}
                            """

                            echo "Pushing latest image..."

                            sh """
                            docker push ${LATEST_TAG}
                            """
                        }
                    }
                }
            }
        }

        stage('Archive Trivy Reports') {

            when {
                expression { env.SERVICES_TO_BUILD != null }
            }

            steps {

                echo "Archiving Trivy reports..."

                archiveArtifacts artifacts: "${TRIVY_REPORT_DIR}/*.json", fingerprint: true
            }
        }
    }

    post {

        success {

            echo "======================================"
            echo "Build SUCCESS"
            echo "Services built: ${env.SERVICES_TO_BUILD}"
            echo "Images pushed to ECR"
            echo "======================================"
        }

        failure {

            echo "======================================"
            echo "Build FAILED"
            echo "Reason: CRITICAL or HIGH vulnerability OR build error"
            echo "Check Trivy reports"
            echo "======================================"
        }

        always {

            echo "Cleaning workspace..."

            cleanWs()
        }
    }
}
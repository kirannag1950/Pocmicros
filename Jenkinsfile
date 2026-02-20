pipeline {

    agent any

    options {
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
    }

    parameters {

        choice(
            name: 'SERVICE',
            choices: ['auto', 'auth-service', 'invoice-api', 'invoice-worker', 'all'],
            description: '''
auto = detect changed services automatically (webhook)
auth-service = build only auth-service
invoice-api = build only invoice-api
invoice-worker = build only invoice-worker
all = build all services
'''
        )
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

        stage('Detect Services to Build') {

            steps {

                script {

                    def services = []

                    // Manual build mode
                    if (params.SERVICE == "all") {

                        echo "Manual build selected: ALL services"

                        services = [
                            "auth-service",
                            "invoice-api",
                            "invoice-worker"
                        ]
                    }
                    else if (params.SERVICE != "auto") {

                        echo "Manual build selected: ${params.SERVICE}"

                        services = [params.SERVICE]
                    }
                    else {

                        echo "Webhook/Auto mode: detecting changed services..."

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

                        echo "Changed files:"
                        echo "${changedFiles}"

                        if (changedFiles.contains("auth-service")) {
                            services.add("auth-service")
                        }

                        if (changedFiles.contains("invoice-api")) {
                            services.add("invoice-api")
                        }

                        if (changedFiles.contains("invoice-worker")) {
                            services.add("invoice-worker")
                        }
                    }

                    if (services.isEmpty()) {

                        echo "No services detected. Skipping build."

                        currentBuild.result = 'SUCCESS'

                        return
                    }

                    env.SERVICES_TO_BUILD = services.join(",")

                    echo "Final services list: ${env.SERVICES_TO_BUILD}"
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

        stage('Build, Scan and Push') {

            when {
                expression { env.SERVICES_TO_BUILD != null }
            }

            steps {

                script {

                    sh "mkdir -p ${TRIVY_REPORT_DIR}"

                    def serviceList = env.SERVICES_TO_BUILD.split(",")

                    for (svc in serviceList) {

                        echo "========================================"
                        echo "Processing service: ${svc}"
                        echo "========================================"

                        def VERSION_TAG = "${ECR_REPO}:${svc}-${BUILD_NUMBER}"
                        def LATEST_TAG  = "${ECR_REPO}:${svc}-latest"

                        dir("${svc}") {

                            echo "Building Docker image..."

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

            echo "========================================"
            echo "BUILD SUCCESS"
            echo "Services built: ${env.SERVICES_TO_BUILD}"
            echo "Images pushed to ECR successfully"
            echo "========================================"
        }

        failure {

            echo "========================================"
            echo "BUILD FAILED"
            echo "Reason: CRITICAL or HIGH vulnerability OR build error"
            echo "========================================"
        }

        always {

            echo "Cleaning workspace..."

            cleanWs()
        }
    }
}
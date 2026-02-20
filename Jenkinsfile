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
            description: 'auto = webhook detect, or manually select service'
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

                    if (params.SERVICE == "all") {

                        services = [
                            "auth-service",
                            "invoice-api",
                            "invoice-worker"
                        ]

                        echo "Manual build ALL services"
                    }
                    else if (params.SERVICE != "auto") {

                        services = [params.SERVICE]

                        echo "Manual build ${params.SERVICE}"
                    }
                    else {

                        echo "Webhook mode detecting changes..."

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

                        echo "No services to build"

                        currentBuild.result = 'SUCCESS'

                        return
                    }

                    env.SERVICES_TO_BUILD = services.join(",")

                    echo "Services to build: ${env.SERVICES_TO_BUILD}"
                }
            }
        }

        stage('Login to AWS ECR') {

            when {
                expression { env.SERVICES_TO_BUILD != null }
            }

            steps {

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

                        echo "Processing ${svc}"

                        def VERSION_TAG = "${ECR_REPO}:${svc}-${BUILD_NUMBER}"

                        def LATEST_TAG  = "${ECR_REPO}:${svc}-latest"

                        dir("${svc}") {

                            sh """
                            docker build -t ${VERSION_TAG} .
                            """

                            script {

                                def jsonReport = "../${TRIVY_REPORT_DIR}/${svc}-trivy-report.json"
                                def txtReport  = "../${TRIVY_REPORT_DIR}/${svc}-trivy-report.txt"

                                // JSON scan
                                def exitCode = sh(
                                    script: """
                                    trivy image \
                                      --severity CRITICAL,HIGH \
                                      --scanners vuln \
                                      --format json \
                                      -o ${jsonReport} \
                                      ${VERSION_TAG}
                                    """,
                                    returnStatus: true
                                )

                                // Table scan
                                sh """
                                trivy image \
                                  --severity CRITICAL,HIGH \
                                  --scanners vuln \
                                  --format table \
                                  -o ${txtReport} \
                                  ${VERSION_TAG}
                                """

                                // ✅ FIXED PATH HERE
                                archiveArtifacts artifacts: "../${TRIVY_REPORT_DIR}/*", fingerprint: true

                                // Fail after archive
                                if (exitCode != 0) {

                                    error("CRITICAL or HIGH vulnerabilities found in ${svc}. Download report from Jenkins artifacts.")
                                }
                            }

                            sh """
                            docker tag ${VERSION_TAG} ${LATEST_TAG}
                            docker push ${VERSION_TAG}
                            docker push ${LATEST_TAG}
                            """
                        }
                    }
                }
            }
        }
    }

    post {

        success {

            echo "Build SUCCESS"
            echo "Services built: ${env.SERVICES_TO_BUILD}"
        }

        failure {

            echo "Build FAILED"
            echo "Download Trivy report from Jenkins → Build → Artifacts"
        }

        always {

            echo "Cleaning workspace..."

            cleanWs()
        }
    }
}
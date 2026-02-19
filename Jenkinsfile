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

            // Manual build takes priority
            if (params.SERVICE != "auto") {

                env.SERVICE_TO_BUILD = params.SERVICE

                echo "Manual build selected: ${env.SERVICE_TO_BUILD}"
                return
            }

            // Automatic detection
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
                echo "No service change detected. Skipping build."
                currentBuild.result = 'SUCCESS'
                return
            }

            echo "Detected service: ${env.SERVICE_TO_BUILD}"
        }
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

        stage('Build Image') {
    when {
        expression { env.SERVICE_TO_BUILD != null }
    }
    steps {
        script {

            def IMAGE = "${ECR_REPO}:${env.SERVICE_TO_BUILD}-${env.BUILD_NUMBER}"

            dir("${env.SERVICE_TO_BUILD}") {
                sh "docker build -t ${IMAGE} ."
            }

            sh "docker push ${IMAGE}"

            echo "Pushed image: ${IMAGE}"
        }
    }
}

    post {
        success {
            echo "Build completed successfully"
        }
        failure {
            echo "Build failed"
        }
    }
}

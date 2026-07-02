pipeline {
    agent any

    environment {
        // Core Variables
        APP_DIR        = 'instamart-backend'
        AWS_REGION     = 'us-east-1' 
        CLUSTER_NAME   = 'instamart-prod-cluster'
        AWS_ACCOUNT_ID = '397920213006' // Your AWS Account ID
        
        // ECR Variables
        ECR_REPO       = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/instamart-backend"
        IMAGE_TAG      = "v${BUILD_NUMBER}"
        FULL_IMAGE     = "${ECR_REPO}:${IMAGE_TAG}"

        // Secrets Management
        SSM_PARAM_NAME = '/instamart/dev/database/credentials'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out source code...'
                git branch: 'main', 
                    credentialsId: 'github-token', 
                    url: 'https://github.com/nikithaboopathy/instamart.git'
            }
        }

        stage('Build & Unit Test') {
            steps {
                dir("${APP_DIR}") {
                    echo 'Building Spring Boot application with Maven...'
                    sh 'mvn clean package'
                }
            }
        }

        stage('Static Code Analysis (SonarQube)') {
            environment {
                SCANNER_HOME = tool 'sonar-scanner'
            }
            steps {
                dir("${APP_DIR}") {
                    withSonarQubeEnv('sonar-server') {
                        sh '''
                            $SCANNER_HOME/bin/sonar-scanner \
                            -Dsonar.projectKey=instamart-backend \
                            -Dsonar.java.binaries=target/classes
                        '''
                    }
                }
            }
        }

        stage('Secure Credential Fetch (SSM)') {
            steps {
                script {
                    echo 'Authenticating via IAM to fetch DB secrets...'
                    
                    def secretJson = sh(
                        script: "aws ssm get-parameter --region ${AWS_REGION} --name ${SSM_PARAM_NAME} --with-decryption --query 'Parameter.Value' --output text",
                        returnStdout: true
                    ).trim()

                    def dbCredentials = readJSON text: secretJson

                    env.DB_URL  = dbCredentials.spring_url
                    env.DB_USER = dbCredentials.username
                    env.DB_PASS = dbCredentials.password
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                dir("${APP_DIR}") {
                    echo "Building Docker Image: ${FULL_IMAGE}"
                    sh "docker build -t ${FULL_IMAGE} ."
                    
                    echo 'Authenticating with AWS ECR...'
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
                    
                    echo 'Pushing image to ECR...'
                    sh "docker push ${FULL_IMAGE}"
                }
            }
        }

        stage('Deploy to EKS (Helm)') {
            steps {
                script {
                    echo 'Updating Kubeconfig...'
                    sh "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}"
                    
                    echo 'Executing Helm Upgrade...'
                    // NOTE: Adjust './instamart-backend' to the actual path where you saved your Helm Chart
                    sh """
                        helm upgrade --install instamart-backend ./instamart-backend \\
                        --set image.repository=${ECR_REPO} \\
                        --set image.tag=${IMAGE_TAG} \\
                        --namespace default
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution complete.'
            cleanWs()
        }
        success {
            echo "Deployment Successful! Version ${IMAGE_TAG} is now live on EKS."
        }
        failure {
            echo 'Pipeline failed. Check the Jenkins logs for the exact stage failure.'
        }
    }
}

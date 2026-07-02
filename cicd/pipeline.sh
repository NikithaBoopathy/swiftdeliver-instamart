pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        maven 'maven-3'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo "Pulling Spring Boot backend code from Git..."
                git branch: 'main', url: 'YOUR-GITHUB-URL-HERE'
            }
        }
        
        stage('2. Build & Compile') {
            steps {
                echo "Compiling the application..."
		dir('instamart-backend'){
                sh 'mvn clean package -DskipTests'
	}
            }
        }
        
        stage('3. Static Security Scan (SAST)') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    echo "Executing deep security analysis..."
		    dir('instamart-backend') {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                      -Dsonar.projectKey=instamart-backend \
                      -Dsonar.projectName="Instamart Backend" \
                      -Dsonar.java.binaries=target/classes
                    '''
	    }
                }
            }
        }
        
        stage('4. The Quality Gate') {
            steps {
                echo "Awaiting SonarQube security verdict..."
                waitForQualityGate abortPipeline: true
            }
        }
    }
}

pipeline {
  agent any

   environment {
//     AWS_REGION     = 'us-east-1'
//     AWS_ACCOUNT_ID = '<your-aws-account-id>'
     ECR_REPO       = 'my-ecr-repo'
     IMAGE_TAG      = "${env.BUILD_NUMBER}"
//     CLUSTER        = 'my-ecs-cluster'
//     SERVICE        = 'my-ecs-service'
   }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: 'main', credentialsId: 'git credentials', url: 'https://github.com/sanjeev0575/DevOps.git'
      }
    
    }
    stage('Build Docker Image') {
      steps {
        script {
            // sh "sudo groupadd docker"
            // sh "sudo usermod -aG docker $USER"
            dockerImage = docker.build("${ECR_REPO}:${IMAGE_TAG}")
        }
      }
    }
    }

}


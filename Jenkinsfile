pipeline {
  agent any

   environment {
     AWS_REGION     = 'us-east-1'
     AWS_ACCOUNT_ID = '115456585578'
     ECR_REPO       = 'devops'
     IMAGE_TAG      = "${env.BUILD_NUMBER}"
    CLUSTER        = 'my-ecs-cluster-devops'
    SERVICE        = 'my-ecs-service-devops
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
            dockerImage = docker.build("${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}") 
            // docker.build("${ECR_REPO}:${IMAGE_TAG}")
        }
      }
    }
  stage('Login to ECR') {
   steps {
    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
      sh '''
        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
        aws configure set region $AWS_REGION
        aws sts get-caller-identity
        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
      '''
    }
  }
  }
  stage('Pushing to ECR') {
    steps {
      // sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
      sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
    }
  }

  stage('Cleanup Docker Images') {
    steps {
        script {
            sh '''
            echo "Cleaning up Docker images..."
            docker image prune -af
            '''
        }
    }
  }
  stage('Deploy to ECS') {
    steps {
      sh '''
        aws ecs update-service \
                    --cluster $CLUSTER_NAME \
                    --service $SERVICE_NAME \
                    --force-new-deployment \
                    --region $AWS_REGION
                '''
    }
  }


  }

}


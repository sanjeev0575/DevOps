pipeline {
  agent any

//   environment {
//     AWS_REGION     = 'us-east-1'
//     AWS_ACCOUNT_ID = '<your-aws-account-id>'
//     ECR_REPO       = 'my-ecr-repo'
//     IMAGE_TAG      = "${env.BUILD_NUMBER}"
//     CLUSTER        = 'my-ecs-cluster'
//     SERVICE        = 'my-ecs-service'
//   }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: 'main', credentialsId: 'git credentials', url: 'https://github.com/sanjeev0575/DevOps.git'
      }
    }

    // stage('Build Docker Image') {
    //   steps {
    //     script {
    //       dockerImage = docker.build("${ECR_REPO}:${IMAGE_TAG}")
    //     }
    //   }
    // }

    // stage('Login to ECR') {
    //   steps {
    //     sh '''
    //     aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
    //     '''
    //   }
    // }

    // stage('Push to ECR') {
    //   steps {
    //     sh '''
    //     docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
    //     docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
    //     '''
    //   }
    // }

    // stage('Deploy to ECS') {
    //   steps {
    //     sh '''
    //     aws ecs update-service \
    //       --cluster $CLUSTER \
    //       --service $SERVICE \
    //       --force-new-deployment \
    //       --region $AWS_REGION
    //     '''
    //   }
    // }
  }

  post {
    success {
      echo "✅ Deployment to ECS successful!"
    }
    failure {
      echo "❌ Deployment failed."
    }
  }
}

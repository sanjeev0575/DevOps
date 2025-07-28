pipeline {
  agent any

  environment {
    AWS_REGION     = 'us-east-1'
    AWS_ACCOUNT_ID = '115456585578'
    ECR_REPO       = 'devops'
    IMAGE_TAG      = "${env.BUILD_NUMBER}"
    CLUSTER        = 'my-ecs-cluster'
    SERVICE        = 'my-ecs-service'
    ALB_NAME       = 'my-app-alb'
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
        }
      }
    }

    stage('Login to ECR') {
      steps {
        withCredentials([aws(
          credentialsId: 'aws-cred',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
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

    stage('Push Docker Image to ECR') {
      steps {
        sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
      }
    }

    stage('Cleanup Docker Images') {
      steps {
        sh '''
          echo "Cleaning up Docker images..."
          docker image prune -af
        '''
      }
    }

    // stage('Deploy to ECS') {
    //   steps {
    //     sh '''
    //       aws ecs update-service \
    //         --cluster $CLUSTER \
    //         --service $SERVICE \
    //         --force-new-deployment \
    //         --region $AWS_REGION
    //     '''
    //   }
    // }
    // stage('Wait for Deployment') {
    //   steps {
    //     sh '''
    //     while true; do
    //       STATUS=$(aws ecs describe-services \
    //         --cluster $CLUSTER \
    //         --services $SERVICE \
    //         --region $AWS_REGION \
    //         --query "services[0].deployments[0].rolloutState" \
    //         --output text)

    //       echo "Deployment status: $STATUS"

    //       if [ "$STATUS" = "COMPLETED" ]; then
    //         echo "Deployment completed!"
    //         break
    //       fi

    //       sleep 10
    //     done
    //     '''
    //   }
    // }
    // stage('Get App URL') {
    //   steps {
    //     script {
    //       def url = sh(
    //         script: "aws elbv2 describe-load-balancers --names $ALB_NAME --region $AWS_REGION --query 'LoadBalancers[0].DNSName' --output text",
    //         returnStdout: true
    //       ).trim()
    //       echo "✅ Application is available at: http://${url}"
    //     }
    //   }
    // }

  }
}

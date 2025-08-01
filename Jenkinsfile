// pipeline {
//   agent any

//   environment {
//     AWS_REGION     = 'us-east-1'
//     AWS_ACCOUNT_ID = '115456585578'
//     ECR_REPO       = 'devops'
//     IMAGE_TAG      = "${env.BUILD_NUMBER}"
//     CLUSTER        = 'my-ecs-cluster'
//     SERVICE        = 'my-ecs-service'
//     TASK_FAMILY    = 'python-app-task'
//   }

//   stages {

//     stage('Checkout Code') {
//       steps {
//         git branch: 'main', credentialsId: 'git credentials', url: 'https://github.com/sanjeev0575/DevOps.git'
//       }
//     }

//     stage('Build Docker Image') {
//       steps {
//         script {
//           dockerImage = docker.build("${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}")
//         }
//       }
//     }

//     stage('Login to ECR') {
//       steps {
//         withCredentials([aws(
//           credentialsId: 'aws-cred',
//           accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//           secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//         )]) {
//           sh '''
//             aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
//             aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
//             aws configure set region $AWS_REGION
//             aws sts get-caller-identity
//             aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
//           '''
//         }
//       }
//     }

//     stage('Push Docker Image to ECR') {
//       steps {
//         sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
//       }
//     }

//   //   stage('Cleanup Docker Images') {
//   //     steps {
//   //       sh '''
//   //         echo "Cleaning up Docker images..."
//   //         docker image prune -af
//   //       '''
//   //     }
//   //   }
//   //   stage('Update Task Definition') {
//   //     steps {
//   //       sh '''
        
//   //       TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY)
//   //       NEW_TASK_DEF=$(echo $TASK_DEF | jq --arg IMAGE "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | {family: .family, containerDefinitions: .containerDefinitions, networkMode: .networkMode, requiresCompatibilities: .requiresCompatibilities, cpu: .cpu, memory: .memory, executionRoleArn: .executionRoleArn}')
//   //       echo $NEW_TASK_DEF > new-task-def.json
//   //       aws ecs register-task-definition --cli-input-json file://new-task-def.json

//   //       '''
//   //     }
//   //   }
//   //   stage('Debug Cluster & Service') {
//   //     steps {
//   //       sh '''
//   //         echo "Verifying cluster and service..."
//   //         aws ecs describe-clusters --clusters $CLUSTER --region $AWS_REGION
//   //         aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION
//   //       '''
//   //     } 
//   //   }

//   //   stage('Deploy to ECS') {
//   //     steps {
//   //       sh """
//   //       aws ecs update-service \
//   //         --cluster $CLUSTER \
//   //         --service $SERVICE \
//   //         --force-new-deployment
//   //       """
//   //     }

    

//   // }
// }
// }

// pipeline {
//   agent any

//   environment {
//     AWS_REGION     = 'us-east-1'
//     AWS_ACCOUNT_ID = '115456585578'
//     ECR_REPO       = 'devops'
//     IMAGE_TAG      = "${env.BUILD_NUMBER}"
//     CLUSTER        = 'my-ecs-cluster'
//     SERVICE        = 'my-ecs-service'
//     TASK_FAMILY    = 'python-app-task'
//     TASK_ROLE_ARN  = 'arn:aws:iam::115456585578:role/ecsTaskExecutionRole' // Update with your IAM role ARN
//     SUBNETS        = 'subnet-0cefa984039dbc9df' 
//     SECURITY_GROUPS = 'sg-017eeb5250435bd47' 
//     TARGET_GROUP_ARN = 'arn:aws:elasticloadbalancing:us-east-1:115456585578:loadbalancer/app/my-app-alb/c46bba7037581096' // Update with your target group ARN
//   }

//   stages {
//     stage('Checkout Code') {
//       steps {
//         git branch: 'main', credentialsId: 'git credentials', url: 'https://github.com/sanjeev0575/DevOps.git'
//       }
//     }

//     stage('Build Docker Image') {
//       steps {
//         script {
//           dockerImage = docker.build("${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}")
//         }
//       }
//     }

//     stage('Login to ECR') {
//       steps {
//         withCredentials([aws(
//           credentialsId: 'aws-cred',
//           accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//           secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//         )]) {
//           sh '''
//             aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
//           '''
//         }
//       }
//     }

//     stage('Push Docker Image to ECR') {
//       steps {
//         sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
//       }
//     }

//     stage('Update Task Definition') {
//       steps {
//         sh '''
//           cat > task-definition.json <<EOF
//           {
//             "family": "${TASK_FAMILY}",
//             "networkMode": "awsvpc",
//             "containerDefinitions": [
//               {
//                 "name": "python-app",
//                 "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}",
//                 "essential": true,
//                 "portMappings": [
//                   {
//                     "containerPort": 5000,
//                     "hostPort": 5000,
//                     "protocol": "tcp"
//                   }
//                 ],
//                 "logConfiguration": {
//                   "logDriver": "awslogs",
//                   "options": {
//                     "awslogs-group": "/ecs/python-app",
//                     "awslogs-region": "${AWS_REGION}",
//                     "awslogs-stream-prefix": "ecs"
//                   }
//                 }
//               }
//             ],
//             "requiresCompatibilities": ["FARGATE"],
//             "cpu": "256",
//             "memory": "512",
//             "executionRoleArn": "${TASK_ROLE_ARN}",
//             "taskRoleArn": "${TASK_ROLE_ARN}"
//           }
//           EOF
//           aws ecs register-task-definition --cli-input-json file://task-definition.json
//         '''
//       }
//     }

//     stage('Deploy to ECS') {
//       steps {
//         sh '''
//           aws ecs update-service \
//             --cluster ${CLUSTER} \
//             --service ${SERVICE} \
//             --task-definition ${TASK_FAMILY} \
//             --force-new-deployment \
//             --region ${AWS_REGION}
//         '''
//       }
//     }

//     stage('Verify Deployment') {
//       steps {
//         sh '''
//           aws ecs describe-services \
//             --cluster ${CLUSTER} \
//             --services ${SERVICE} \
//             --region ${AWS_REGION}
//         '''
//       }
//     }

//     stage('Cleanup Docker Images') {
//       steps {
//         sh '''
//           echo "Cleaning up Docker images..."
//           docker image prune -af
//         '''
//       }
//     }
//   }

//   post {
//     always {
//       cleanWs()
//     }
//     success {
//       echo 'Deployment to ECS completed successfully!'
//     }
//     failure {
//       echo 'Deployment failed. Please check the logs.'
//     }
//   }
// }

pipeline {
  agent any

  environment {
    AWS_REGION       = 'us-east-1'
    AWS_ACCOUNT_ID   = '115456585578'
    ECR_REPOSITORY   = 'devops'
    IMAGE_TAG        = "${env.BUILD_NUMBER}"
    CLUSTER          = 'my-ecs-cluster-automated-deploy'
    SERVICE          = 'my-ecs-service-automated-deploy'
    TASK_FAMILY      = 'python-app-task-automated'
    TASK_DEFINITION_NAME = 'automated-deploy-task'
    CONTAINER_NAME = 'my-app-container'
    ECR_REGISTRY = '115456585578.dkr.ecr.us-east-1.amazonaws.com'

  }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: 'main', credentialsId: 'git-credentials', url: 'https://github.com/sanjeev0575/DevOps.git'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          dockerImage = docker.build("${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}")
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
            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
            docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
          '''
        }
      }
    }
    // stage('Update Task Definition') {
    //   steps {
    //     script {
    //       // Update task-definition.json with new image
    //       sh """
    //         sed -i 's|${ECR_REGISTRY}/${ECR_REPOSITORY}:.*|${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}|' task-definition.json
    //         aws ecs register-task-definition --cli-input-json file://task-definition.json --region ${AWS_REGION}
    //       """
    //     }
    //   }
    // }
  // stage('Update Task Definition') {
  //   steps {
  //     script {
  //       sh """
  //         export TASK_FAMILY=${TASK_FAMILY}
  //         export CONTAINER_NAME=${CONTAINER_NAME}
  //         export IMAGE_TAG=${IMAGE_TAG}
  //         export AWS_REGION=${AWS_REGION}
  //         export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
  //         export ECR_REPOSITORY=${ECR_REPOSITORY}
  //         export ECR_REGISTRY=${ECR_REGISTRY}

  //         envsubst < task-definition-template.json > task-definition.json

  //         echo '==== Rendered task-definition.json ===='
  //         cat task-definition.json

  //         echo '==== Validating JSON ===='
  //         jq . task-definition.json

  //         echo '==== Registering task ===='
  //         aws ecs register-task-definition --cli-input-json file://task-definition-rendered.json

  //       """
  //       }
  //     }
  //   }
  stage('Update Task Definition') {
    steps {
      withCredentials([aws(
        credentialsId: 'aws-cred',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
        sh '''
          #— export all vars so envsubst can see them
          export AWS_ACCOUNT_ID='115456585578'
          export AWS_REGION='us-east-1'
          export ECR_REPOSITORY='devops'
          export ECR_REGISTRY='115456585578.dkr.ecr.us-east-1.amazonaws.com'
          export IMAGE_TAG='${BUILD_NUMBER}'
          export CONTAINER_NAME='my-app-container'
          export TASK_DEFINITION_NAME='automated-deploy-task'

          #— render template into valid JSON
          envsubst < task-definition-template.json > task-definition-rendered.json

          #— debug / validate
          echo '---- rendered task-definition ----'
          cat task-definition-rendered.json
          echo '---- validating JSON via jq ----'
          jq . task-definition-rendered.json

          #— register with ECS
          aws ecs register-task-definition \
            --cli-input-json file://task-definition-rendered.json \
            --region $AWS_REGION
          '''
        }
      }
    }



  }
}

    
    // AWS_REGION = 'us-east-1'
    // ECR_REGISTRY = '115456585578.dkr.ecr.us-east-1.amazonaws.com'
    // ECR_REPOSITORY = 'my-app-repo'
    // ECS_CLUSTER = 'my-app-cluster'
    // ECS_SERVICE = 'my-app-service'
    // TASK_DEFINITION_NAME = 'my-app-task'
    // CONTAINER_NAME = 'my-app-container'
    // IMAGE_TAG = "${env.BUILD_NUMBER}
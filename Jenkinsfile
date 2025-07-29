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
    ECR_REPO         = 'devops'
    IMAGE_TAG        = "${env.BUILD_NUMBER}"
    CLUSTER          = 'my-ecs-cluster'
    SERVICE          = 'my-ecs-service'
    TASK_FAMILY      = 'python-app-task'
    TASK_ROLE_ARN    = 'arn:aws:iam::115456585578:role/ecsTaskExecutionRole'
    SUBNETS          = 'subnet-0cefa984039dbc9df,subnet-00d20a28ebb69e58e'
    SECURITY_GROUPS  = 'sg-017eeb5250435bd47'
    //TARGET_GROUP_ARN = 'aarn:aws:elasticloadbalancing:us-east-1:115456585578:targetgroup/my-python-app-tg/c5a4165738f30115' // Update with correct ARN
    TARGET_GROUP_ARN = 'arn:aws:elasticloadbalancing:us-east-1:115456585578:listener/app/simple-application/df4c92b13fd4b139/5c039e2c260350a7

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

    stage('Update Task Definition') {
      steps {
        withCredentials([aws(
          credentialsId: 'aws-cred',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        )])  {
        sh '''
          cat > task-definition.json <<EOF
          {
            "family": "${TASK_FAMILY}",
            "networkMode": "awsvpc",
            "containerDefinitions": [
              {
                "name": "python-app",
                "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}",
                "essential": true,
                "portMappings": [
                  {
                    "containerPort": 5000,
                    "hostPort": 5000,
                    "protocol": "tcp"
                  }
                ],
                "logConfiguration": {
                  "logDriver": "awslogs",
                  "options": {
                    "awslogs-group": "/ecs/python-app",
                    "awslogs-region": "${AWS_REGION}",
                    "awslogs-stream-prefix": "ecs"
                  }
                }
              }
            ],
            "requiresCompatibilities": ["FARGATE"],
            "cpu": "256",
            "memory": "512",
            "executionRoleArn": "${TASK_ROLE_ARN}",
            "taskRoleArn": "${TASK_ROLE_ARN}"
          }
          EOF
          aws ecs register-task-definition --cli-input-json file://task-definition.json --region $AWS_REGION
        '''
      }
    }
    }
    stage('Check or Create ECS Service') {
      steps {
        withCredentials([aws(
          credentialsId: 'aws-cred',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
        sh '''
          SERVICE_STATUS=$(aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION --query 'services[0].status' --output text || echo "NONE")
          if [ "$SERVICE_STATUS" != "ACTIVE" ]; then
            echo "Service does not exist or is not ACTIVE. Creating service..."
            aws ecs create-service \
              --cluster $CLUSTER \
              --service-name $SERVICE \
              --task-definition $TASK_FAMILY \
              --desired-count 1 \
              --launch-type FARGATE \
              --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUPS],assignPublicIp=ENABLED}" \
              --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=python-app,containerPort=5000" \
              --region $AWS_REGION
          else
            echo "Service is ACTIVE. Proceeding to update..."
            aws ecs update-service \
              --cluster $CLUSTER \
              --service $SERVICE \
              --task-definition $TASK_FAMILY \
              --force-new-deployment \
              --region $AWS_REGION
          fi
        '''
      }
    }
    }
    // stage('Verify Deployment') {
    //   steps {
    //     withCredentials([aws(
    //       credentialsId: 'aws-cred',
    //       accessKeyVariable: 'AWS_ACCESS_KEY_ID',
    //       secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
    //     )]){
    //     sh '''
    //       aws ecs wait services-stable --cluster $CLUSTER --services $SERVICE --region $AWS_REGION
    //       aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION
    //     '''
    //   }
    // }
    // }
    stage('Cleanup Docker Images') {
      steps {
        sh '''
          echo "Cleaning up Docker images..."
          docker image prune -af
        '''
      }
    }
  }

  post {
    always {
      cleanWs()
    }
    success {
      echo 'Deployment to ECS completed successfully!'
    }
    failure {
      echo 'Deployment failed. Please check the logs.'
    }
  }
}
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

// pipeline {
//     agent any

//     environment {
//         AWS_REGION = 'us-east-1'
//         AWS_ACCOUNT_ID = '115456585578'
//         ECR_REPOSITORY = 'devops'
//         IMAGE_TAG = "${env.BUILD_NUMBER}"
//         ECS_CLUSTER = 'my-ecs-cluster-automated-deploy'
//         ECS_SERVICE = 'my-ecs-service-automated-deploy'
//         TASK_FAMILY = 'python-app-task-automated'
//         TASK_DEFINITION_NAME = 'automated-deploy-task'
//         CONTAINER_NAME = 'my-app-container'
//     }

//     stages {
//         stage('Checkout Code') {
//             steps {
//                 git branch: 'main', credentialsId: 'git-credentials', url: 'https://github.com/sanjeev0575/DevOps.git'
//             }
//         }

//         stage('Build Docker Image') {
//             steps {
//                 script {
//                     dockerImage = docker.build("${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}")
//                 }
//             }
//         }

//         stage('Login to ECR') {
//             steps {
//                 withCredentials([aws(
//                     credentialsId: 'aws-cred',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 )]) {
//                     sh '''
//                         aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
//                     '''
//                 }
//             }
//         }

//         stage('Push to ECR') {
//             steps {
//                 script {
//                     dockerImage.push()
//                     dockerImage.push('latest')
//                 }
//             }
//         }

//         stage('Update Task Definition') {
//             steps {
//                 withCredentials([aws(
//                     credentialsId: 'aws-cred',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 )]) {
//                     script {
//                         // Render task definition
//                         sh '''
//                             echo "Using IMAGE_TAG: ${IMAGE_TAG}"
//                             envsubst < task-definition-template.json > task-definition-rendered.json
//                             echo "--- Rendered JSON ---"
//                             cat task-definition-rendered.json
//                             echo "--- Validating JSON ---"
//                             jq . task-definition-rendered.json
//                         '''

//                         // Register task definition and capture ARN
//                         def taskDefinitionOutput = sh(
//                             script: '''
//                                 aws ecs register-task-definition \
//                                     --cli-input-json file://task-definition-rendered.json \
//                                     --region ${AWS_REGION} \
//                                     --query 'taskDefinition.taskDefinitionArn' \
//                                     --output text
//                             ''',
//                             returnStdout: true
//                         ).trim()
//                         env.TASK_DEFINITION_ARN = taskDefinitionOutput
//                         echo "Registered Task Definition ARN: ${TASK_DEFINITION_ARN}"
//                     }
//                 }
//             }
//         }

//         stage('Deploy to ECS') {
//             steps {
//                 withCredentials([aws(
//                     credentialsId: 'aws-cred',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 )]) {
//                     script {
//                         sh '''
//                             aws ecs update-service \
//                                 --cluster ${ECS_CLUSTER} \
//                                 --service ${ECS_SERVICE} \
//                                 --task-definition ${TASK_DEFINITION_ARN} \
//                                 --force-new-deployment \
//                                 --region ${AWS_REGION}
//                         '''
//                     }
//                 }
//             }
//         }
//     }

//     post {
//         always {
//             sh 'docker system prune -f'
//         }
//         success {
//             echo 'Pipeline completed successfully!'
//         }
//         failure {
//             echo 'Pipeline failed. Check logs for details.'
//         }
//     }
// }



pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '115456585578'
        ECR_REPOSITORY = 'devops'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        ECS_CLUSTER = 'my-ecs-cluster-automated-deploy'
        ECS_SERVICE = 'my-ecs-service-automated-deploy'
        TASK_FAMILY = 'python-app-task-automated'
        TASK_DEFINITION_NAME = 'automated-deploy-task'
        CONTAINER_NAME = 'my-app-container'
        // Add your VPC subnet and security group IDs
        SUBNET_IDS = 'subnet-01d7c4a4a6f9235e6,subnet-01c1ca97fe8b13fb1' // Replace with actual subnet IDs
        SECURITY_GROUP_IDS = 'sg-0644fd647017edcbf' // Replace with actual security group ID
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
                    try {
                        dockerImage = docker.build("${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}")
                    } catch (Exception e) {
                        error "Failed to build Docker image: ${e}"
                    }
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
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    try {
                        dockerImage.push()
                        dockerImage.push('latest')
                    } catch (Exception e) {
                        error "Failed to push Docker image to ECR: ${e}"
                    }
                }
            }
        }

        stage('Update Task Definition') {
            steps {
                withCredentials([aws(
                    credentialsId: 'aws-cred',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        try {
                            sh '''
                                echo "Using IMAGE_TAG: ${IMAGE_TAG}"
                                envsubst < task-definition-template.json > task-definition-rendered.json
                                echo "--- Rendered JSON ---"
                                cat task-definition-rendered.json
                                echo "--- Validating JSON ---"
                                jq . task-definition-rendered.json
                            '''

                            def taskDefinitionOutput = sh(
                                script: '''
                                    aws ecs register-task-definition \
                                        --cli-input-json file://task-definition-rendered.json \
                                        --region ${AWS_REGION} \
                                        --query 'taskDefinition.taskDefinitionArn' \
                                        --output text
                                ''',
                                returnStdout: true
                            ).trim()
                            env.TASK_DEFINITION_ARN = taskDefinitionOutput
                            echo "Registered Task Definition ARN: ${TASK_DEFINITION_ARN}"
                        } catch (Exception e) {
                            error "Failed to register task definition: ${e}"
                        }
                    }
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
                    script {
                        try {
                            def serviceExists = sh(
                                script: """
                                    aws ecs describe-services \
                                        --cluster ${ECS_CLUSTER} \
                                        --services ${ECS_SERVICE} \
                                        --region ${AWS_REGION} \
                                        --query 'services[0].status' \
                                        --output text || echo 'NONE'
                                """,
                                returnStdout: true
                            ).trim()

                            if (serviceExists == 'ACTIVE') {
                                echo "Service ${ECS_SERVICE} exists and is active."
                            } else {
                                echo "Service ${ECS_SERVICE} not found. Creating it..."
                                sh """
                                    aws ecs create-service \
                                        --cluster ${ECS_CLUSTER} \
                                        --service-name ${ECS_SERVICE} \
                                        --task-definition ${TASK_DEFINITION_ARN} \
                                        --desired-count 1 \
                                        --launch-type FARGATE \
                                        --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_IDS}],assignPublicIp=ENABLED}" \
                                        --region ${AWS_REGION}
                                """
                            }
                        } catch (Exception e) {
                            error "Failed to check or create ECS service: ${e}"
                        }
                    }
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([aws(
                    credentialsId: 'aws-cred',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        try {
                            sh """
                                aws ecs update-service \
                                    --cluster ${ECS_CLUSTER} \
                                    --service ${ECS_SERVICE} \
                                    --task-definition ${TASK_DEFINITION_ARN} \
                                    --force-new-deployment \
                                    --region ${AWS_REGION}
                            """
                        } catch (Exception e) {
                            error "Failed to deploy to ECS: ${e}"
                        }
                    }
                }
            }
        }

        stage('Wait for Service Stability') {
            steps {
                withCredentials([aws(
                    credentialsId: 'aws-cred',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        try {
                            sh '''
                                aws ecs wait services-stable \
                                    --cluster ${ECS_CLUSTER} \
                                    --services ${ECS_SERVICE} \
                                    --region ${AWS_REGION}
                            '''
                            echo "Service ${ECS_SERVICE} is stable."
                        } catch (Exception e) {
                            error "Service failed to stabilize: ${e}"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
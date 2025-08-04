pipeline {
    agent any

    environment {
        AWS_REGION           = 'us-east-1'
        AWS_ACCOUNT_ID       = '115456585578'
        ECR_REPOSITORY       = 'devops'
        ECR_REGISTRY         = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG            = "${BUILD_NUMBER}"
        ECS_CLUSTER          = 'my-ecs-cluster-automated-deploy'
        ECS_SERVICE          = 'my-ecs-service-automated-deploy'
        TASK_FAMILY          = 'python-app-task-automated'
        TASK_DEFINITION_NAME = "automated-deploy-task-${BUILD_NUMBER}"
        CONTAINER_NAME       = 'my-app-container'
        SUBNET_IDS           = 'subnet-01d7c4a4a6f9235e6'
        SECURITY_GROUP_IDS   = 'sg-0c57473a6ece357b0'
        TARGET_GROUP_NAME    = "flask-tg-${BUILD_NUMBER}"
        LISTENER_PORT        = '80'
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
                    dockerImage = docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}")
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    dockerImage.push()
                    dockerImage.push('latest')
                }
            }
        }

        stage('Register Task Definition') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        envsubst < task-definition-template.json > task-definition-rendered.json
                    '''

                    script {
                        def taskDefArn = sh(
                            script: '''
                                aws ecs register-task-definition \
                                    --cli-input-json file://task-definition-rendered.json \
                                    --region ${AWS_REGION} \
                                    --query 'taskDefinition.taskDefinitionArn' \
                                    --output text
                            ''',
                            returnStdout: true
                        ).trim()

                        env.TASK_DEFINITION_ARN = taskDefArn
                        echo "✅ Task Definition: ${TASK_DEFINITION_ARN}"
                    }
                }
            }
        }

        stage('Fetch VPC ID') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def vpcId = sh(
                            script: """
                                aws ec2 describe-subnets \
                                    --subnet-ids ${SUBNET_IDS.split(',')[0]} \
                                    --region ${AWS_REGION} \
                                    --query 'Subnets[0].VpcId' \
                                    --output text
                            """,
                            returnStdout: true
                        ).trim()
                        env.VPC_ID = vpcId
                    }
                }
            }
        }

        stage('Check or Create Target Group') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def tgArn = sh(
                            script: """
                                aws elbv2 describe-target-groups \
                                    --names ${TARGET_GROUP_NAME} \
                                    --region ${AWS_REGION} \
                                    --query 'TargetGroups[0].TargetGroupArn' \
                                    --output text 2>/dev/null || echo "MISSING"
                            """,
                            returnStdout: true
                        ).trim()

                        if (tgArn == "MISSING") {
                            tgArn = sh(
                                script: """
                                    aws elbv2 create-target-group \
                                        --name ${TARGET_GROUP_NAME} \
                                        --protocol HTTP \
                                        --port 5000 \
                                        --vpc-id ${VPC_ID} \
                                        --target-type ip \
                                        --region ${AWS_REGION} \
                                        --query 'TargetGroups[0].TargetGroupArn' \
                                        --output text
                                """,
                                returnStdout: true
                            ).trim()
                        }
                        env.TG_ARN = tgArn
                        echo "✅ Target Group ARN: ${TG_ARN}"
                    }
                }
            }
        }

        
        stage('Check or Create ECS Service') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        SERVICE_EXISTS=$(aws ecs describe-services \
                            --cluster ${ECS_CLUSTER} \
                            --services ${ECS_SERVICE} \
                            --region ${AWS_REGION} \
                            --query "services[?status=='ACTIVE'].serviceName" \
                            --output text)

                        if [ -z "$SERVICE_EXISTS" ]; then
                            echo "ECS service does not exist. Creating..."
                            aws ecs create-service \
                                --cluster ${ECS_CLUSTER} \
                                --service-name ${ECS_SERVICE} \
                                --task-definition ${TASK_DEFINITION_ARN} \
                                --launch-type FARGATE \
                                --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID}],securityGroups=[${SECURITY_GROUP_ID}],assignPublicIp=ENABLED}" \
                                --load-balancers "targetGroupArn=${TG_ARN},containerName=${CONTAINER_NAME},containerPort=5000" \
                                --desired-count 1 \
                                --region ${AWS_REGION}
                        else
                            echo "ECS service exists. Skipping creation."
                        fi
                    '''
                }
            }
        }


        stage('Deploy to ECS') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecs update-service \
                            --cluster ${ECS_CLUSTER} \
                            --service ${ECS_SERVICE} \
                            --task-definition ${TASK_DEFINITION_ARN} \
                            --force-new-deployment \
                            --region ${AWS_REGION}
                    '''
                }
            }
        }




        stage('Wait for ECS Service Stability') {
            steps {
                script {
                    def maxAttempts = 30
                    def delay = 20
                    for (int i = 0; i < maxAttempts; i++) {
                        def status = sh(
                            script: "aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${ECS_SERVICE} --region ${AWS_REGION} --query 'services[0].deployments'",
                            returnStdout: true
                        ).trim()

                        if (status.contains('"rolloutState": "COMPLETED"') && status.contains('"status": "PRIMARY"')) {
                            echo "✅ Service is stable"
                            break
                        } else {
                            echo "⏳ Waiting ${delay}s... (${i+1}/${maxAttempts})"
                            sleep delay
                        }
                    }
                }
            }
        }

        


        stage('Final Target Group Health Check') {
            steps {
                sh '''
                    echo "📊 Checking final target health..."
                    aws elbv2 describe-target-health \
                        --target-group-arn ${TG_ARN} \
                        --region ${AWS_REGION} \
                        --output table
                '''
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f'
        }
        success {
            echo '✅ Deployment complete.'
        }
        failure {
            echo '❌ Deployment failed. Check ECS and CloudWatch logs.'
        }
    }
}

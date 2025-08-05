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
        TASK_DEFINITION_ARN  = "automated-deploy-task-${BUILD_NUMBER}"
        CONTAINER_NAME       = 'my-app-container'
        SUBNET_IDS           = 'subnet-01d7c4a4a6f9235e6,subnet-01c1ca97fe8b13fb1'
        SECURITY_GROUP_IDS   = 'sg-0acc29bad05199bf5'
        TARGET_GROUP_NAME    = "flask-tg-${BUILD_NUMBER}"
        LOAD_BALANCER_NAME   = "automated-flask-alb-${BUILD_NUMBER}"
        TASK_DEFINITION_NAME = "automated-deploy-task-${BUILD_NUMBER}"
        LISTENER_PORT        = '80'
        CONTAINER_PORT       = '5000'
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
                        export TASK_DEFINITION_NAME="automated-deploy-task-${BUILD_NUMBER}"
                        export AWS_REGION="${AWS_REGION}"
                        export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
                        export CONTAINER_NAME="my-app-container"
                        export ECR_REGISTRY="${ECR_REGISTRY}"
                        export ECR_REPOSITORY="${ECR_REPOSITORY}"
                        export IMAGE_TAG="${IMAGE_TAG}"
                        
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

        stage('Check or Create Load Balancer') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        echo "🔍 Checking if Load Balancer exists..."
                        LB_ARN=$(aws elbv2 describe-load-balancers \
                            --names ${LOAD_BALANCER_NAME} \
                            --region ${AWS_REGION} \
                            --query 'LoadBalancers[0].LoadBalancerArn' \
                            --output text 2>/dev/null || echo "")

                        if [ -z "$LB_ARN" ] || [[ "$LB_ARN" == "None" ]]; then
                            echo "🔧 Creating Load Balancer..."
                            LB_ARN=$(aws elbv2 create-load-balancer \
                                --name ${LOAD_BALANCER_NAME} \
                                --subnets $(echo ${SUBNET_IDS} | tr ',' ' ') \
                                --security-groups ${SECURITY_GROUP_IDS} \
                                --scheme internet-facing \
                                --type application \
                                --region ${AWS_REGION} \
                                --query 'LoadBalancers[0].LoadBalancerArn' \
                                --output text)

                            echo "✅ Created ALB: $LB_ARN"
                        else
                            echo "✅ ALB already exists: $LB_ARN"
                        fi

                        echo "LB_ARN=$LB_ARN" > alb_target_info.env
                    '''
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
                                    --output text 2>/dev/null || echo ""
                            """,
                            returnStdout: true
                        ).trim()

                        if (!tgArn || tgArn == "None") {
                            tgArn = sh(
                                script: """
                                    aws elbv2 create-target-group \
                                        --name ${TARGET_GROUP_NAME} \
                                        --protocol HTTP \
                                        --port ${CONTAINER_PORT} \
                                        --target-type ip \
                                        --vpc-id ${VPC_ID} \
                                        --health-check-path / \
                                        --region ${AWS_REGION} \
                                        --query 'TargetGroups[0].TargetGroupArn' \
                                        --output text
                                """,
                                returnStdout: true
                            ).trim()
                            echo "✅ Created Target Group: ${tgArn}"
                        } else {
                            echo "✅ Target Group already exists: ${tgArn}"
                        }

                        env.TG_ARN = tgArn
                    }
                }
            }
        }

        stage('Attach Target Group to Listener') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        // Get Load Balancer ARN first (safer and reusable)
                        def loadBalancerArn = sh(
                            script: """
                                aws elbv2 describe-load-balancers \
                                    --names ${LOAD_BALANCER_NAME} \
                                    --region ${AWS_REGION} \
                                    --query 'LoadBalancers[0].LoadBalancerArn' \
                                    --output text
                            """,
                            returnStdout: true
                        ).trim()

                        // Try to get Listener ARN
                        def listenerArn = sh(
                            script: """
                                aws elbv2 describe-listeners \
                                    --load-balancer-arn "${loadBalancerArn}" \
                                    --region "${AWS_REGION}" \
                                    --query "Listeners[?Port==\\`${LISTENER_PORT}\\`].ListenerArn"  \
                                    --output text
                            """,
                            returnStdout: true
                        ).trim()

                        // Create listener if not found
                        if (!listenerArn || listenerArn == "None" || listenerArn == "") {
                            listenerArn = sh(
                                script: """
                                    aws elbv2 create-listener \
                                        --load-balancer-arn ${loadBalancerArn} \
                                        --protocol HTTP \
                                        --port ${LISTENER_PORT} \
                                        --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
                                        --region ${AWS_REGION} \
                                        --query 'Listeners[0].ListenerArn' \
                                        --output text
                                """,
                                returnStdout: true
                            ).trim()
                        } else {
                            // Modify listener if exists
                            sh """
                                aws elbv2 modify-listener \
                                    --listener-arn ${listenerArn} \
                                    --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
                                    --region ${AWS_REGION}
                            """
                        }

                        env.LISTENER_ARN = listenerArn
                        echo "✅ Listener ARN: ${env.LISTENER_ARN}"
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
                                --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_IDS}],assignPublicIp=ENABLED}" \
                                --load-balancers "targetGroupArn=${TG_ARN},containerName=${CONTAINER_NAME},containerPort=${CONTAINER_PORT}" \
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


        
        stage('Debug Target Registration') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        echo "Fetching ECS Task ARN..."
                        TASK_ARN=$(aws ecs list-tasks \
                            --cluster ${ECS_CLUSTER} \
                            --service-name ${ECS_SERVICE} \
                            --region ${AWS_REGION} \
                            --query 'taskArns[0]' \
                            --output text)

                        echo "Task ARN: $TASK_ARN"

                        echo "Fetching private IP of the ECS Task..."
                        PRIVATE_IP=$(aws ecs describe-tasks \
                            --cluster ${ECS_CLUSTER} \
                            --tasks $TASK_ARN \
                            --region ${AWS_REGION} \
                            --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' \
                            --output text)

                        echo "ECS Task IP: $PRIVATE_IP"

                        echo "Registering target to Target Group..."
                        aws elbv2 register-targets \
                            --target-group-arn ${TG_ARN} \
                            --targets Id=${PRIVATE_IP},Port=80 \
                            --region ${AWS_REGION}

                        echo "Waiting for target to register..."
                        sleep 20

                        echo "Target group health:"
                        aws elbv2 describe-target-health \
                            --target-group-arn ${TG_ARN} \
                            --region ${AWS_REGION}
                    '''
                }
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


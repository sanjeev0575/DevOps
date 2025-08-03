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
        SUBNET_IDS           = ('subnet-01d7c4a4a6f9235e6,subnet-01c1ca97fe8b13fb1')
        SECURITY_GROUP_IDS   = 'sg-0c57473a6ece357b0'
        LOAD_BALANCER_NAME   = "automated-flask-alb-${BUILD_NUMBER}"
        TARGET_GROUP_NAME    = "flask-tg-${BUILD_NUMBER}"
        LISTENER_PORT        = '5000'
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
                    script {
                        sh '''
                            envsubst < task-definition-template.json > task-definition-rendered.json
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
                    }
                }
            }
        }

        stage('Fetch VPC ID') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def firstSubnet = env.SUBNET_IDS.split(',')[0]
                        env.VPC_ID = sh(
                            script: """
                                aws ec2 describe-subnets \
                                    --subnet-ids ${firstSubnet} \
                                    --region ${AWS_REGION} \
                                    --query 'Subnets[0].VpcId' \
                                    --output text
                            """,
                            returnStdout: true
                        ).trim()
                        echo "✅ Resolved VPC ID from subnet: ${env.VPC_ID}"
                    }
                }
            }
        }

        stage('Create Load Balancer & Target Group') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh '''#!/bin/sh
                            echo "🔍 Checking if Load Balancer exists..."
                            LB_ARN=$(aws elbv2 describe-load-balancers --names ${LOAD_BALANCER_NAME} --region ${AWS_REGION} --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")

                            if [ -z "$LB_ARN" ]; then
                                echo "🔧 Creating Load Balancer..."
                                LB_ARN=$(aws elbv2 create-load-balancer \
                                    --name ${LOAD_BALANCER_NAME} \
                                    --subnets $(echo ${SUBNET_IDS} | tr ',' ' ') \
                                    --security-groups ${SECURITY_GROUP_IDS} \
                                    --scheme internet-facing \
                                    --type application \
                                    --region ${AWS_REGION} \
                                    --query 'LoadBalancers[0].LoadBalancerArn' --output text)
                            fi

                            echo "🔍 Checking if Target Group exists..."
                            TG_ARN=$(aws elbv2 describe-target-groups --names ${TARGET_GROUP_NAME} --region ${AWS_REGION} --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")

                            if [ -z "$TG_ARN" ]; then
                                echo "🔧 Creating Target Group with /health path..."
                                TG_ARN=$(aws elbv2 create-target-group \
                                    --name ${TARGET_GROUP_NAME} \
                                    --protocol HTTP \
                                    --port 5000 \
                                    --target-type ip \
                                    --vpc-id ${VPC_ID} \
                                    --region ${AWS_REGION} \
                                    --health-check-protocol HTTP \
                                    --health-check-path /health \
                                    --health-check-port traffic-port \
                                    --health-check-interval-seconds 30 \
                                    --health-check-timeout-seconds 5 \
                                    --healthy-threshold-count 2 \
                                    --unhealthy-threshold-count 2 \
                                    --query 'TargetGroups[0].TargetGroupArn' --output text)
                            fi

                            echo "🔍 Checking if Listener exists..."
                            LISTENER_ARN=$(aws elbv2 describe-listeners \
                                    --load-balancer-arn $LB_ARN \
                                    --region ${AWS_REGION} \
                                    --query 'Listeners[?Port==`'"${LISTENER_PORT}"'`].ListenerArn' \
                                    --output text 2>/dev/null || echo "")


                            if [ -z "$LISTENER_ARN" ]; then
                                aws elbv2 create-listener \
                                    --load-balancer-arn $LB_ARN \
                                    --protocol HTTP \
                                    --port ${LISTENER_PORT} \
                                    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
                                    --region ${AWS_REGION}
                            fi

                            if [ -z "$TG_ARN" ]; then
                                echo "❌ TG_ARN is empty. Cannot continue."
                                exit 1
                            fi

                            echo "TG_ARN=$TG_ARN" >> env.properties
                        '''

                        if (!fileExists('env.properties')) {
                            error("❌ env.properties file not found! Likely failure in LB or TG creation.")
                        }

                        def props = readProperties file: 'env.properties'
                        env.TG_ARN = props.TG_ARN
                        echo "✔️ TG_ARN read from env.properties: ${env.TG_ARN}"
                    }
                }
            }
        }
        stage('Check Target Group Health') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                sh '''
                echo "🔍 Listing ECS task..."
                TASK_ARN=$(aws ecs list-tasks \
                  --cluster ${ECS_CLUSTER} \
                  --service-name ${ECS_SERVICE} \
                  --region ${AWS_REGION} \
                  --query "taskArns[0]" --output text)

                echo "📦 Describing task: $TASK_ARN"
                aws ecs describe-tasks \
                    --cluster ${ECS_CLUSTER} \
                    --tasks $TASK_ARN \
                    --region ${AWS_REGION} \
                    --query "tasks[0].containers[0].lastStatus"

                echo "📦 Checking network attachment"
                    aws ecs describe-tasks \
                    --cluster ${ECS_CLUSTER} \
                    --tasks $TASK_ARN \
                    --region ${AWS_REGION} \
                    --query "tasks[0].attachments[0].details"
                    
                    aws elbv2 describe-target-health \
                        --target-group-arn ${TG_ARN} \
                        --region ${AWS_REGION} \
                        --output table
                    echo "Target Group ARN: ${TG_ARN}"
                    echo "AWS Region: ${AWS_REGION}"
                '''
                }
            }
    }
    stage('Debug ECS Task IP Registration') {
    steps {
        withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
            sh '''
                echo "🔍 Listing ECS task..."
                TASK_ARN=$(aws ecs list-tasks \
                  --cluster ${ECS_CLUSTER} \
                  --service-name ${ECS_SERVICE} \
                  --region ${AWS_REGION} \
                  --query "taskArns[0]" --output text)

                echo "📦 Describing task: $TASK_ARN"
                aws ecs describe-tasks \
                  --cluster ${ECS_CLUSTER} \
                  --tasks $TASK_ARN \
                  --region ${AWS_REGION} \
                  --query "tasks[0].containers[0].lastStatus"

                echo "📦 Checking network attachment"
                aws ecs describe-tasks \
                  --cluster ${ECS_CLUSTER} \
                  --tasks $TASK_ARN \
                  --region ${AWS_REGION} \
                  --query "tasks[0].attachments[0].details"
            '''
        }
    }
}



        stage('Check or Create ECS Service') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
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
                            echo "ECS service already exists."
                        } else {
                            echo "Creating ECS service..."
                            sh """
                                aws ecs create-service \
                                    --cluster ${ECS_CLUSTER} \
                                    --service-name ${ECS_SERVICE} \
                                    --task-definition ${TASK_DEFINITION_ARN} \
                                    --launch-type FARGATE \
                                    --network-configuration 'awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_IDS}],assignPublicIp=ENABLED}' \
                                    --load-balancers '[{"targetGroupArn":"${TG_ARN}","containerName":"${CONTAINER_NAME}","containerPort":5000}]' \
                                    --region ${AWS_REGION}
                            """
                        }
                    }
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
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def maxAttempts = 30
                        def delay = 30
                        for (int i = 0; i < maxAttempts; i++) {
                            def output = sh(
                                script: "aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${ECS_SERVICE} --region ${AWS_REGION} --query 'services[0].deployments'",
                                returnStdout: true
                            ).trim()

                            if (output.contains('"rolloutState": "COMPLETED"') && output.contains('"status": "PRIMARY"')) {
                                echo "✅ ECS service is stable."
                                break
                            } else {
                                echo "⏳ Service not stable yet. Attempt ${i + 1}/${maxAttempts}. Waiting ${delay}s..."
                                sleep delay
                            }

                            if (i == maxAttempts - 1) {
                                error("❌ ECS service did not stabilize within ${maxAttempts * delay / 60} minutes.")
                            }
                        }
                    }
                }
            }
        }

        stage('Dump ECS Service Events (if failed)') {
            when {
                expression { currentBuild.result == 'FAILURE' }
            }
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        echo "⚠️ ECS Service Events:"
                        aws ecs describe-services \
                            --cluster ${ECS_CLUSTER} \
                            --services ${ECS_SERVICE} \
                            --region ${AWS_REGION} \
                            --query 'services[0].events' \
                            --output table
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
            echo '✅ Deployment pipeline completed successfully!'
        }
        failure {
            echo '❌ Deployment failed. Check ECS events and CloudWatch logs.'
        }
    }
}







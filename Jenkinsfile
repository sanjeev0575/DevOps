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
        TASK_DEFINITION_NAME = 'automated-deploy-task'
        CONTAINER_NAME       = 'my-app-container'
        SUBNET_IDS           = 'subnet-01d7c4a4a6f9235e6,subnet-01c1ca97fe8b13fb1'
        SECURITY_GROUP_IDS   = 'sg-0644fd647017edcbf'
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
                                    --desired-count 1 \
                                    --launch-type FARGATE \
                                    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_IDS}],assignPublicIp=ENABLED}" \
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

// pipeline {
//     agent any

//     environment {
//         AWS_REGION           = 'us-east-1'
//         AWS_ACCOUNT_ID       = '115456585578'
//         ECR_REPOSITORY       = 'devops'
//         ECR_REGISTRY         = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
//         IMAGE_TAG            = "${BUILD_NUMBER}"
//         ECS_CLUSTER          = 'my-ecs-cluster-automated-deploy'
//         ECS_SERVICE          = 'my-ecs-service-automated-deploy'
//         TASK_FAMILY          = 'python-app-task-automated'
//         TASK_DEFINITION_NAME = "automated-deploy-task-${BUILD_NUMBER}"
//         CONTAINER_NAME       = 'my-app-container'
//         SUBNET_IDS           = 'subnet-01d7c4a4a6f9235e6,subnet-01c1ca97fe8b13fb1'
//         SECURITY_GROUP_IDS   = 'sg-0c57473a6ece357b0'
//         TARGET_GROUP_NAME    = "flask-tg-${BUILD_NUMBER}"
//         LOAD_BALANCER_NAME   = "automated-flask-alb-${BUILD_NUMBER}"
//         LISTENER_PORT        = '80'
//         CONTAINER_PORT       =  '5000'
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
//                     dockerImage = docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}")
//                 }
//             }
//         }

//         stage('Login to ECR') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
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

//         stage('Register Task Definition') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         envsubst < task-definition-template.json > task-definition-rendered.json
//                     '''

//                     script {
//                         def taskDefArn = sh(
//                             script: '''
//                                 aws ecs register-task-definition \
//                                     --cli-input-json file://task-definition-rendered.json \
//                                     --region ${AWS_REGION} \
//                                     --query 'taskDefinition.taskDefinitionArn' \
//                                     --output text
//                             ''',
//                             returnStdout: true
//                         ).trim()

//                         env.TASK_DEFINITION_ARN = taskDefArn
//                         echo "✅ Task Definition: ${TASK_DEFINITION_ARN}"
//                     }
//                 }
//             }
//         }

//         stage('Fetch VPC ID') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     script {
//                         def vpcId = sh(
//                             script: """
//                                 aws ec2 describe-subnets \
//                                     --subnet-ids ${SUBNET_IDS.split(',')[0]} \
//                                     --region ${AWS_REGION} \
//                                     --query 'Subnets[0].VpcId' \
//                                     --output text
//                             """,
//                             returnStdout: true
//                         ).trim()
//                         env.VPC_ID = vpcId
//                     }
//                 }
//             }
//         }

//         // stage('Check or Create Target Group') {
//         //     steps {
//         //         withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//         //             script {
//         //                 def tgArn = sh(
//         //                     script: """
//         //                         aws elbv2 describe-target-groups \
//         //                             --names ${TARGET_GROUP_NAME} \
//         //                             --region ${AWS_REGION} \
//         //                             --query 'TargetGroups[0].TargetGroupArn' \
//         //                             --output text 2>/dev/null || echo "MISSING"
//         //                     """,
//         //                     returnStdout: true
//         //                 ).trim()

//         //                 if (tgArn == "MISSING") {
//         //                     tgArn = sh(
//         //                         script: """
//         //                             aws elbv2 create-target-group \
//         //                                 --name ${TARGET_GROUP_NAME} \
//         //                                 --protocol HTTP \
//         //                                 --port 5000 \
//         //                                 --vpc-id ${VPC_ID} \
//         //                                 --target-type ip \
//         //                                 --region ${AWS_REGION} \
//         //                                 --query 'TargetGroups[0].TargetGroupArn' \
//         //                                 --output text
//         //                         """,
//         //                         returnStdout: true
//         //                     ).trim()
//         //                 }
//         //                 env.TG_ARN = tgArn
//         //                 echo "✅ Target Group ARN: ${TG_ARN}"
//         //             }
//         //         }
//         //     }
//         // }
//         stage('Check or Create Load Balancer') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                 sh '''
//                     echo "🔍 Checking if Load Balancer exists..."
//                     LB_ARN=$(aws elbv2 describe-load-balancers \
//                     --names ${LOAD_BALANCER_NAME} \
//                     --region ${AWS_REGION} \
//                     --query 'LoadBalancers[0].LoadBalancerArn' \
//                     --output text 2>/dev/null || echo "")

//                     if [ -z "$LB_ARN" ] || [[ "$LB_ARN" == "None" ]]; then
//                     echo "🔧 Creating Load Balancer..."
//                     LB_ARN=$(aws elbv2 create-load-balancer \
//                         --name ${LOAD_BALANCER_NAME} \
//                         --subnets $(echo ${SUBNET_IDS} | tr ',' ' ') \
//                         --security-groups ${SECURITY_GROUP_IDS} \
//                         --scheme internet-facing \
//                         --type application \
//                         --region ${AWS_REGION} \
//                         --query 'LoadBalancers[0].LoadBalancerArn' \
//                         --output text)

//                     echo "✅ Created ALB: $LB_ARN"
//                     else
//                     echo "✅ ALB already exists: $LB_ARN"
//                     fi

//                     echo "LB_ARN=$LB_ARN" > alb_target_info.env
//                 '''
//                 }
//             }
//         }

//         // stage('Check or Create Target Group') {
//         //     steps {
//         //         withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//         //         sh '''
//         //             echo "🔍 Checking if Target Group exists..."
//         //             TG_ARN=$(aws elbv2 describe-target-groups \
//         //             --names ${TARGET_GROUP_NAME} \
//         //             --region ${AWS_REGION} \
//         //             --query 'TargetGroups[0].TargetGroupArn' \
//         //             --output text 2>/dev/null || echo "")

//         //             if [ -z "$TG_ARN" ] || [[ "$TG_ARN" == "None" ]]; then
//         //             echo "🔧 Creating Target Group..."
//         //             TG_ARN=$(aws elbv2 create-target-group \
//         //                 --name ${TARGET_GROUP_NAME} \
//         //                 --protocol HTTP \
//         //                 --port ${CONTAINER_PORT} \
//         //                 --target-type ip \
//         //                 --vpc-id ${VPC_ID} \
//         //                 --health-check-path / \
//         //                 --region ${AWS_REGION} \
//         //                 --query 'TargetGroups[0].TargetGroupArn' \
//         //                 --output text)

//         //             echo "✅ Created Target Group: $TG_ARN"
//         //             else
//         //             echo "✅ Target Group already exists: $TG_ARN"
//         //             fi

//         //             echo "TG_ARN=$TG_ARN" > alb_target_info.env
//         //         '''
//         //         }
//         //     }
//         // }
//         stage('Check or Create Target Group') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     script {
//                         def tgArn = sh(
//                             script: """
//                                 aws elbv2 describe-target-groups \
//                                     --names ${TARGET_GROUP_NAME} \
//                                     --region ${AWS_REGION} \
//                                     --query 'TargetGroups[0].TargetGroupArn' \
//                                     --output text 2>/dev/null || echo ""
//                             """,
//                             returnStdout: true
//                         ).trim()

//                         if (!tgArn || tgArn == "None") {
//                             tgArn = sh(
//                                 script: """
//                                     aws elbv2 create-target-group \
//                                         --name ${TARGET_GROUP_NAME} \
//                                         --protocol HTTP \
//                                         --port ${CONTAINER_PORT} \
//                                         --target-type ip \
//                                         --vpc-id ${VPC_ID} \
//                                         --health-check-path / \
//                                         --region ${AWS_REGION} \
//                                         --query 'TargetGroups[0].TargetGroupArn' \
//                                         --output text
//                                 """,
//                                 returnStdout: true
//                             ).trim()
//                             echo "✅ Created Target Group: ${tgArn}"
//                         } else {
//                             echo "✅ Target Group already exists: ${tgArn}"
//                         }

//                         env.TG_ARN = tgArn
//                     }
//                 }
//             }
//         }

//         stage('Attach Target Group to Listener') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     script {
//                         def listenerArn = sh(
//                             script: """
//                                 aws elbv2 describe-listeners \
//                                     --load-balancer-arn \$(aws elbv2 describe-load-balancers \
//                                         --names \${LOAD_BALANCER_NAME} \
//                                         --region \${AWS_REGION} \
//                                         --query 'LoadBalancers[0].LoadBalancerArn' \
//                                         --output text) \
//                                     --query 'Listeners[?Port==`'"${LISTENER_PORT}"'`].ListenerArn'  \
//                                     --region \${AWS_REGION} \
//                                     --output text
//                             """,
//                             returnStdout: true
//                         ).trim()

//                         if (!listenerArn || listenerArn == "None") {
//                             error("❌ Listener not found on Load Balancer ${LOAD_BALANCER_NAME}")
//                         }

//                         env.LISTENER_ARN = listenerArn
//                         echo "✅ Listener ARN: ${LISTENER_ARN}"

//                         // Attach TG to LB Listener
//                         sh """
//                             echo '🔗 Attaching target group to listener...'
//                             aws elbv2 modify-listener \
//                                 --listener-arn ${LISTENER_ARN} \
//                                 --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
//                                 --region ${AWS_REGION}
//                         """
//                     }
//                 }
//             }
//         }


        
//         stage('Check or Create ECS Service') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         SERVICE_EXISTS=$(aws ecs describe-services \
//                             --cluster ${ECS_CLUSTER} \
//                             --services ${ECS_SERVICE} \
//                             --region ${AWS_REGION} \
//                             --query "services[?status=='ACTIVE'].serviceName" \
//                             --output text)

//                         if [ -z "$SERVICE_EXISTS" ]; then
//                             echo "ECS service does not exist. Creating..."
//                             aws ecs create-service \
//                                 --cluster ${ECS_CLUSTER} \
//                                 --service-name ${ECS_SERVICE} \
//                                 --task-definition ${TASK_DEFINITION_ARN} \
//                                 --launch-type FARGATE \
//                                 --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_IDS}],assignPublicIp=ENABLED}" \
//                                 --load-balancers "targetGroupArn=${TG_ARN},containerName=${CONTAINER_NAME},containerPort=${CONTAINER_PORT}" \
//                                 --desired-count 1 \
//                                 --region ${AWS_REGION}
//                         else
//                             echo "ECS service exists. Skipping creation."
//                         fi
//                     '''
//                 }
//             }
//         }


//         stage('Deploy to ECS') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         aws ecs update-service \
//                             --cluster ${ECS_CLUSTER} \
//                             --service ${ECS_SERVICE} \
//                             --task-definition ${TASK_DEFINITION_ARN} \
//                             --force-new-deployment \
//                             --region ${AWS_REGION}
//                     '''
//                 }
//             }
//         }




//         stage('Wait for ECS Service Stability') {
//             steps {
//                 script {
//                     def maxAttempts = 30
//                     def delay = 20
//                     for (int i = 0; i < maxAttempts; i++) {
//                         def status = sh(
//                             script: "aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${ECS_SERVICE} --region ${AWS_REGION} --query 'services[0].deployments'",
//                             returnStdout: true
//                         ).trim()

//                         if (status.contains('"rolloutState": "COMPLETED"') && status.contains('"status": "PRIMARY"')) {
//                             echo "✅ Service is stable"
//                             break
//                         } else {
//                             echo "⏳ Waiting ${delay}s... (${i+1}/${maxAttempts})"
//                             sleep delay
//                         }
//                     }
//                 }
//             }
//         }

        


//         stage('Final Target Group Health Check') {
//             steps {
//                 sh '''
//                     echo "📊 Checking final target health..."
//                     aws elbv2 describe-target-health \
//                         --target-group-arn ${TG_ARN} \
//                         --region ${AWS_REGION} \
//                         --output table
//                 '''
//             }
//         }
//     }

//     post {
//         always {
//             sh 'docker system prune -f'
//         }
//         success {
//             echo '✅ Deployment complete.'
//         }
//         failure {
//             echo '❌ Deployment failed. Check ECS and CloudWatch logs.'
//         }
//     }
// }



// pipeline {
//     agent any

//     environment {
//         AWS_REGION           = 'us-east-1'
//         AWS_ACCOUNT_ID       = '115456585578'
//         ECR_REPOSITORY       = 'devops'
//         ECR_REGISTRY         = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
//         IMAGE_TAG            = "${BUILD_NUMBER}"
//         ECS_CLUSTER          = 'my-ecs-cluster-automated-deploy'
//         ECS_SERVICE          = 'my-ecs-service-automated-deploy'
//         //TASK_FAMILY          = 'python-app-task-automated'
//         TASK_DEFINITION_ARN  = "automated-deploy-task-${BUILD_NUMBER}"
//         CONTAINER_NAME       = 'my-app-container'
//         SUBNET_IDS           = 'subnet-01d7c4a4a6f9235e6,subnet-01c1ca97fe8b13fb1'
//         SECURITY_GROUP_IDS   = 'sg-0acc29bad05199bf5'
//         TARGET_GROUP_NAME    = "flask-tg-${BUILD_NUMBER}"
//         LOAD_BALANCER_NAME   = "automated-flask-alb-${BUILD_NUMBER}"
//         TASK_DEFINITION_NAME = "automated-deploy-task-${BUILD_NUMBER}"
//         LISTENER_PORT        = '80'
//         CONTAINER_PORT       = '5000'
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
//                     dockerImage = docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}")
//                 }
//             }
//         }

//         stage('Login to ECR') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
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

//         stage('Register Task Definition') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         export TASK_DEFINITION_NAME="automated-deploy-task-${BUILD_NUMBER}"
//                         export AWS_REGION="${AWS_REGION}"
//                         export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
//                         export CONTAINER_NAME="my-app-container"
//                         export ECR_REGISTRY="${ECR_REGISTRY}"
//                         export ECR_REPOSITORY="${ECR_REPOSITORY}"
//                         export IMAGE_TAG="${IMAGE_TAG}"
                        
//                         envsubst < task-definition-template.json > task-definition-rendered.json
//                     '''

//                     script {
//                         def taskDefArn = sh(
//                             script: '''
//                                 aws ecs register-task-definition \
//                                     --cli-input-json file://task-definition-rendered.json \
//                                     --region ${AWS_REGION} \
//                                     --query 'taskDefinition.taskDefinitionArn' \
//                                     --output text
//                             ''',
//                             returnStdout: true
//                         ).trim()

//                         env.TASK_DEFINITION_ARN = taskDefArn
//                         echo "✅ Task Definition: ${TASK_DEFINITION_ARN}"
//                     }
//                 }
//             }
//         }

//         stage('Fetch VPC ID') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     script {
//                         def vpcId = sh(
//                             script: """
//                                 aws ec2 describe-subnets \
//                                     --subnet-ids ${SUBNET_IDS.split(',')[0]} \
//                                     --region ${AWS_REGION} \
//                                     --query 'Subnets[0].VpcId' \
//                                     --output text
//                             """,
//                             returnStdout: true
//                         ).trim()
//                         env.VPC_ID = vpcId
//                     }
//                 }
//             }
//         }

//         stage('Check or Create Load Balancer') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         echo "🔍 Checking if Load Balancer exists..."
//                         LB_ARN=$(aws elbv2 describe-load-balancers \
//                             --names ${LOAD_BALANCER_NAME} \
//                             --region ${AWS_REGION} \
//                             --query 'LoadBalancers[0].LoadBalancerArn' \
//                             --output text 2>/dev/null || echo "")

//                         if [ -z "$LB_ARN" ] || [[ "$LB_ARN" == "None" ]]; then
//                             echo "🔧 Creating Load Balancer..."
//                             LB_ARN=$(aws elbv2 create-load-balancer \
//                                 --name ${LOAD_BALANCER_NAME} \
//                                 --subnets $(echo ${SUBNET_IDS} | tr ',' ' ') \
//                                 --security-groups ${SECURITY_GROUP_IDS} \
//                                 --scheme internet-facing \
//                                 --type application \
//                                 --region ${AWS_REGION} \
//                                 --query 'LoadBalancers[0].LoadBalancerArn' \
//                                 --output text)

//                             echo "✅ Created ALB: $LB_ARN"
//                         else
//                             echo "✅ ALB already exists: $LB_ARN"
//                         fi

//                         echo "LB_ARN=$LB_ARN" > alb_target_info.env
//                     '''
//                 }
//             }
//         }

//         stage('Check or Create Target Group') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     script {
//                         def tgArn = sh(
//                             script: """
//                                 aws elbv2 describe-target-groups \
//                                     --names ${TARGET_GROUP_NAME} \
//                                     --region ${AWS_REGION} \
//                                     --query 'TargetGroups[0].TargetGroupArn' \
//                                     --output text 2>/dev/null || echo ""
//                             """,
//                             returnStdout: true
//                         ).trim()

//                         if (!tgArn || tgArn == "None") {
//                             tgArn = sh(
//                                 script: """
//                                     aws elbv2 create-target-group \
//                                         --name ${TARGET_GROUP_NAME} \
//                                         --protocol HTTP \
//                                         --port ${CONTAINER_PORT} \
//                                         --target-type ip \
//                                         --vpc-id ${VPC_ID} \
//                                         --health-check-path / \
//                                         --region ${AWS_REGION} \
//                                         --query 'TargetGroups[0].TargetGroupArn' \
//                                         --output text
//                                 """,
//                                 returnStdout: true
//                             ).trim()
//                             echo "✅ Created Target Group: ${tgArn}"
//                         } else {
//                             echo "✅ Target Group already exists: ${tgArn}"
//                         }

//                         env.TG_ARN = tgArn
//                     }
//                 }
//             }
//         }

//         // stage('Attach Target Group to Listener') {
//         //     steps {
//         //         withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//         //             script {
//         //                 def listenerArn = sh(
//         //                     script: '''
//         //                         aws elbv2 describe-listeners \
//         //                             --load-balancer-arn $(aws elbv2 describe-load-balancers \
//         //                                 --names ${LOAD_BALANCER_NAME} \
//         //                                 --region ${AWS_REGION} \
//         //                                 --query 'LoadBalancers[0].LoadBalancerArn' \
//         //                                 --output text) \
//         //                             --query "Listeners[?Port==\${LISTENER_PORT}].ListenerArn" \
//         //                             --region ${AWS_REGION} \
//         //                             --output text
//         //                     ''',
//         //                     returnStdout: true
//         //                 ).trim()

//         //                 if (!listenerArn || listenerArn == "None" || listenerArn == "") {
//         //                     listenerArn = sh(
//         //                         script: '''
//         //                             aws elbv2 create-listener \
//         //                                 --load-balancer-arn $(aws elbv2 describe-load-balancers \
//         //                                     --names ${LOAD_BALANCER_NAME} \
//         //                                     --region ${AWS_REGION} \
//         //                                     --query 'LoadBalancers[0].LoadBalancerArn' \
//         //                                     --output text) \
//         //                                 --protocol HTTP \
//         //                                 --port ${LISTENER_PORT} \
//         //                                 --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
//         //                                 --region ${AWS_REGION} \
//         //                                 --query 'Listeners[0].ListenerArn' \
//         //                                 --output text
//         //                         ''',
//         //                         returnStdout: true
//         //                     ).trim()
//         //                 } else {
//         //                     sh '''
//         //                         aws elbv2 modify-listener \
//         //                             --listener-arn ${listenerArn} \
//         //                             --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
//         //                             --region ${AWS_REGION}
//         //                     '''
//         //                 }

//         //                 env.LISTENER_ARN = listenerArn
//         //                 echo "✅ Listener ARN: ${LISTENER_ARN}"
//         //             }
//         //         }
//         //     }
//         // }
//         stage('Attach Target Group to Listener') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     script {
//                         // Get Load Balancer ARN first (safer and reusable)
//                         def loadBalancerArn = sh(
//                             script: """
//                                 aws elbv2 describe-load-balancers \
//                                     --names ${LOAD_BALANCER_NAME} \
//                                     --region ${AWS_REGION} \
//                                     --query 'LoadBalancers[0].LoadBalancerArn' \
//                                     --output text
//                             """,
//                             returnStdout: true
//                         ).trim()

//                         // Try to get Listener ARN
//                         def listenerArn = sh(
//                             script: """
//                                 aws elbv2 describe-listeners \
//                                     --load-balancer-arn "${loadBalancerArn}" \
//                                     --region "${AWS_REGION}" \
//                                     --query "Listeners[?Port==\\`${LISTENER_PORT}\\`].ListenerArn" \
//                                     --output text
//                             """,
//                             returnStdout: true
//                         ).trim()

//                         // Create listener if not found
//                         if (!listenerArn || listenerArn == "None" || listenerArn == "") {
//                             listenerArn = sh(
//                                 script: """
//                                     aws elbv2 create-listener \
//                                         --load-balancer-arn ${loadBalancerArn} \
//                                         --protocol HTTP \
//                                         --port ${LISTENER_PORT} \
//                                         --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
//                                         --region ${AWS_REGION} \
//                                         --query 'Listeners[0].ListenerArn' \
//                                         --output text
//                                 """,
//                                 returnStdout: true
//                             ).trim()
//                         } else {
//                             // Modify listener if exists
//                             sh """
//                                 aws elbv2 modify-listener \
//                                     --listener-arn ${listenerArn} \
//                                     --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
//                                     --region ${AWS_REGION}
//                             """
//                         }

//                         env.LISTENER_ARN = listenerArn
//                         echo "✅ Listener ARN: ${env.LISTENER_ARN}"
//                     }
//                 }
//             }
//         }

//         stage('Check or Create ECS Service') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         SERVICE_EXISTS=$(aws ecs describe-services \
//                             --cluster ${ECS_CLUSTER} \
//                             --services ${ECS_SERVICE} \
//                             --region ${AWS_REGION} \
//                             --query "services[?status=='ACTIVE'].serviceName" \
//                             --output text)

//                         if [ -z "$SERVICE_EXISTS" ]; then
//                             echo "ECS service does not exist. Creating..."
//                             aws ecs create-service \
//                                 --cluster ${ECS_CLUSTER} \
//                                 --service-name ${ECS_SERVICE} \
//                                 --task-definition ${TASK_DEFINITION_ARN} \
//                                 --launch-type FARGATE \
//                                 --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_IDS}],assignPublicIp=ENABLED}" \
//                                 --load-balancers "targetGroupArn=${TG_ARN},containerName=${CONTAINER_NAME},containerPort=${CONTAINER_PORT}" \
//                                 --desired-count 1 \
//                                 --region ${AWS_REGION}
//                         else
//                             echo "ECS service exists. Skipping creation."
//                         fi
//                     '''
//                 }
//             }
//         }

//         stage('Deploy to ECS') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         aws ecs update-service \
//                             --cluster ${ECS_CLUSTER} \
//                             --service ${ECS_SERVICE} \
//                             --task-definition ${TASK_DEFINITION_ARN} \
//                             --force-new-deployment \
//                             --region ${AWS_REGION}
//                     '''
//                 }
//             }
//         }

//         // stage('Wait for ECS Service Stability') {
//         //     steps {
//         //         withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {

//         //             script {
//         //                 def maxAttempts = 30
//         //                 def delay = 20
//         //                 for (int i = 0; i < maxAttempts; i++) {
//         //                     def status = sh(
//         //                         script: "aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${ECS_SERVICE} --region ${AWS_REGION} --query 'services[0].deployments'",
//         //                         returnStdout: true
//         //                     ).trim()

//         //                     if (status.contains('"rolloutState": "COMPLETED"') && status.contains('"status": "PRIMARY"')) {
//         //                         echo "✅ Service is stable"
//         //                         break
//         //                     } else {
//         //                         echo "⏳ Waiting ${delay}s... (${i + 1}/${maxAttempts})"
//         //                         sleep delay
//         //                     }
//         //                 }
//         //             }    
//         //         }
//         //     }
//         // }

//         // stage('Final Target Group Health Check') {
//         //     steps {
//         //         withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//         //             sh '''
//         //                 echo "📊 Checking final target health..."
//         //                 aws elbv2 describe-target-health \
//         //                     --target-group-arn ${TG_ARN} \
//         //                     --region ${AWS_REGION} \
//         //                 '''
//         //         }
//         //     }
//         // }
//         stage('Debug Target Registration') {
//             steps {
//                 withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         echo "Fetching ECS Task ARN..."
//                         TASK_ARN=$(aws ecs list-tasks \
//                             --cluster ${ECS_CLUSTER} \
//                             --service-name ${ECS_SERVICE} \
//                             --region ${AWS_REGION} \
//                             --query 'taskArns[0]' \
//                             --output text)

//                         echo "Task ARN: $TASK_ARN"

//                         echo "Fetching private IP of the ECS Task..."
//                         PRIVATE_IP=$(aws ecs describe-tasks \
//                             --cluster ${ECS_CLUSTER} \
//                             --tasks $TASK_ARN \
//                             --region ${AWS_REGION} \
//                             --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' \
//                             --output text)

//                         echo "ECS Task IP: $PRIVATE_IP"

//                         echo "Registering target to Target Group..."
//                         aws elbv2 register-targets \
//                             --target-group-arn ${TG_ARN} \
//                             --targets Id=${PRIVATE_IP},Port=80 \
//                             --region ${AWS_REGION}

//                         echo "Waiting for target to register..."
//                         sleep 20

//                         echo "Target group health:"
//                         aws elbv2 describe-target-health \
//                             --target-group-arn ${TG_ARN} \
//                             --region ${AWS_REGION}
//                     '''
//                 }
//             }
//         }
//     }

//     post {
//         always {
//             sh 'docker system prune -f'
//         }
//         success {
//             echo '✅ Deployment complete.'
//         }
//         failure {
//             echo '❌ Deployment failed. Check ECS and CloudWatch logs.'
//         }
//     }
// }

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

        stage('Login to ECR & Push') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest || true
                    '''
                }
            }
        }

        stage('Register Task Definition') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    // Render your task-definition-template.json (must exist in repo)
                    sh '''
                        export IMAGE_URI=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        envsubst < task-definition-template.json > task-definition-rendered.json
                    '''

                    script {
                        def taskDefArn = sh(
                            script: """
                                aws ecs register-task-definition \
                                    --cli-input-json file://task-definition-rendered.json \
                                    --region ${AWS_REGION} \
                                    --query 'taskDefinition.taskDefinitionArn' \
                                    --output text
                            """,
                            returnStdout: true
                        ).trim()
                        env.TASK_DEFINITION_ARN = taskDefArn
                        echo "✅ Task Definition ARN: ${env.TASK_DEFINITION_ARN}"
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
                        echo "VPC_ID=${env.VPC_ID}"
                    }
                }
            }
        }

        stage('Check or Create ECS Cluster') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        echo "Checking ECS cluster ${ECS_CLUSTER}..."
                        CLUSTER_STATUS=$(aws ecs describe-clusters \
                            --clusters ${ECS_CLUSTER} \
                            --region ${AWS_REGION} \
                            --query 'clusters[0].status' \
                            --output text 2>/dev/null || echo "MISSING")

                        if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then
                            echo "Cluster not active or missing (status=${CLUSTER_STATUS}). Creating cluster ${ECS_CLUSTER}..."
                            aws ecs create-cluster --cluster-name ${ECS_CLUSTER} --region ${AWS_REGION}
                            echo "Cluster created."
                        else
                            echo "Cluster is ACTIVE."
                        fi
                    '''
                }
            }
        }

        stage('Check or Create Load Balancer') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        LB_ARN=$(aws elbv2 describe-load-balancers --names ${LOAD_BALANCER_NAME} --region ${AWS_REGION} --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
                        if [ -z "$LB_ARN" ] || [ "$LB_ARN" = "None" ]; then
                            echo "Creating ALB ${LOAD_BALANCER_NAME}..."
                            LB_ARN=$(aws elbv2 create-load-balancer \
                                --name ${LOAD_BALANCER_NAME} \
                                --subnets $(echo ${SUBNET_IDS} | tr ',' ' ') \
                                --security-groups ${SECURITY_GROUP_IDS} \
                                --scheme internet-facing \
                                --type application \
                                --region ${AWS_REGION} \
                                --query 'LoadBalancers[0].LoadBalancerArn' \
                                --output text)
                            echo "ALB created: $LB_ARN"
                        else
                            echo "ALB exists: $LB_ARN"
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
                                aws elbv2 describe-target-groups --names ${TARGET_GROUP_NAME} --region ${AWS_REGION} --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo ""
                            """,
                            returnStdout: true
                        ).trim()

                        if (!tgArn || tgArn == "None" || tgArn == "") {
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
                            echo "✅ Target Group exists: ${tgArn}"
                        }

                        env.TG_ARN = tgArn
                        echo "TG_ARN=${env.TG_ARN}"
                    }
                }
            }
        }

        stage('Attach Target Group to Listener') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def loadBalancerArn = sh(
                            script: """
                                aws elbv2 describe-load-balancers --names ${LOAD_BALANCER_NAME} --region ${AWS_REGION} --query 'LoadBalancers[0].LoadBalancerArn' --output text
                            """,
                            returnStdout: true
                        ).trim()

                        def listenerArn = sh(
                            script: """
                                aws elbv2 describe-listeners --load-balancer-arn ${loadBalancerArn} --region ${AWS_REGION} --query "Listeners[?Port==\\`${LISTENER_PORT}\\`].ListenerArn" --output text
                            """,
                            returnStdout: true
                        ).trim()

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
                            sh """
                                aws elbv2 modify-listener \
                                    --listener-arn ${listenerArn} \
                                    --default-actions Type=forward,TargetGroupArn=${TG_ARN} \
                                    --region ${AWS_REGION}
                            """
                        }

                        env.LISTENER_ARN = listenerArn
                        echo "Listener ARN: ${env.LISTENER_ARN}"
                    }
                }
            }
        }

        stage('Check or Create ECS Service') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    // Create service if not exists
                    sh '''
                        SERVICE_EXISTS=$(aws ecs describe-services \
                            --cluster ${ECS_CLUSTER} \
                            --services ${ECS_SERVICE} \
                            --region ${AWS_REGION} \
                            --query "services[?status=='ACTIVE'].serviceName" \
                            --output text 2>/dev/null || echo "")

                        if [ -z "$SERVICE_EXISTS" ]; then
                            echo "ECS service does not exist. Creating..."
                            # proper quoting for awsvpcConfiguration
                            aws ecs create-service \
                                --cluster ${ECS_CLUSTER} \
                                --service-name ${ECS_SERVICE} \
                                --task-definition ${TASK_DEFINITION_ARN} \
                                --launch-type FARGATE \
                                --network-configuration "awsvpcConfiguration={subnets=[\\\"${SUBNET_IDS//,/\\\",\\\"}\\\"],securityGroups=[\\\"${SECURITY_GROUP_IDS}\\\"],assignPublicIp=ENABLED}" \
                                --load-balancers "targetGroupArn=${TG_ARN},containerName=${CONTAINER_NAME},containerPort=${CONTAINER_PORT}" \
                                --desired-count 1 \
                                --region ${AWS_REGION}
                            echo "Created ECS service ${ECS_SERVICE}"
                        else
                            echo "ECS service exists. Skipping creation."
                        fi
                    '''
                }
            }
        }

        stage('Deploy to ECS (Update Service)') {
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
                        TASK_ARN=$(aws ecs list-tasks --cluster ${ECS_CLUSTER} --service-name ${ECS_SERVICE} --region ${AWS_REGION} --query 'taskArns[0]' --output text)
                        echo "Task ARN: $TASK_ARN"

                        if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" = "None" ]; then
                            echo "No task found yet. Skipping manual register step."
                        else
                            PRIVATE_IP=$(aws ecs describe-tasks --cluster ${ECS_CLUSTER} --tasks $TASK_ARN --region ${AWS_REGION} --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' --output text)
                            echo "ECS Task IP: $PRIVATE_IP"

                            if [ -n "$PRIVATE_IP" ]; then
                                aws elbv2 register-targets --target-group-arn ${TG_ARN} --targets Id=${PRIVATE_IP},Port=${CONTAINER_PORT} --region ${AWS_REGION} || true
                            else
                                echo "No private IP available yet."
                            fi
                        fi

                        sleep 10
                        aws elbv2 describe-target-health --target-group-arn ${TG_ARN} --region ${AWS_REGION} || true
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
        }
        success {
            echo '✅ Deployment complete.'
        }
        failure {
            echo '❌ Deployment failed. Check ECS and CloudWatch logs.'
        }
    }
}

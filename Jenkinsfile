pipeline {

    agent any
    environment {
        CLOUDFLARE_ZONE_ID = credentials('c97d41c2-a4b7-499f-8ea8-382d7ce4097d')   // <-- globally available
    }
    parameters {
        choice(name: 'ACTION', choices: ['BUILD', 'REPLICA', 'DESTROY'], description: 'Pick what you like to do:')
        choice(name: 'GitBranch', choices: ['master', 'dev'], description: 'Pick the branch you like to clone:')
    }

    stages {

        stage('Stage 1: Git Clone') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {
                git branch: params.GitBranch,
                    url: 'https://github.com/itonix/BlogApp-ECS.git'
            }
        }

        stage('Stage 2: Create Dockerfile') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {
                writeFile file: "Blog-App/Dockerfile", text: '''# ----------- Builder Stage -----------
FROM node:25-slim AS builder
RUN apt-get update && apt-get install -y python3 g++ make && rm -rf /var/lib/apt/lists/*
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
# ----------- Final Stage -----------
FROM node:25-slim
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app ./
EXPOSE 3001
ENV NODE_ENV=production
CMD ["node", "index.js"]'''
            }
        }

        stage('Stage 3: Docker Build & Push') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {
                dir('Blog-App') {

                 withCredentials([usernamePassword(credentialsId: '314e5bd0-3275-4a92-81d7-0bb89016d12f', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
    // some block
    sh '''
       echo "$PASS" | docker login -u "$USER" --password-stdin
       docker buildx build -t tonygeorgethomas/blog_app:latest --push .
       docker rmi -f $(docker images -aq)

    '''
     
}
                }
            }
        }

        stage('Stage 4: Terraform Init') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {
                dir('infra') {
                    writeFile file: "infra/terraform.tf", text: '''
terraform {
  required_version = ">= 1.4.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.12.0"
    }

  }

  cloud {

    organization = "itonix"

    workspaces {
      name = "blogapp_ecs"
    }
  }

}

'''

                    withCredentials([string(credentialsId: '79fbf8d7-6884-4bda-aae6-f562f4b083ba', variable: 'TFC_TOKEN')]) {
                        sh '''
                            export TF_VAR_cloudflare_zone_id=$CLOUDFLARE_ZONE_ID
                            export TF_TOKEN_app_terraform_io=$TFC_TOKEN
                            terraform fmt -recursive
                            terraform init -input=false
                            terraform validate
                            
                        '''
                    }
                }
            }
        }

        stage('Stage 5: Terraform Plan') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {
                dir('infra') {
                    withCredentials([string(credentialsId: '79fbf8d7-6884-4bda-aae6-f562f4b083ba', variable: 'TFC_TOKEN')]) {
                        sh '''
                            export TF_VAR_cloudflare_zone_id=$CLOUDFLARE_ZONE_ID
                            export TF_TOKEN_app_terraform_io=$TFC_TOKEN
                            terraform plan -input=false
                        '''
                    }
                }
            }
        }

        stage('Stage 6: Terraform Apply') {
            when { expression { params.ACTION == 'BUILD' || params.ACTION == 'REPLICA' } }
            steps {
                dir('infra') {
                    script {

                        def userChoice = input(
                            id: 'approvalInput',
                            message: 'Should we continue with infra provisioning?',
                            parameters: [
                                choice(name: 'CONFIRM', choices: ['NO', 'YES'], description: 'Approve?')
                            ]
                        )

                        if (userChoice != "YES") {
                            error("User selected NO. Stopping pipeline.")
                        }

                        def containernumber = input(
                            id: 'containerCountInput',
                            message: 'Enter the number of containers to deploy:',
                            parameters: [
                                string(name: 'COUNT', defaultValue: '2', description: 'Number of containers')
                            ]
                        )

                        int containerCount = containernumber.toInteger()

                        withCredentials([string(credentialsId: '79fbf8d7-6884-4bda-aae6-f562f4b083ba', variable: 'TFC_TOKEN')]) {
                            sh """
                                export TF_VAR_cloudflare_zone_id=$CLOUDFLARE_ZONE_ID
                                export TF_TOKEN_app_terraform_io=$TFC_TOKEN
                                export TF_VAR_replica_count=${containerCount}
                                terraform apply -input=false -auto-approve
                            """
                        }
                    }
                }
            }
        }

        stage('Destroy Infra') {
            when { expression { params.ACTION == 'DESTROY' } }
            steps {
               dir('infra') {
                script {

                // Confirm destroy
                def confirmDestroy = input(
                    id: 'destroyConfirm',
                    message: 'Are you SURE you want to destroy ALL infrastructure?',
                    parameters: [
                        choice(name: 'confirm', choices: ['NO', 'YES'], description: 'Confirm destroy')
                    ]
                )

                if (confirmDestroy != "YES") {
                    error("User selected NO. Aborting destroy.")
                }

                withCredentials([string(credentialsId: '79fbf8d7-6884-4bda-aae6-f562f4b083ba', variable: 'TFC_TOKEN')]) {

                    sh """
                        export TF_TOKEN_app_terraform_io=$TFC_TOKEN
                        export TF_VAR_replica_count=0

                        # Step 1 — Gracefully scale ECS service to zero
                        terraform apply -auto-approve

                        # Step 2 — Destroy all infrastructure
                        terraform destroy -auto-approve
                    """
                }
            }
        }
    }
}


    }
}

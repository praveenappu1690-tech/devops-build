pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKERHUB_USERNAME = 'praveenappu'
        APP_HOST = '65.1.107.93'
        APP_USER = 'ec2-user'
        APP_DIR = '/opt/devops-app'
    }

    stages {
        stage('Validate') {
            steps {
                sh '''
                    set -eu
                    test -f Dockerfile
                    test -f docker-compose.yml
                    test -f build/index.html
                    test -x build.sh
                    echo "Validation passed"
                '''
            }
        }

        stage('Select Image') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        env.IMAGE_REPO = 'dev'
                    } else if (env.BRANCH_NAME == 'master') {
                        env.IMAGE_REPO = 'prod'
                    } else {
                        error("Only dev and master branches are supported")
                    }

                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE = "${env.DOCKERHUB_USERNAME}/${env.IMAGE_REPO}"
                }
            }
        }

        stage('Build Image') {
            steps {
                sh '''
                    set -eu
                    docker build --pull \
                      -t "$IMAGE:$IMAGE_TAG" \
                      -t "$IMAGE:latest" .
                '''
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_TOKEN'
                )]) {
                    sh '''
                        set +x
                        echo "$DH_TOKEN" | docker login \
                          --username "$DH_USER" --password-stdin
                        docker push "$IMAGE:$IMAGE_TAG"
                        docker push "$IMAGE:latest"
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['app-server-ssh']) {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DH_USER',
                        passwordVariable: 'DH_TOKEN'
                    )]) {
                        sh '''
                            set +x
                            mkdir -p ~/.ssh
                            chmod 700 ~/.ssh

                            ssh-keyscan -H "$APP_HOST" >> ~/.ssh/known_hosts

                            printf '%s' "$DH_TOKEN" | ssh \
                              "$APP_USER@$APP_HOST" \
                              "sudo docker login --username '$DH_USER' --password-stdin"

                            ssh "$APP_USER@$APP_HOST" \
                              "DOCKERHUB_USERNAME='$DOCKERHUB_USERNAME' \
                               IMAGE_REPO='$IMAGE_REPO' \
                               IMAGE_TAG='$IMAGE_TAG' \
                               bash '$APP_DIR/deploy.sh'"
                        '''
                    }
                }
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    set -eu
                    curl --fail --show-error --silent \
                      "http://$APP_HOST/health"
                    echo
                '''
            }
        }
    }

    post {
        success {
            echo "Build and deployment completed successfully."
        }
        failure {
            echo "Pipeline failed. Check the stage logs and Console Output."
        }
    }
}


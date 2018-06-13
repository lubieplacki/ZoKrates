#!/usr/bin/env groovy

def majorVersion
def minorVersion
def patchVersion

pipeline {
    agent any
    stages {
        stage('Init') {
            steps {
                script {
                    def gitCommitHash = sh(returnStdout: true, script: 'git rev-parse HEAD').trim().take(7)
                    currentBuild.displayName = "#${BUILD_ID}-${gitCommitHash}"

                    patchVersion = sh(returnStdout: true, script: 'cat Cargo.toml | grep version | awk \'{print $3}\' | sed -e \'s/"//g\'').trim()
                    echo "ZoKrates patch version: ${patchVersion}"
                    def (major, minor, patch) = patchVersion.tokenize( '.' )
                    minorVersion = "${major}.${minor}"
                    majorVersion = major
                    echo "ZoKrates minor version: ${minorVersion}"
                    echo "ZoKrates major version: ${majorVersion}"
                }
            }
        }
        stage('Build') {
            steps {
                withDockerContainer('kyroy/zokrates-test:1') {
                    sh 'RUSTFLAGS="-D warnings" cargo build'
                }
            }
        }

        stage('Test') {
            steps {
                withDockerContainer('kyroy/zokrates-test:1') {
                    sh 'RUSTFLAGS="-D warnings" cargo test'
                }
            }
        }

        stage('Integration Test') {
            when {
                expression { env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'develop' }
            }
            steps {
                withDockerContainer('kyroy/zokrates-test:1') {
                    sh 'RUSTFLAGS="-D warnings" cargo test -- --ignored'
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                script {
                    def dockerImage = docker.build("kyroy/zokrates")
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-kyroy') {
                        dockerImage.push(patchVersion)
                        dockerImage.push(minorVersion)
                        if (majorVersion > '0') {
                            dockerImage.push(majorVersion)
                        }
                        dockerImage.push("latest")
                    }
                }
            }
        }
    }
    post {
        always {
            // junit allowEmptyResults: true, testResults: '*test.xml'
            deleteDir()
        }
        changed {
            notifyStatusChange notificationRecipients: 'mail@kyroy.com', componentName: 'ZoKrates'
        }
    }
}

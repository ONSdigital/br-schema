#!groovy

// Global scope required for multi-stage persistence
def artServer = Artifactory.server 'art-p-01'
def buildInfo = Artifactory.newBuildInfo()
def agentMavenVersion = 'maven_3.5.4'

pipeline {
    libraries {
        lib('jenkins-pipeline-shared')
    }
    environment {
        SVC_NAME = "br-schema"
        ORG = "BR"
        LANG = "en_US.UTF-8"
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
        timeout(time: 1, unit: 'HOURS')
        ansiColor('xterm')
    }
    agent { label 'download.jenkins.slave' }
    stages {
        stage('Checkout') {
            agent { label 'download.jenkins.slave' }
            steps {
                checkout scm
                script {
                    buildInfo.name = "${SVC_NAME}"
                    buildInfo.number = "${BUILD_NUMBER}"
                    buildInfo.env.collect()
                }
                colourText("info", "BuildInfo: ${buildInfo.name}-${buildInfo.number}")
                dir('test-data') {
                    git branch: 'master', url: 'https://github.com/ONSdigital/br-test-data.git'
                }
                stash name: 'Checkout'
            }
        }

        stage('Build') {
            agent { label "build.${agentMavenVersion}" }
            steps {
                unstash name: 'Checkout'
                sh "mvn generate-resources"
                stash name: 'Generated'
            }
            post {
                success {
                    colourText("info", "Stage: ${env.STAGE_NAME} successful!")
                }
                failure {
                    colourText("warn", "Stage: ${env.STAGE_NAME} failed!")
                }
            }
        }

        stage('Validate') {
            agent { label "build.${agentMavenVersion}" }
            steps {
                unstash name: 'Generated'
                sh 'mvn xml:validate'
            }
            post {
                success {
                    colourText("info", "Stage: ${env.STAGE_NAME} successful!")
                }
                failure {
                    colourText("warn", "Stage: ${env.STAGE_NAME} failed!")
                }
            }
        }

        stage('Publish') {
            agent { label "build.${agentMavenVersion}" }
            when {
                branch "master"
                // evaluate the when condition before entering this stage's agent, if any
                beforeAgent true
            }
            steps {
                colourText("info", "Building snapshot ${env.BUILD_ID} on ${env.JENKINS_URL} from branch ${env.BRANCH_NAME}")
                unstash name: 'Generated'
                sh 'mvn package'
            }
            post {
                success {
                    colourText("info", "Stage: ${env.STAGE_NAME} successful!")
                }
                failure {
                    colourText("warn", "Stage: ${env.STAGE_NAME} failed!")
                }
            }
        }

        stage('Create Schema: Dev'){
            agent { label 'deploy.jenkins.slave' }
            when {
                branch "master"
                // evaluate the when condition before entering this stage's agent, if any
                beforeAgent true
            }
            environment{
                DEPLOY_TO = 'dev'
                USER = 'sbr-dev-ci'
                NAMESPACE = 'br_dev_db'
                DROP_TABLES = 'true'
            }
            steps {
                unstash name: 'Generated'
                createSchema()
                milestone label: 'post create-schema:dev', ordinal: 2
            }
            post {
                success {
                    colourText("info","Stage: ${env.STAGE_NAME} successful!")
                }
                failure {
                    colourText("warn","Stage: ${env.STAGE_NAME} failed!")
                }
            }
        }

        stage('Create Index: Dev'){
            agent { label 'deploy.jenkins.slave' }
            when {
                branch "master"
                // evaluate the when condition before entering this stage's agent, if any
                beforeAgent true
            }
            environment{
                DEPLOY_TO = 'dev'
                USER = 'sbr-dev-ci'
                COLLECTION= 'unit'
                INDEX_NAME = "br_dev_${COLLECTION}_index"
                DROP_INDEX = 'true'
            }
            steps {
                unstash name: 'Generated'
                createIndex()
                milestone label: 'post create-index:dev', ordinal: 3
            }
            post {
                success {
                    colourText("info","Stage: ${env.STAGE_NAME} successful!")
                }
                failure {
                    colourText("warn","Stage: ${env.STAGE_NAME} failed!")
                }
            }
        }

        stage('Populate Schema: Dev'){
            agent { label 'deploy.jenkins.slave' }
            when {
                branch "master"
                // evaluate the when condition before entering this stage's agent, if any
                beforeAgent true
            }
            environment{
                DEPLOY_TO = 'dev'
                USER = 'sbr-dev-ci'
                NAMESPACE = 'br_dev_db'
                TEST_DATA_DIR = 'test-data'
                BR_ROOT_DIR = 'br'
                HDFS_DIR = "${BR_ROOT_DIR}/hbase"
            }
            steps {
                unstash name: 'Generated'
                populateSchema()
                milestone label: 'post populate-schema:dev', ordinal: 4
            }
            post {
                success {
                    colourText("info","Stage: ${env.STAGE_NAME} successful!")
                }
                failure {
                    colourText("warn","Stage: ${env.STAGE_NAME} failed!")
                }
            }
        }
    }

    post {
        success {
            colourText("success", "All stages complete. Build was successful.")
            slackSend(
                    color: "good",
                    message: "${env.JOB_NAME} success: ${env.RUN_DISPLAY_URL}"
            )
        }
        unstable {
            colourText("warn", "Something went wrong, build finished with result ${currentResult}. This may be caused by failed tests, code violation or in some cases unexpected interrupt.")
            slackSend(
                    color: "warning",
                    message: "${env.JOB_NAME} unstable: ${env.RUN_DISPLAY_URL}"
            )
        }
        failure {
            colourText("warn", "Process failed at: ${env.NODE_STAGE}")
            slackSend(
                    color: "danger",
                    message: "${env.JOB_NAME} failed at ${env.STAGE_NAME}: ${env.RUN_DISPLAY_URL}"
            )
        }
    }
}

def createSchema() {
    echo "Deploying to $DEPLOY_TO"
    sshagent(credentials: ["br-$DEPLOY_TO-ci-ssh-key"]) {
        withCredentials([string(credentialsId: "dev-edgenode-1", variable: 'EDGE_NODE')]) {
            sh '''
                scp -q -o StrictHostKeyChecking=no src/main/resources/hbase/create_schema.sh ${USER}@${EDGE_NODE}:create_schema.sh
                echo "Successfully copied create_schema.sh to HOME directory on ${EDGE_NODE}"
                ssh -o StrictHostKeyChecking=no ${USER}@${EDGE_NODE} /bin/bash << CREATE_SCHEMA
                        chmod +x create_schema.sh
                        kinit ${USER}@ONS.STATISTICS.GOV.UK -k -t ${USER}.keytab
                        bash create_schema.sh -n ${NAMESPACE} -d ${DROP_TABLES}
CREATE_SCHEMA
            '''
        }
    }
}

def createIndex() {
    echo "Deploying to $DEPLOY_TO"
    sshagent(credentials: ["br-$DEPLOY_TO-ci-ssh-key"]) {
        withCredentials([string(credentialsId: "dev-edgenode-1", variable: 'EDGE_NODE'),
                         string(credentialsId: "dev-zookeeper-ensemble", variable: 'ZK_ENSEMBLE')]) {
            sh '''
                scp -q -o StrictHostKeyChecking=no src/main/resources/solr/create_index.sh ${USER}@${EDGE_NODE}:create_index.sh
                echo "Successfully copied create_schema.sh to HOME directory on ${EDGE_NODE}"
                scp -r -q -o StrictHostKeyChecking=no src/main/resources/solr/collection/${COLLECTION} ${USER}@${EDGE_NODE}:${COLLECTION}/
                echo "Successfully copied '${COLLECTION}' index config files to HOME directory on ${EDGE_NODE}"
                ssh -o StrictHostKeyChecking=no ${USER}@${EDGE_NODE} /bin/bash << CREATE_INDEX
                        chmod +x create_index.sh
                        kinit ${USER}@ONS.STATISTICS.GOV.UK -k -t ${USER}.keytab
                        bash create_index.sh -z ${ZK_ENSEMBLE} -n ${INDEX_NAME} -f ${COLLECTION}/config/schema.xml -d ${DROP_INDEX}
CREATE_INDEX
            '''
        }
    }
}

def populateSchema() {
            echo "Deploying to $DEPLOY_TO"
            sshagent(credentials: ["br-$DEPLOY_TO-ci-ssh-key"]) {
                withCredentials([string(credentialsId: "dev-edgenode-1", variable: 'EDGE_NODE')]) {
                    sh '''
                scp -q -o StrictHostKeyChecking=no src/main/resources/hbase/populate_schema.sh ${USER}@${EDGE_NODE}:populate_schema.sh
                echo "Successfully copied populate_schema.sh to HOME directory on ${EDGE_NODE}"
                scp -r -q -o StrictHostKeyChecking=no test-data/src/main/resources/data/ ${USER}@${EDGE_NODE}:${TEST_DATA_DIR}/
                echo "Successfully copied test data files to HOME directory on ${EDGE_NODE}"
                ssh -o StrictHostKeyChecking=no ${USER}@${EDGE_NODE} /bin/bash << POPULATE_SCHEMA
                        chmod +x populate_schema.sh
                        kinit ${USER}@ONS.STATISTICS.GOV.UK -k -t ${USER}.keytab
                        hadoop fs -mkdir ${BR_ROOT_DIR}
                        hadoop fs -mkdir ${HDFS_DIR}
                        hadoop fs -copyFromLocal -f ${TEST_DATA_DIR} ${HDFS_DIR}
                        bash populate_schema.sh ${NAMESPACE} "${HDFS_DIR}/${TEST_DATA_DIR}"
POPULATE_SCHEMA
            '''
                }
            }
}

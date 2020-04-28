pipeline {
    agent {
            label "maven"
        }
    environment {
        APPLICATION_NAME = 'testspringbootopenshift'
        GIT_REPO="https://github.com/DivakaraGitHub/testspringbootopenshift.git"
		APP_TEMPLATE_PARAMETERS = './src/main/resources/application.properties'
        GIT_BRANCH="master"
        STAGE_TAG = "promoteToQA"
        DEV_PROJECT = "fuse-on-ocp-18e9"
        STAGE_PROJECT = "stage"
        TEMPLATE_NAME = "testspringbootopenshift"
        ARTIFACT_FOLDER = "./target"
		BASE_IMAGE = "fuse7-java-openshift:1.3"
		BUILD_TAG = "latest"
		JOB_NAME = "Jenkins-Openshift-CICD"
		TAG_NAME = ""
        PORT = 8084;
    }
	tools {
        maven 'M3'
    }
    options {
        // set a timeout of 4 Minutes for this pipeline
        timeout(time: 4, unit: 'MINUTES')
        }
    stages {
      stage ('Initialize') {
            steps {
                sh '''
                    echo "PATH = ${PATH}"
                    echo "M2_HOME = ${M2_HOME}"
                '''
            }
        }
       stage("Checkout") {
             steps {      
                 git branch: "${GIT_BRANCH}", url: "${GIT_REPO}"
             }
           }
		stage("Compile") {
             steps {              
                 sh "mvn clean package -DskipTests=true"
              }
            }
		stage("Test") {
            steps {
               sh "mvn  test"
            }
        }
		stage("Create ConfigMap") {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject(env.DEV_PROJECT) {
                             openshift.apply(openshift.raw("create configmap ${APPLICATION_NAME}-cm --dry-run --from-file=${APP_TEMPLATE_PARAMETERS} --output=yaml").actions[0].out)
                        }
                    }
                }
            }
        }
		stage("Build Image") {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject(env.DEV_PROJECT) {
                            openshift.selector("bc", "$TEMPLATE_NAME").startBuild("--from-dir=${ARTIFACT_FOLDER}", "--wait=true")
                        }
                    }
                }
            }
        }
		stage('Deploy to DEV') {
			steps {
				script {
				  def dc = openshift.selector("dc/${APPLICATION_NAME}").object()

				openshift.set("triggers", "dc/${TEMPLATE_NAME}", "--from-image=${TEMPLATE_NAME}:latest", "-c ${dc.spec.template.spec.containers[0].name}", "--manual")    
    
				openshift.selector("dc", application).rollout().latest()    
				openshift.selector("dc", application).rollout().status()
				}
			}
         
        } 
    }
	
	post {
            failure {
                mail to: 'DK00600384@techmahindra.com', from: 'jenkinsopenshift@techmahindra.com',
                subject: "Jenkins Build: ${env.JOB_NAME} - Failed", 
                body: "Job Failed - \"${env.JOB_NAME}\" for build: ${env.TEMPLATE_NAME}\n\n"
            }
        }
}
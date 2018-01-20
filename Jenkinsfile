#!/usr/bin/env groovy
pipeline {
    agent any
    stages {
      stage('Build And Deploy') {
        steps {
		  sh 'ls -la'
		  sh 'chmod +x build.sh'
		  sh 'printenv'
          sh './build.sh'
        }
      }
    }
}
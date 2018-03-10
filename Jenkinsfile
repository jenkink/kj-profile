#!/usr/bin/env groovy
pipeline {
    agent any
    stages {
      stage('Build And Deploy') {
        steps {
		      sh 'chmod +x scripts/build.sh'
          sh './scripts/build.sh kj-profile'
        }
      }
    }
}
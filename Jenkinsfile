#!/usr/bin/env groovy
pipeline {
    agent{
      docker {
        image 'ubuntu'
        args '-u root:root'
      }
    }
    stages {
      stage('Deploy') {
        steps {
          sh 'build.sh'
        }
      }
    }
}
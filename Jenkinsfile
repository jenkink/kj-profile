#!/usr/bin/env groovy
pipeline {
    agent any
    stages {
      stage('Deploy') {
        steps {
          sh 'build.sh'
        }
      }
    }
}
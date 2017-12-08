#!/usr/bin/env groovy
pipeline {
    agent{
      docker {
        image 'node:8'
        args '-u root:root'
      }
    }
    stages {
      stage('npm install') {
        steps {
          sh 'npm install'
        }
      }
      stage('Deploy') {
        steps {
          sh 'node_modules/.bin/gulp'
        }
      }
    }
}
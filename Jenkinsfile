#!/usr/bin/env groovy
pipeline {
    agent any
    stages {
      stage('Build And Deploy') {
        steps {
		  sh 'ls -la'
          sh 'build.sh'
        }
      }
    }
}
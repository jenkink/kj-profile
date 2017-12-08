'use strict';

const AWS = require('aws-sdk');
const gulp = require('gulp');
const gutil = require('gulp-util');

gulp.task('checkCreds', checkAwsCreds);

/**
 * Checks for AWS credentials
 * @returns {Promise<void>}
 */
function checkAwsCreds() {
  let awsProfile = 'default';
  if (gutil.env.profile) {
    awsProfile = gutil.env.profile;
  }

  const credentials = new AWS.SharedIniFileCredentials({ profile: awsProfile, });

  if (credentials.accessKeyId) {
    AWS.config.credentials = credentials;
    gutil.log(`Using AWS Profile: ${awsProfile}`);
  } else if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
    gutil.log('Using AWS Credentials from Environment variables');
  } else {
    gutil.log(gutil.colors.red(`AWS Profile ${awsProfile} not found!`));
    gutil.log(gutil.colors.red('Please run aws configure to set up a credential profile'));
    gutil.log(gutil.colors.red('ex: aws configure --profile <profile_name>'));
    return Promise.reject(new Error());
  }
return Promise.resolve();
}
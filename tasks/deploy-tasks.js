'use strict';

const AWS = require('aws-sdk');
const fs = require('fs');
const glob = require('glob');
const gulp = require('gulp');
const gutil = require('gulp-util');
const promisify = require('es6-promisify');
const s3 = new AWS.S3();

const config = require('../config/config.json');

const globDir = promisify(glob);

gulp.task('updateProfile', copyFilesToS3);

/**
 * locates the files to copy to S3
 * @return {Promise}
 */
function copyFilesToS3() {
  const options = {
    nodir: true,
  }
  return globDir('resources/**', options)
    .catch((err) => {
      return Promise.reject(gutil.log(gutil.colors.red('Could not read the given directory.', err)));
    })
    .then((files) => {
      const numFiles = files.length;
      const uploadPromises = [];
      if (numFiles) {
        Object.keys(files).forEach((file) => {
          //we dont need the resources prefix for the structure on S3
          const upload = files[file].replace('resources/', '');
          uploadPromises.push(s3Upload(upload, 'resources/'));
        });
        return Promise.all(uploadPromises);
      }

      return Promise.resolve();
    });
}

/**
 * Utility function to upload items to s3
 * @param {String} key
 * @param {String} sourceDir
 * @return {Promise<void>}
 */
function s3Upload(key, sourceDir) {
  let Bucket = config.s3Bucket;
  const t = 5000;
  let data;
  if (!sourceDir) {
    sourceDir = '';
  }
  try {
    gutil.log(`Uploading ${sourceDir}${key} to S3...`);
    data = fs.readFileSync(`${sourceDir}${key}`);
  } catch (err) {
    gutil.log(`failed to read ${sourceDir}${key}`);
    return Promise.reject(err);
  }

  let params = {
    Bucket: Bucket,
    Key: key,
    Body: data,
    ACL: 'public-read',
  }

  //set the content type otherwise the content type will be set as an attachment by s3 and will download instead of displaying the html
  if (key.includes('html')) {
    params.ContentType = 'text/html';
  }
  if (key.includes('css')) {
    params.ContentType = 'text/css';
  }

  // let base64data = data;
  return s3.upload(params).promise()
    .catch((err) => {
      gutil.log(`${key} Failed to upload`);
      return Promise.reject(err);
    })
    .then(() => {
      // with S3 we have eventual consistency so we need to wait a few seconds for the changes to propagate
      return new Promise((resolve) => {
        setTimeout(resolve, t);
      });
    });
}

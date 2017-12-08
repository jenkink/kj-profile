'use strict';

const AWS = require('aws-sdk');
const fs = require('fs');
const gulp = require('gulp');
const gutil = require('gulp-util');
const promisify = require('es6-promisify');
const s3 = new AWS.S3();

const config = require('../config/config.json');

const readDir = promisify(fs.readdir);

gulp.task('updateProfile', copyFilesToS3);


/**
 * locates the files to copy to S3
 * @return {Promise}
 */
function copyFilesToS3() {
    return readDir('html')
      .catch((err) => {
        return Promise.reject(gutil.log(gutil.colors.red('Could not read the given directory.', err)));
      })
      .then((files) => {
        const numFiles = files.length;
  
        const uploadPromises = [];
        if (numFiles) {
          Object.keys(files).forEach((file) => {
            uploadPromises.push(s3Upload(`${files[file]}`, 'html/'));
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
    try {
      gutil.log(`Uploading ${sourceDir}${key} to S3...`);
      data = fs.readFileSync(`${sourceDir}${key}`);
    } catch (err) {
      gutil.log(`failed to read ${sourceDir}/${key}`);
      return Promise.reject(err);
    }
    
    // let base64data = data;
    return s3.upload({
      Bucket: Bucket,
      Key: key,
      Body: data,
      ACL: 'public-read',
    }).promise()
      .catch((err) => {
        gutil.log(`${key} Failed to upload`);
        return Promise.reject(err);
      })
      .then(() => {
        return new Promise((resolve) => {
            setTimeout(resolve, );
          });
      });
  }
  
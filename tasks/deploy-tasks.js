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
  const options ={
    nodir : true,
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
            if(files[file].includes('index')){
              //strip the directory so we can place index.html into the top level of the s3Bucket
              const fileSplit = files[file].split('/');
              uploadPromises.push(s3Upload(`${fileSplit[1]}`, 'resources/'));       
            }else{
            uploadPromises.push(s3Upload(`${files[file]}`));
            }
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
    let options = {
      Bucket: Bucket,
      Key: key,
      Body: data,
      ACL: 'public-read',
    }
    
    //set the content type for html files other wise the content type will be set as an attachment
    if(key.includes('html')){
      options.contentType = 'text/html';
    }

    if(!sourceDir){
       sourceDir = '';
    }
    try {
      gutil.log(`Uploading ${sourceDir}${key} to S3...`);
      data = fs.readFileSync(`${sourceDir}${key}`);
    } catch (err) {
      gutil.log(`failed to read ${sourceDir}${key}`);
      return Promise.reject(err);
    }
    
    // let base64data = data;
    return s3.upload(options).promise()
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
  
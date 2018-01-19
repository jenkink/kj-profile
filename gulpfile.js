'use strict';

const gulp = require('gulp');
const hub = require('gulp-hub');

hub(['tasks/**/*.js']);

gulp.task('default', gulp.series('db'));

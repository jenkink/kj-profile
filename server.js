'use strict';

const express = require('express');
const config = require('./config/config.json');

// Constants
const HOST = '0.0.0.0';

// App
const app = express();
app.use(express.static(__dirname + '/resources'));

app.get('/', function (req, res) {
  res.sendFile(path.resolve(__dirname + '/resources/index.html'));
});

app.listen(config.portNumber, HOST);
console.log(`Running on http://${HOST}:${config.portNumber}`);

'use strict';

const elasticsearch = require('elasticsearch');
const getIndex = require('./getIndex');

const host = process.env.ELASTIC_SEARCH_IP;
const port = process.env.ELASTIC_SEARCH_PORT;
const rawIndex = 'hubot-today';

const index = getIndex(rawIndex);
const type = 'message';
const id = process.env.HUBOT_NAME + '_log';

const client = new elasticsearch.Client({
  host: `${host}:${port}`
});

module.exports.logs = (data, cb) => {
  client.index({
    index,
    type,
    body: data
  },cb);
};

module.exports.log = (data, cb) => {
  client.index({
    index,
    type,
    id,
    body: data
  },cb);
};
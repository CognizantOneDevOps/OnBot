'use strict';

const elasticsearch = require('elasticsearch');
const getIndex = require('./getIndex');

const host = process.env.ELASTIC_SEARCH_IP;
const port = process.env.ELASTIC_SEARCH_PORT;
const rawIndex = 'hubot_wall_notification';


const index = getIndex(rawIndex);
const type = 'Notifier';

const client = new elasticsearch.Client({
  host: `${host}:${port}`
});

module.exports.log = (data, cb) => {
  client.index({
    index,
    type,
    body: data
  },cb);
};

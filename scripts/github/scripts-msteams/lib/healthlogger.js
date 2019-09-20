'use strict';

const elasticsearch = require('elasticsearch');
const getIndex = require('./getIndex');
const host = process.env.ELASTIC_SEARCH_IP;
const port = process.env.ELASTIC_SEARCH_PORT;
const rawIndex = 'hubot-monitor';

const index = getIndex(rawIndex);
const type = 'Health';
const id = 'hubot_monitor_'+ process.env.HUBOT_NAME;

const client = new elasticsearch.Client({
  host: `${host}:${port}`
});

module.exports.healthData = (data, cb) => {
  client.index({
    index,
    type,
	id,
    body: data
  },cb);
};
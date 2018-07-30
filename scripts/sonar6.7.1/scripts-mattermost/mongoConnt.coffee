#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
#   
#   Licensed under the Apache License, Version 2.0 (the "License"); you may not
#   use this file except in compliance with the License.  You may obtain a copy
#   of the License at
#   
#     http://www.apache.org/licenses/LICENSE-2.0
#   
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
#   License for the specific language governing permissions and limitations under
#   the License.
#-------------------------------------------------------------------------------

#Description:
# Generate Random ID with 4 Digits
# Insert Data into DB with Payload
#
#Configuration:
# MONGO_DB_URL
# MONGO_COLL
#
#COMMANDS:
# None
#
#Dependencies:
# "mongodb": "2.2.31"
#
#Notes:
# Invoked from every coffeescript inside scripts folder which handles hubot commands for database interactions
#
#
#Generate Random ID with 4 Digits
#Insert Data into DB with Payload
#
#Sample JSON Documents
mongo = require 'mongodb'
MongoClient = mongo.MongoClient
#MONGO_DB_URL should be set in this format: mongodb://<mongodb_host_ip>:<mongodb_port>/
url = process.env.MONGO_DB_URL
#MONGO_COLL is the name of the collection where all tickets should be stored. This collection must reside inside the database mentioned in MONGO_DB_NAME
mongocollection=process.env.MONGO_COLL + ''
counters = process.env.MONGO_COUNTER + ''
ticketIdGenerator = process.env.MONGO_TICKETIDGEN + ''
name = process.env.MONGO_DB_NAME

db=MongoClient.connect url, (err, conn) ->
	if err
		console.log 'Unable to connect . Error:', err
	else
		console.log 'Connection established to', url
		#db=conn
		db=conn.db(name)
		
		
		

module.exports =
	getNextSequence: (callback)->
		
		col = db.collection(counters)
		tckid=col.findAndModify { _id: ticketIdGenerator}, [],{ $inc: seq: 1 }, {}, (err, object) ->
			console.log('inside func')
			if err
				console.log("error: "+err)
				callback err,null
			else
				console.log object.value
				callback null,object.value.seq
	add_in_mongo: (doc1) ->
		col = db.collection(mongocollection)
		col.insert [doc1], (err, result) ->
			if err
				console.log err
			else
				console.log "updated counter"

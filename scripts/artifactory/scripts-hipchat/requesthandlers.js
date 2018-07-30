/*******************************************************************************
*Copyright 2018 Cognizant Technology Solutions
*  
*  Licensed under the Apache License, Version 2.0 (the "License"); you may not
*  use this file except in compliance with the License.  You may obtain a copy
*  of the License at
*  
*    http://www.apache.org/licenses/LICENSE-2.0
*  
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
*  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
*  License for the specific language governing permissions and limitations under
*  the License.
******************************************************************************/

/*
Description:
 Handles all requests coming from JFrogArtifactory.coffee file

Configuration:
 ARTIFACTORY_HOST
 ARTIFACTORY_USER
 ARTIFACTORY_PASSWORD

Dependencies:
 "request": "*"
 "fs": "*"
*/

var request = require("request")
var fs = require('fs')

var getrepos = function (callback) {
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/api/repositories',
		method: "GET",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD}
	}
	request.get(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else
			var reply = '*Number*\t*Repo Type*\t*Repo Key*\n'
			body = JSON.parse(body)
			if(body.hasOwnProperty('errors'))
				callback(null,body.errors[0].message)
			else{
				for(var i=0;i<body.length;i++){
					reply += (i+1) + "\t\t\t\t" + body[i].type + "\t" + body[i].key + "\n"
				}
				callback(null,reply)
			}
	})
}

var get_artifact = function (repo, artifact, callback) {
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/api/search/artifact?name='+artifact+'&repos='+repo,
		method: "GET",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD}
	}
	request.get(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else{
			body = JSON.parse(body)
			if(body.hasOwnProperty('errors'))
				callback(null,body.errors[0].message)
			else{
				if(body.results.length == 0)
					callback(null,"Artifact not found in the given repository")
				else{
					var reply = ''
					for(var i=0;i<body.results.length;i++){
						reply += '(downvote) Download ' + body.results[i].uri.split('/')[body.results[i].uri.split('/').length-1] + ' ' + process.env.ARTIFACTORY_HOST + '/artifactory/' + body.results[i].uri.substring(body.results[i].uri.indexOf(repo+'/'),body.results[i].uri.length) + '\nRemote Path: '+body.results[i].uri.substring(body.results[i].uri.indexOf(repo+'/'),body.results[i].uri.length)+'\n'
					}
					callback(null,reply)
				}
			}
		}
	})
}

var create_repo = function (repokey, repotype, callback) {
	data = JSON.parse(fs.readFileSync('./scripts/'+repotype+'.json', 'utf8'))
	data.key = repokey
	if(repotype == 'remote'){
		data.url = process.env.ARTIFACTORY_HOST+'/'+repokey
		data.username = process.env.ARTIFACTORY_USER
		data.password = process.env.ARTIFACTORY_PASSWORD
	}
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/api/repositories/'+repokey,
		method: "PUT",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD},
		body: JSON.stringify(data),
		headers: {'Content-Type': 'application/json'}
	}
	request.put(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else{
			if(body.indexOf('errors')>-1){
				body = JSON.parse(body)
				if(body.hasOwnProperty('errors'))
					callback(null,body.errors[0].message)
			}
			else{
					callback(null,body)
				}
			}
	})
}

var delete_repo = function (repokey, callback) {
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/api/repositories/'+repokey,
		method: "DELETE",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD}
	}
	request.delete(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else{
			if(body.indexOf('errors')>-1){
				body = JSON.parse(body)
				if(body.hasOwnProperty('errors'))
					callback(null,body.errors[0].message)
			}
			else{
					callback(null,body)
				}
			}
	})
}

var get_users = function (callback) {
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/api/security/users',
		method: "GET",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD}
	}
	request.get(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else{
			body = JSON.parse(body)
			if(body.hasOwnProperty('errors'))
				callback(null,body.errors[0].message)
			else{
					var reply = '*Number*\t*Realm*\t\t*Username*\n'
					for(var i=0;i<body.length;i++){
						reply += (i+1) + '\t\t\t\t' + body[i].realm + '\t' + body[i].name + '\n'
					}
					callback(null,reply)
				}
			}
	})
}

var create_user = function (username, email, callback) {
	data = JSON.parse(fs.readFileSync('./scripts/user.json', 'utf8'))
	data.user = username
	data.email = email
	data.password = 'password'
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/api/security/users/'+username,
		method: "PUT",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD},
		body: JSON.stringify(data),
		headers: {'Content-type': 'application/json'}
	}
	request.put(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else{
			if(body){
				body = JSON.parse(body)
				if(body.hasOwnProperty('errors'))
					callback(null,body.errors[0].message)
			}
			else{
					callback(null,'User '+username+' created successfully\nusername: '+username+'\npassword: password\n**It is recommended that you change your password after first login.**')
				}
			}
	})
}

var delete_user = function (username, callback) {
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/api/security/users/'+username,
		method: "DELETE",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD}
	}
	request.delete(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else{
			if(body.indexOf('errors')>-1){
				body = JSON.parse(body)
				if(body.hasOwnProperty('errors'))
					callback(null,body.errors[0].message)
			}
			else
				callback(null,body)
			}
	})
}

var upload_artifact = function (remote_path, local_path, callback) {
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/'+remote_path,
		method: "PUT",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD},
		formData: {file: fs.createReadStream(local_path)}
	}
	request.put(options, function(error, response, body){
		console.log(body)
		if(error)
			callback(error,"error")
		else{
			if(body.indexOf('errors')>-1){
				body = JSON.parse(body)
				if(body.hasOwnProperty('errors'))
					callback(null,body.errors[0].message)
			}
			else{
				console.log(body)
				body = JSON.parse(body)
				var reply = 'Artifact uploaded successfully to repo: '+body.repo+' at this path: '+body.path+'\n(downvote)'+body.downloadUri
				callback(null,reply)
			}
		}
	})
}

var delete_artifact = function (remote_path, callback) {
	options = {
		url: process.env.ARTIFACTORY_HOST+'/artifactory/'+remote_path,
		method: "DELETE",
		auth: {username: process.env.ARTIFACTORY_USER, password: process.env.ARTIFACTORY_PASSWORD}
	}
	request.delete(options, function(error, response, body){
		if(error)
			callback(error,"error")
		else{
			if(body.indexOf('errors')>-1){
				body = JSON.parse(body)
				if(body.hasOwnProperty('errors'))
					callback(null,body.errors[0].message)
			}
			else{
				var reply = 'Item: '+remote_path+' deleted successfully'
				callback(null,reply)
			}
		}
	})
}

module.exports = {
	getrepos : getrepos,
	get_artifact : get_artifact,
	create_repo : create_repo,
	delete_repo : delete_repo,
	get_users : get_users,
	create_user : create_user,
	delete_user : delete_user,
	upload_artifact : upload_artifact,
	delete_artifact : delete_artifact
}

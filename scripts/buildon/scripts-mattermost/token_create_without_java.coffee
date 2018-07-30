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

#	NEED NEDB AND REQUEST MODULE. SO USE NPM INSTALL MODULENAME --SAVE
#	STARTSBUILD COMMAND WITH ORGANIZATION AND REPOSITORY NAME WILL CHECK WEATHER YOU HAVE ALREADY TOKEN PRESENT OR NOT.
#	IF NOT THEN CREATEBUILDONTOKEN WITH USERNAME PASSWORD COMMAND WILL GENERATE THE TOKEN AND STORE IT IN USERS-BUILDON.DB FILE
#	TWO ENV VARIABLE ( HUBOT_GIT_SOFTWARE, HUBOT_GITLAB_IP ) HAVE TO BE SET.


call = require('./call_without_java.js');
index = require('./index')
derby = "./scripts/derby_data.jar"
pg=require('pg')

postgres_url = process.env.POSTGRES_LINK

gitlab_service_token = process.env.GITLAB_SERVICE_TOKEN;

botname = process.env.HUBOT_NAME

pythonservice = process.env.HUBOT_BUILDON_SERVICE;

uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length




check_string = 'stop';
result_reply = '';
undefined_value = 'undefined';
final_repo = '';
final_branch = '';
final_org = '';
module.exports = (robot) ->
  cmdstart = new RegExp('@' + process.env.HUBOT_NAME + ' startbuildon (.*)$')
  robot.listen(
   (message) ->
     return unless message.text
     message.text.match cmdstart
   (msg) ->
    check_string = 'startbuildon';
    message_in_room = msg.message.room;
    message_user_in_room = '';

    software = process.env.HUBOT_GIT_SOFTWARE
    
    ip = process.env.HUBOT_GITLAB_IP;
    org = '';
    repo = '';
    branch = '';
    console.log(ip+" "+software);
    res = '';
    res = msg.match[1].split " ", 3
    org = res[0];
    repo = res[1];
    second_time_repo = repo;
    branch = res[2];
    second_time_branch = branch;
    if org == undefined || repo == undefined || branch == undefined
      dt = "Please provide details. Like this : botname startbuildon <Organization> <Repo> <Branch>"
      msg.send dt
      setTimeout (->index.passData dt),1000
    else
      headers = 
        'Content-Type': 'application/json'
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36'
      dataString = '{"scopes":["public_repo"],"note":"sample-token"}'
      Datastore = require('../node_modules/nedb'); 
      request = require('../node_modules/request');
      scott = {'name':msg.message.user.name};#THIS NAME WILL BE THE USER SLACK NAME		msg.message.user.name
      users = new Datastore({ filename: 'users-buildon.db', autoload: true });
      users.findOne scott, (error, doc) ->
       final_token = '';
       check_token = '';
       clone_download_link = '';
     
       if doc == null
         message = msg.match[0]
         userid = msg.message.user.name
         msg.send 'You are not a registered user. Please Generate token.';
         if gitlab_service_token == undefined_value
           msg.reply 'Please register yourself : registerbuildon <git-username> <git-password> in Private';
           robot.messageRoom msg.message.user.id, "Please register yourself : registerbuildon <username> <password>";
           dt='Please register yourself : registerbuildon <git-username> <git-password> in Private'
           setTimeout (->index.passData dt),1000
         else
           msg.reply 'Please register yourself : registerbuildon <git-username> in Private';
           robot.messageRoom msg.message.user.id, "Please register yourself : registerbuildon <username>";
           dt='Please register yourself : registerbuildon <git-username> in Private'
           setTimeout (->index.passData dt),1000
         final_branch = branch;
         final_repo = repo;
         final_org = org;
         robot.respond /registerbuildon (.*)$/i, (msg) ->
           if check_string == 'stop'
             
           else if check_string == 'startbuildon'
             message_user_in_room = msg.message.user.name;
             org = final_org;
             branch = final_branch;
             repo = final_repo;
             res1 = msg.match[1].split " ", 2
             res1[0] = res1[0].toLowerCase();
             buildon_git_username_for_clone = res1[0];
             if software == 'GitLab'
               console.log('Inside gitlab else loop');
               url_link = 'http://'.concat(ip);
               url_link = url_link.concat('/api/v4/session?login=');
               url_link = url_link.concat(res1[0]);
               url_link = url_link.concat('&password=');
               url_link = url_link.concat(res1[1]);
               console.log(url_link);
               options =
                 url: url_link
                 method: 'POST'
             else
               options =
                 url: 'https://api.github.com/authorizations'
                 method: 'POST'
                 headers: headers
                 body: dataString
                 auth:
                   'user': res1[0]
                   'pass': res1[1]
             final_name = res1[0];
             callback = (error, response, body) ->
               
               json_obj = JSON.parse(body)
               console.log(json_obj+" "+json_obj.private_token+" "+software+" "+error+" "+response);
               if software == 'GitLab'
                 console.log('check true**************');
                 if gitlab_service_token == undefined_value
                   gitlab_clone = 'http://gitlab-ci-token'.concat(':').concat(json_obj.private_token).concat('@').concat(ip).concat('/').concat(org).concat('/').concat(repo).concat('.git');
                 scott = {'username':res1[0], 'name':msg.message.user.name, 'token':json_obj.private_token};
                 check_token = json_obj.private_token;
                 clone_download_link = gitlab_clone;
               else
                 console.log('check true');
                 github_clone = 'http://'.concat(res1[0]).concat(':').concat(json_obj.token).concat('@').concat('github.com').concat('/').concat(org).concat('/').concat(repo).concat('.git');
                 clone_download_link = github_clone;
                 scott = {'username':res1[0], 'name':msg.message.user.name, 'token':json_obj.token};
                 check_token = json_obj.token;
               if check_token != undefined
                 final_token = check_token;
                 users.insert scott, (error, doc) ->
                   rep = 'Inserted in userdb. Token --> '.concat(json_obj.token);
                   dt="You are registerted in Bot successfully"
                   msg.reply dt
                   setTimeout (->index.passData dt),1000
               else
                 msg.reply 'Something went wrong with token. It is present in Git but not in DB.'
                 dt='Something went wrong with token. It is present in Git but not in DB.'
                 setTimeout (->index.passData dt),1000
                 final_token = null;
               if final_token != null
                 @exec = require('child_process').exec;
                 folder_name_in_container = uniqueId(3);
                 cmd = " git config --global http.sslVerify false && mkdir /tmp/"+folder_name_in_container+" && cd /tmp/"+folder_name_in_container+" && git clone -b "+branch+" "+clone_download_link;
                 @exec cmd, (error, stdout, stderr) ->
                   if error
                     dt='Something went wrong.'
                     msg.reply dt;
                     setTimeout (->index.passData dt),1000
                   else
                     msg.reply stdout;
                     setTimeout (->index.passData stdout),1000
                 run = () ->
                   call.callname final_name, repo, branch, pythonservice, clone_download_link, folder_name_in_container, (error, stdout, stderr) ->
                     if error == null
                       console.log('Going right way................................');
                       small_commitid = stdout.substr(0, 7)
                       dt = 'Build started for this commit-id: '.concat(small_commitid);
                       msg.reply dt
                       setTimeout (->index.passData dt),1000
                       message_sent_room = 'Build started for this commit-id: '.concat(stdout)
                       robot.messageRoom(message_in_room, message_sent_room);
                       index.passData message_sent_room
                       actionmsg = 'Build started in buildon'
                       commitid_status = stdout
                       
                       statusmsg = 'Success'
                       index.wallData botname, message, actionmsg, statusmsg
                     else
                       msg.reply stdout;
                       setTimeout (->index.passData stdout),1000
                 setTimeout(run, 5000);
               return
             if gitlab_service_token == undefined_value
               request options, callback
             else
               #IF WE HAVE SERVICE TOKEN THEN FOLLOW THIS METHOD.***********************************************************************************************************************************************************
               gitlab_clone = 'http://oauth2'.concat(':').concat(gitlab_service_token).concat('@').concat(ip).concat('/').concat(org).concat('/').concat(repo).concat('.git');
               clone_download_link = gitlab_clone;
               scott = {'username':res1[0], 'name':msg.message.user.name};
               users.insert scott, (error, doc) ->
                 dt="You are registerted in Bot successfully"
                 msg.reply dt;
                 setTimeout (->index.passData dt),1000
               @exec = require('child_process').exec;
               folder_name_in_container = uniqueId(3);
               cmd = " git config --global http.sslVerify false && mkdir /tmp/"+folder_name_in_container+" && cd /tmp/"+folder_name_in_container+" && git clone -b "+branch+" "+clone_download_link;
               @exec cmd, (error, stdout, stderr) ->
                 if error
                   dt='Something went wrong.'
                   msg.reply dt;
                   setTimeout (->index.passData dt),1000
                 else
                   msg.reply stdout;
                   setTimeout (->index.passData stdout),1000
               run = () ->
                 call.callname final_name, repo, branch, pythonservice, clone_download_link, folder_name_in_container, (error, stdout, stderr) ->
                   if error == null
                     small_commitid = stdout.substr(0, 7);
                     dt = 'Build started for this commit-id: '.concat(small_commitid);
                     msg.reply dt;
                     setTimeout (->index.passData dt),1000
                     message_sent_room = 'Build started '.concat(message_user_in_room);
                     robot.messageRoom(message_in_room, message_sent_room);
                     actionmsg = 'Build started for this commit-id: '.concat(stdout)
                     commitid_status = stdout
                     statusmsg = 'Success'
                   else
                     msg.reply stdout;
                     setTimeout (->index.passData stdout),1000
               setTimeout(run, 5000);
             check_string = 'stop';
       else#*************************************************************** IF WE ALREADY HAVE DOCUMENT IN DATABASE******************************
        pyservice_url = ''
        repo = second_time_repo;
        branch = second_time_branch;
        message_user_in_room = msg.message.user.name;
        message_in_room = msg.message.room;
        message = 'Start Build-on'
        download_name = doc.username;
        dt='Proceeding with username : '.concat(doc.username)
        msg.reply dt;
        setTimeout (->index.passData dt),1000
        final_name = doc.username;
        if software == 'GitLab'
          if gitlab_service_token == undefined_value#***********************************************WHEN WE DO NOT HAVE THE GITLAB SERVICE TOKEN ENV VARIABLE**********************************
            final_token = doc.token;
            gitlab_clone = 'http://gitlab-ci-token'.concat(':').concat(final_token).concat('@').concat(ip).concat('/').concat(org).concat('/').concat(repo).concat('.git');
          else
            gitlab_clone = 'http://oauth2'.concat(':').concat(gitlab_service_token).concat('@').concat(ip).concat('/').concat(org).concat('/').concat(repo).concat('.git');
            pyservice_url = 'http://'+ip+'/'+org+'/'+repo
          clone_download_link = gitlab_clone;
        else
          final_token = doc.token;
          github_clone = 'http://'.concat(download_name).concat(':').concat(final_token).concat('@').concat('github.com').concat('/').concat(org).concat('/').concat(repo).concat('.git');
          clone_download_link = github_clone;
        @exec = require('child_process').exec;
        folder_name_in_container = uniqueId(3);
        cmd = " git config --global http.sslVerify false && mkdir /tmp/"+folder_name_in_container+" && cd /tmp/"+folder_name_in_container+" && git clone -b "+branch+" "+clone_download_link;
        @exec cmd, (error, stdout, stderr) ->
          if error
            dt='Something went wrong.'
            msg.reply dt;
            setTimeout (->index.passData dt),1000
          else
            msg.reply stdout;
            setTimeout (->index.passData stdout),1000
        run = () ->
          call.callname final_name, repo, branch, pythonservice, pyservice_url, folder_name_in_container, (error, stdout, stderr) ->
            if error == null
              dt='Build started '.concat(message_user_in_room)
              msg.reply dt;
              setTimeout (->index.passData dt),1000
              small_commitid = stdout.substr(0, 7)
              robot.messageRoom msg.message.user.id, 'Build started for this commit-id: '.concat(small_commitid);
              dt='Build started for this commit-id: '.concat(small_commitid)
              index.passData dt
              actionmsg = 'Build started for this commit-id: '.concat(stdout)
              statusmsg = 'Success'
              commitid_status = stdout
            else
              msg.reply stdout;
              setTimeout (->index.passData stdout),1000
        setTimeout(run, 5000);
        check_string = 'stop';
    checkstat = (id,commitid) ->
            i=0
            rs = ''
            rows = []
            tmp=''
            pgClient = new (pg.Client)(postgres_url)
            pgClient.connect()
            qu = "select status from buildon_reports rep1 where commitid='"+commitid+"' and TRIGGER_FROM='BOT' order by start_timestamp desc"
            query = pgClient.query(qu)
            query.on "end", (result) ->
                tmp=result.rows
                console.log(tmp)
                for i in [0...tmp.length]
                    rows.push(tmp[i].status)
                    if(rows[i]=='FAILURE')
                        rs = "FAILED"
                console.log(!!rows.reduce (fs, nx) -> if fs == nx then fs else NaN)
                if(!!rows.reduce (fs, nx) -> if fs == nx then fs else NaN)
                    if(rows[0]=='NOTSTARTED')
                        rs = "INITIATED"
                    else
                        rs = rows[0]
                else if(rows.indexOf('NOTSTARTED')>-1)
                    if(rs == '')
                        rs = "INPROGRESS"
                else
                    rs = rows[rows.length-1]
                #sending the status to user in chatroom
                robot.messageRoom id,rs
                rows=[]
                return rs
  )

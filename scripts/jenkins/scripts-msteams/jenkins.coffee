# Description:
#   Interact with your Jenkins CI server
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JENKINS_URL
#   HUBOT_JENKINS_USER
#   HUBOT_JENKINS_PASSWORD
#
#
# Commands:
#   hubot jenkins b <jobNumber> - builds the job specified by jobNumber. List jobs to get number.
#   hubot jenkins build <job> - builds the specified Jenkins job
#   hubot jenkins build <job>, <params> - builds the specified Jenkins job with parameters as key=value&key2=value2
#   hubot jenkins list <filter> - lists Jenkins jobs
#   hubot jenkins describe <job> - Describes the specified Jenkins job
#   hubot jenkins last <job> - Details about the last build for the specified Jenkins job

#
# Author:
#   dougcole

readjson = require './readjson.js'
finaljson=" ";
eindex = require('./index')
one = require('./index')

botname = process.env.HUBOT_NAME

querystring = require 'querystring'

# Holds a list of jobs, so we can trigger them with a number
# instead of the job's name. Gets populated on when calling
# list.
jobList = []

jenkinsBuildById = (msg) ->
  # Switch the index with the job name
  job = jobList[parseInt(msg.match[1]) - 1]

  if job
    msg.match[1] = job
    jenkinsBuild(msg)
  else
    dt = "I couldn't find that job. Try `jenkins list` to get a list."
    eindex.passData dt
    msg.reply dt

jenkinsBuild = (msg, buildWithEmptyParameters) ->
    message = "jenkins build "
    actionmsg = "Jenkins build started"
    statusmsg = ""
    url = process.env.HUBOT_JENKINS_URL
    job = querystring.escape msg.match[1]
    params = msg.match[3]
    command = if buildWithEmptyParameters then "buildWithParameters" else "build"
    path = if params then "#{url}/job/#{job}/buildWithParameters?#{params}" else "#{url}/job/#{job}/#{command}"

    req = msg.http(path)

#    if process.env.HUBOT_JENKINS_AUTH
    if process.env.HUBOT_JENKINS_USER && process.env.HUBOT_JENKINS_PASSWORD
#      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      auth = new Buffer(process.env.HUBOT_JENKINS_USER + ':' + process.env.HUBOT_JENKINS_PASSWORD).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.post() (err, res, body) ->
        if err
          dt = "Jenkins says: #{err}"
          eindex.passData dt
          msg.reply dt
        else if 200 <= res.statusCode < 400 # Or, not an error code.
          dt = "(#{res.statusCode}) Build started for #{job} #{url}/job/#{job}"
          actionmsg = "(#{res.statusCode}) Build started for #{job} #{url}/job/#{job}"
          one.one botname, message, actionmsg, statusmsg
          eindex.passData dt
          msg.reply dt
        else if 400 == res.statusCode
          jenkinsBuild(msg, true)
        else if 404 == res.statusCode
          dt = "Build not found, double check that it exists and is spelt correctly."
          eindex.passData dt
          msg.reply dt
        else
          dt = "Jenkins says: Status #{res.statusCode} #{body}"
          eindex.passData dt
          msg.reply dt

jenkinsDescribe = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    job = msg.match[1]

    path = "#{url}/job/#{job}/api/json"

    req = msg.http(path)

#    if process.env.HUBOT_JENKINS_AUTH
    if process.env.HUBOT_JENKINS_USER && process.env.HUBOT_JENKINS_PASSWORD
#      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      auth = new Buffer(process.env.HUBOT_JENKINS_USER + ':' + process.env.HUBOT_JENKINS_PASSWORD).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.get() (err, res, body) ->
        if err
          dt = "Jenkins says: #{err}"
          eindex.passData dt
          msg.send dt
        else
          response = ""
          try
            content = JSON.parse(body)
            response += "JOBNAME: #{content.displayName}\n"
            response += "URL: #{content.url}\n"

            if content.description
              response += "DESCRIPTION: #{content.description}\n"

            response += "ENABLED: #{content.buildable}\n"
            response += "STATUS: #{content.color}\n"

            tmpReport = ""
            if content.healthReport.length > 0
              for report in content.healthReport
                tmpReport += " #{report.description}"
            else
              tmpReport = " unknown"
            response += "HEALTH: #{tmpReport}\n"

            parameters = ""
            for item in content.actions
              if item.parameterDefinitions
                for param in item.parameterDefinitions
                  tmpDescription = if param.description then " - #{param.description} " else ""
                  tmpDefault = if param.defaultParameterValue then " (default=#{param.defaultParameterValue.value})" else ""
                  parameters += "\n  #{param.name}#{tmpDescription}#{tmpDefault}"

            if parameters != ""
              response += "PARAMETERS: #{parameters}\n"

            eindex.passData response
            msg.send response

            if not content.lastBuild
              return

            path = "#{url}/job/#{job}/#{content.lastBuild.number}/api/json"
            req = msg.http(path)
#            if process.env.HUBOT_JENKINS_AUTH
            if process.env.HUBOT_JENKINS_USER && process.env.HUBOT_JENKINS_PASSWORD
#              auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
              auth = new Buffer(process.env.HUBOT_JENKINS_USER + ':' + process.env.HUBOT_JENKINS_PASSWORD).toString('base64')
              req.headers Authorization: "Basic #{auth}"

            req.header('Content-Length', 0)
            req.get() (err, res, body) ->
                if err
                  dt = "Jenkins says: #{err}"
                  eindex.passData dt
                  msg.send dt
                else
                  response = ""
                  try
                    content = JSON.parse(body)
                    console.log(JSON.stringify(content, null, 4))
                    jobstatus = content.result || 'PENDING'
                    jobdate = new Date(content.timestamp);
                    response += "LAST BUILD: #{jobstatus}, #{jobdate}\n"

                    eindex.passData response
                    msg.send response
                  catch error
                    eindex.passData error
                    msg.send error

          catch error
            eindex.passData error
            msg.send error

jenkinsLast = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    job = msg.match[1]

    path = "#{url}/job/#{job}/lastBuild/api/json"

    req = msg.http(path)

#    if process.env.HUBOT_JENKINS_AUTH
    if process.env.HUBOT_JENKINS_USER && process.env.HUBOT_JENKINS_PASSWORD
#      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      auth = new Buffer(process.env.HUBOT_JENKINS_USER + ':' + process.env.HUBOT_JENKINS_PASSWORD).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.get() (err, res, body) ->
        if err
          dt = "Jenkins says: #{err}"
          eindex.passData dt
          msg.send dt
        else
          response = ""
          try
            content = JSON.parse(body)
            response += "NAME: #{content.fullDisplayName}\n"
            response += "URL: #{content.url}\n"

            if content.description
              response += "DESCRIPTION: #{content.description}\n"

            response += "BUILDING: #{content.building}\n"

            eindex.passData response
            msg.send response
jenkinsList = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    filter = new RegExp(msg.match[2], 'i')
    req = msg.http("#{url}/api/json")

#    if process.env.HUBOT_JENKINS_AUTH
    if process.env.HUBOT_JENKINS_USER && process.env.HUBOT_JENKINS_PASSWORD
#      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      auth = new Buffer(process.env.HUBOT_JENKINS_USER + ':' + process.env.HUBOT_JENKINS_PASSWORD).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.get() (err, res, body) ->
        response = ""
        if err
          dt = "Jenkins says: #{err}"
          eindex.passData dt
          msg.send dt
        else
          response = "*No.*\t*Build Status*\t\t*Job Name*\n"
          try
            content = JSON.parse(body)
            for job in content.jobs
              # Add the job to the jobList
              index = jobList.indexOf(job.name)
              if index == -1
                jobList.push(job.name)
                index = jobList.indexOf(job.name)

              state = if job.color == "red"
                        "FAIL"
                      else if job.color == "aborted"
                        "ABORTED"
                      else if job.color == "aborted_anime"
                        "CURRENTLY RUNNING"
                      else if job.color == "red_anime"
                        "CURRENTLY RUNNING"
                      else if job.color == "blue_anime"
                        "CURRENTLY RUNNING"
                      else "PASS"

              if (filter.test job.name) or (filter.test state)
                response += "#{index + 1}\t\t\t#{state}\t\t\t#{job.name}\n"
            eindex.passData response
            msg.send response
          catch error
            eindex.passData error
            msg.send error

module.exports = (robot) ->
  ###robot.respond /j(?:enkins)? build ([\w\.\-_ ]+)(, (.+))?/i, (msg) ->
     jenkinsBuild(msg, false)###

  robot.respond /j(?:enkins)? b (\d+)/i, (msg) ->
    jenkinsBuildById(msg)

  robot.respond /j(?:enkins)? list( (.+))?/i, (msg) ->
    jenkinsList(msg)

  robot.respond /j(?:enkins)? describe (.*)/i, (msg) ->
    jenkinsDescribe(msg)

  robot.respond /j(?:enkins)? last (.*)/i, (msg) ->
    jenkinsLast(msg)

  robot.jenkins = {
    list: jenkinsList,
    build: jenkinsBuild
    describe: jenkinsDescribe
    last: jenkinsLast
  }

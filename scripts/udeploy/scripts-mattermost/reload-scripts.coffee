#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

# Description:
#   Allows Hubot to (re)load scripts without restart
#
# Commands:
#   hubot reload - Reloads scripts without restart. Loads new scripts too. (a fork version that works perfectly)
#
# Author:
#   spajus
#   vinta
#   m-seldin

index = require('./index')
Fs       = require 'fs'
Path     = require 'path'

oldCommands = null# Description:
#   Allows Hubot to (re)load scripts without restart
#
# Commands:
#   hubot reload - Reloads scripts without restart. Loads new scripts too. (a fork version that works perfectly)
#
# Author:
#   spajus
#   vinta
#   m-seldin

index = require('./index')
Fs       = require 'fs'
Path     = require 'path'

oldCommands = null
oldListeners = null

module.exports = (robot) ->
  cmd_reload=new RegExp('@' + process.env.HUBOT_NAME + ' reload')
  robot.hear cmd_reload, id:'reload-scripts.reload',  (msg) ->
    try
      oldCommands = robot.commands
      oldListeners = robot.listeners

      robot.commands = []
      robot.listeners = []

      reloadAllScripts msg, success, (err) ->
        msg.send err
    catch error
      console.log "Hubot reloader:", error
      dt = "Could not reload all scripts: #{error}"
      index.passData dt
      msg.send dt

  success = (msg) ->
    # Cleanup old listeners and help
    for listener in oldListeners
      listener = {}
    oldListeners = null
    oldCommands = null
    dt = "Reloaded all scripts"
    index.passData dt
    msg.send dt


  walkSync = (dir, filelist) ->
    #walk through given directory and collect files
    files = Fs.readdirSync(dir)
    filelist = filelist || []
    for file in files
      fullPath = Path.join(dir,file)
      robot.logger.debug "Scanning file : #{fullPath}"

      if (Fs.statSync(fullPath).isDirectory())
        filelist = walkSync(fullPath, filelist)
      else
        #add full path file to returning collection
        filelist.push(fullPath)
    return filelist

  # ref: https://github.com/srobroek/hubot/blob/e543dff46fba9e435a352e6debe5cf210e40f860/src/robot.coffee
  deleteScriptCache = (scriptsBaseDir) ->
    if Fs.existsSync(scriptsBaseDir)
      fileList = walkSync scriptsBaseDir

      for file in fileList.sort()
        robot.logger.debug "file: #{file}"
        if require.cache[require.resolve(file)]
          try
            cacheobj = require.resolve(file)
            delete require.cache[cacheobj]
          catch error
    robot.logger.debug "Finished deleting script cache!"

  reloadAllScripts = (msg, success, error) ->
    robot = msg.robot
    robot.emit('reload_scripts')

    robot.logger.debug "Deleting script cache..."

    scriptsPath = Path.resolve ".", "scripts"
    deleteScriptCache scriptsPath
    robot.load scriptsPath

    scriptsPath = Path.resolve ".", "src", "scripts"
    deleteScriptCache scriptsPath
    robot.load scriptsPath

    robot.logger.debug "Loading hubot scripts..."

    hubotScripts = Path.resolve ".", "hubot-scripts.json"
    Fs.exists hubotScripts, (exists) ->
      if exists
        Fs.readFile hubotScripts, (err, data) ->
          if data.length > 0
            try
              scripts = JSON.parse data
              scriptsPath = Path.resolve "node_modules", "hubot-scripts", "src", "scripts"
              robot.loadHubotScripts scriptsPath, scripts
            catch err
              error "Error parsing JSON data from hubot-scripts.json: #{err}"
              return

    robot.logger.debug "Loading hubot external scripts..."

    robot.logger.debug "Deleting cache for apppulsemobile"
    deleteScriptCache Path.resolve ".","node_modules","hubot-apppulsemobile","src"

    externalScripts = Path.resolve ".", "external-scripts.json"
    Fs.exists externalScripts, (exists) ->
      if exists
        Fs.readFile externalScripts, (err, data) ->
          if data.length > 0
            try
              robot.logger.debug "DATA : #{data}"
              scripts = JSON.parse data

              if scripts instanceof Array
                for pkg in scripts
                  scriptPath = Path.resolve ".","node_modules",pkg,"src"
                  robot.logger.debug "Deleting cache for #{pkg}"
                  robot.logger.debug "Path : #{scripts}"
                  deleteScriptCache scriptPath
            catch err
              error "Error parsing JSON data from external-scripts.json: #{err}"
            robot.loadExternalScripts scripts
            return
    robot.logger.debug "step 5"

    success(msg)

oldListeners = null

module.exports = (robot) ->

  robot.respond /reload/i, id:'reload-scripts.reload',  (msg) ->
    try
      oldCommands = robot.commands
      oldListeners = robot.listeners

      robot.commands = []
      robot.listeners = []

      reloadAllScripts msg, success, (err) ->
        msg.send err
    catch error
      dt = "Could not reload all scripts: #{error}"
      setTimeout ( ->index.passData dt),1000
      msg.send dt

  success = (msg) ->
    # Cleanup old listeners and help
    for listener in oldListeners
      listener = {}
    oldListeners = null
    oldCommands = null
    dt = "Reloaded all scripts"
    setTimeout ( ->index.passData dt),1000
    msg.send dt


  walkSync = (dir, filelist) ->
    #walk through given directory and collect files
    files = Fs.readdirSync(dir)
    filelist = filelist || []
    for file in files
      fullPath = Path.join(dir,file)
      robot.logger.debug "Scanning file : #{fullPath}"

      if (Fs.statSync(fullPath).isDirectory())
        filelist = walkSync(fullPath, filelist)
      else
        #add full path file to returning collection
        filelist.push(fullPath)
    return filelist

  # ref: https://github.com/srobroek/hubot/blob/e543dff46fba9e435a352e6debe5cf210e40f860/src/robot.coffee
  deleteScriptCache = (scriptsBaseDir) ->
    if Fs.existsSync(scriptsBaseDir)
      fileList = walkSync scriptsBaseDir

      for file in fileList.sort()
        robot.logger.debug "file: #{file}"
        if require.cache[require.resolve(file)]
          try
            cacheobj = require.resolve(file)
            delete require.cache[cacheobj]
          catch error
    robot.logger.debug "Finished deleting script cache!"

  reloadAllScripts = (msg, success, error) ->
    robot = msg.robot
    robot.emit('reload_scripts')

    robot.logger.debug "Deleting script cache..."

    scriptsPath = Path.resolve ".", "scripts"
    deleteScriptCache scriptsPath
    robot.load scriptsPath

    scriptsPath = Path.resolve ".", "src", "scripts"
    deleteScriptCache scriptsPath
    robot.load scriptsPath

    robot.logger.debug "Loading hubot scripts..."

    hubotScripts = Path.resolve ".", "hubot-scripts.json"
    Fs.exists hubotScripts, (exists) ->
      if exists
        Fs.readFile hubotScripts, (err, data) ->
          if data.length > 0
            try
              scripts = JSON.parse data
              scriptsPath = Path.resolve "node_modules", "hubot-scripts", "src", "scripts"
              robot.loadHubotScripts scriptsPath, scripts
            catch err
              error "Error parsing JSON data from hubot-scripts.json: #{err}"
              return

    robot.logger.debug "Loading hubot external scripts..."

    robot.logger.debug "Deleting cache for apppulsemobile"
    deleteScriptCache Path.resolve ".","node_modules","hubot-apppulsemobile","src"

    externalScripts = Path.resolve ".", "external-scripts.json"
    Fs.exists externalScripts, (exists) ->
      if exists
        Fs.readFile externalScripts, (err, data) ->
          if data.length > 0
            try
              robot.logger.debug "DATA : #{data}"
              scripts = JSON.parse data

              if scripts instanceof Array
                for pkg in scripts
                  scriptPath = Path.resolve ".","node_modules",pkg,"src"
                  robot.logger.debug "Deleting cache for #{pkg}"
                  robot.logger.debug "Path : #{scripts}"
                  deleteScriptCache scriptPath
            catch err
              error "Error parsing JSON data from external-scripts.json: #{err}"
            robot.loadExternalScripts scripts
            return
    robot.logger.debug "step 5"

    success(msg)

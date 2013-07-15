fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'

# ANSI Terminal Colors
bold  = '\x1B[0;1m'
red   = '\x1B[0;31m'
green = '\x1B[0;32m'
reset = '\x1B[0m'

DEPLOY_URL = process.env.PARTY_URL

log = (message, color = reset, explanation) ->
	console.log color + message + reset + ' ' + (explanation or '')

task "party", ->
	deploy log("* Starting the party ...", green)

task "wipe", ->
	deploy true, log("* Restarting the party ...", red)

task "docs", ->
	command = "docco *.coffee client/*.coffee server/*.coffee -o public/docs"
	docco = exec command, (error, stdout, stderr) ->
		throw error if error
		log "* Generated docs", green
	docco.stdout.on "data", (data) -> print data.toString()

deploy = (reset = false, callback) ->
	if typeof reset is "function"
		callback = reset
		reset = false

	if reset
		command = "meteor deploy --delete #{DEPLOY_URL}"
	else
		command = "meteor deploy #{DEPLOY_URL}"

	meteor = exec command, (error, stdout, stderr) ->
		# If we're resetting, run the same procedure again
		# withour 'reset = true' parameter.
		if reset then deploy(callback) else callback?(error)

	meteor.stdout.on "data", (data) -> print data.toString()

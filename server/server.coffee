# Code that runs on the server.

# On the server, we're *publishing* certain collections to the client, since
# we've turned off the `autopublish` package. 

#Meteor.publish "parties", ->
#	Parties.find()

#Meteor.publish "dummies", ->
#	Dummies.find()

# For anonymous logins to work, we're registering a login handler to
# deal with "glueing" in between the client request and the server response.
Accounts.registerLoginHandler (options) ->
	# If no `anonymous` key exists in the options
	# parameter, don't do anything and let regular login system
	# do its magic.
	return undefined unless options.anonymous

	# Insert a new anonymous user in the user collection. Be sure to grab the
	# resulting user object in order to return an important token and user id later.
	user = Accounts.insertUserDoc {generateLoginToken: true}, {}, {exists: true}

	return {token: user.token, id: user.id}


# Code that might run on both the client and the server.

# Keep track of the root object. `global` on the server and `window` on the client
root = global ? window

# Create database collections for parties and dummy users.
root.Parties = new Meteor.Collection "parties"
root.Dummies = new Meteor.Collection "dummies"

# Disallow these actions for the client. There's simply no need, since
# we're exposing methods for tailored tasks (see below).
Parties.allow
	insert: (user_id, party) ->
		return false
	
	update: (user_id, party, fields, modifier) ->
		return false

	remove: (user_id, party) ->
		return false

# ## Routes

Meteor.Router.add "/parties/clean", "DELETE", ->
	console.log "Removing all parties ..."
	Parties.remove({})
	[204, "No Content"]

Meteor.Router.add "/parties/:id", "DELETE", (id) ->
	console.log "Removing party with id #{id} ..."
	Parties.remove(id)
	[204, "No Content"]


# ## Methods

Meteor.methods

	# The method for creating a party with a bunch of data from
	# an `options` object.
	create_party: (options) ->
		# Check the types of the values in the parameter.
		check(options, 
			description: String
			location: NonEmptyString
			host: String
			future: Boolean
			x: Number
			y: Number
		)

		# Basic error handling to ensure that the `location`, `description`, and
		# `host` properties aren't too long.
		if options.location.length > 50
			throw new Meteor.Error 413, "Namnet på festens plats är för lång"
		if options.description.length > 50
			throw new Meteor.Error 413, "Festens beskrivning är för lång"
		if options.host.length > 50
			throw new Meteor.Error 413, "Namnet på festens arrangerare är för lång"

		# At last, insert the data in the database collection as a new Party. 
		Parties.insert
			x: options.x
			y: options.y
			description: options.description
			location: options.location
			host: options.host
			future: options.future
			# Note that we don't have any attendees yet, hence the empty array. 
			attendees: []

	# Method for letting an anonymous user with a `user_id` attend to a
	# party (`party_id`).
	attend: (party_id, user_id) ->
		check party_id, String
		check user_id, String

		# Check that the party and user actually exist. 
		party = Parties.findOne(party_id)
		throw new Meteor.Error 400, "Festen existerar inte" unless party

		user = Meteor.users.findOne(user_id)
		throw new Meteor.Error 400, "Användaren existerar inte" unless party

		# Update the actual party by adding the user's id to the `attendees` property.
		Parties.update party_id, {$addToSet: {attendees: user_id}}

# Helper function in validations to check
# that a string is non-empty.
NonEmptyString = Match.Where (str) ->
	check str, String
	str.length isnt 0

root.attending = (party) ->
	party.attendees.length







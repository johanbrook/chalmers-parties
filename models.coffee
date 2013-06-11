root = global ? window

root.Parties = new Meteor.Collection "parties"
root.Dummies = new Meteor.Collection "dummies"

Parties.allow
	insert: (user_id, party) ->
		return false
	
	update: (user_id, party, fields, modifier) ->
		if user_id isnt party.owner
			return false

		allowed = ['description', 'host', 'location', 'x', 'y']
		if _.difference(fields, allowed).length
			return false

		return true

	remove: (user_id, party) ->
		party.owner is user_id

# ## Methods

Meteor.methods
	create_party: (options) ->
		check(options, 
			description: String
			location: NonEmptyString
			host: String
			x: Number
			y: Number
		)

		if options.location.length > 50
			throw new Meteor.Error 413, "Namnet på festens plats är för lång"
		if options.description.length > 50
			throw new Meteor.Error 413, "Festens beskrivning är för lång"
		if options.host.length > 50
			throw new Meteor.Error 413, "Namnet på festens arrangerare är för lång"

		Parties.insert
			x: options.x
			y: options.y
			description: options.description
			location: options.location
			host: options.host
			attendees: []

	attend: (party_id, user_id) ->
		check party_id, String
		check user_id, String

		party = Parties.findOne(party_id)
		throw new Meteor.Error 400, "Festen existerar inte" unless party

		user = Meteor.users.findOne(user_id)
		throw new Meteor.Error 400, "Användaren existerar inte" unless party

		Parties.update party_id, {$addToSet: {attendees: user_id}}

NonEmptyString = Match.Where (str) ->
	check str, String
	str.length isnt 0

root.attending = (party) ->
	party.attendees.length







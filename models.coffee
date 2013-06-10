root = global ? window

root.Parties = new Meteor.Collection "parties"

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

NonEmptyString = Match.Where (str) ->
	check str, String
	str.length isnt 0

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
			rsvps: []

	#rsvp: (party_id, rsvp) ->
		# check party_id, String
		# check rsvp, String

		# if not _.contains ['ja', 'nej', 'kanske'], rsvp
		# 	throw new Meteor.Error 400, "Felaktigt svar"

		# party = Parties.findOne party_id

		# unless party
		# 	throw new Meteor.Error 400, "Festen existerar inte"

		# rsvp_index = _.indexOf( _.pluck party.rsvps, 'user', @user_id )

		# if rsvp_index isnt -1
		# 	if Meteor.isServer
		# 		Parties.update
		# 			{_id: party_id},
		# 			{$set: {"rsvps.$.rsvp": rsvp}}

		# 	else
		# 		modifier = {$set: {}}
		# 		modifier.$set['rsvps' + 'rsvpIndex' + ".rsvp"] = rsvp

		# 		Parties.update party_id, modifier

		# else
		# 	Parties.update party_id,
		# 		$push: {rsvps: {user: @user_id}}













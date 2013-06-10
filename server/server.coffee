# Server

Meteor.publish "parties", ->
	Parties.find 
		$or: [owner: @user_id]

Accounts.registerLoginHandler (options) ->
	return undefined unless options.anonymous

	user = Accounts.insertUserDoc {generateLoginToken: true}, {}, {exists: true}

	return {token: user.token, id: user.id}
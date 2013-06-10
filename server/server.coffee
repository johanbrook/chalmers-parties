# Server

Meteor.publish "parties", ->
	Parties.find 
		$or: [owner: @user_id]
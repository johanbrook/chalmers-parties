# Client

Meteor.subscribe "parties"

Meteor.loginAnonymously = (fn) ->
	Meteor.call 'login', anonymous: true, (err, user) ->
		Accounts._makeClientLoggedIn(user.id, user.token)
		fn? and fn()

Meteor.startup ->
	Meteor.loginAnonymously()

# ## Details area

Template.details.party = ->
	Parties.findOne Session.get("selected")

# ## Attendees area

Template.attendees.events
	'click #rsvp-yes' : (event, template) ->
		Meteor.call 'attend', Session.get('selected'), Meteor.userId()
		#$(event.currentTarget).attr("disabled", true).val("Wohoo!").remove()

Template.attendees.is_attending = ->
	attendees = Parties.findOne(Session.get 'selected').attendees
	not _.contains attendees, Meteor.userId()


# ## Map area

coordsRelativeToElement = (event, element) ->
	offset = $(element).offset()

	return {x: event.pageX - offset.left, y: event.pageY - offset.top}

Template.map.events
	"mousedown circle, mousedown text" : (event, template) ->
		Session.set 'selected', event.currentTarget.id

	"dblclick .map" : (event, template) ->
		coords = coordsRelativeToElement(event, event.currentTarget)
		
		Session.set 'createCoords', x: coords.x, y: coords.y
		Session.set 'createError', null

		show_create_popup_at_coords(coords)

Template.map.rendered = ->
	self = this
	self.node = self.find("svg")

	unless self.handle
		self.handle = Deps.autorun ->
			selected = Session.get 'selected'
			selected_party = selected and Parties.findOne(selected)

			radius = (party) ->
				10 + Math.sqrt(attending(party)) * 5

			# Draw circles
			update_circles = (group) ->		
				group
					.attr("id", (party) -> party._id)
					.attr("cx", (party) -> party.x)
					.attr("cy", (party) -> party.y)
					.attr("r", radius)
					.style("opacity", (party) -> 
						if selected is party._id then 1 else 0.6)

			# Update labels with attendee count
			update_attendees = (group) ->
				group
					.attr("id", (party) -> party._id)
					.attr("x", (party) -> party.x)
					.attr("y", (party) -> party.y + radius(party) / 2)
					.text((party) -> attending(party) or "")
					.style("font-size", (party) -> radius(party) * 1.25 + "px")

			circles = d3
				.select(self.node).select(".circles").selectAll("circle")
				.data(Parties.find().fetch(), (party) -> party._id)

			update_circles(circles.enter().append("circle"))
			update_circles(circles.transition().duration(250).ease("cubic-out"))
			circles.exit().transition().duration(250).attr("r", 0).remove()

			labels = d3
				.select(self.node).select(".labels").selectAll("text")
				.data(Parties.find().fetch(), (party) -> party._id)

			update_attendees(labels.enter().append("text"))
			update_attendees(labels.transition().duration(250).ease("cubic-out"))
			labels.exit().remove()

			callout = d3.select(self.node).select("circle.callout")
			        .transition().duration(250).ease("cubic-out")

			if selected_party
				callout.attr("cx", selected_party.x)
					.attr("cy", selected_party.y)
					.attr("r", radius(selected_party) + 10)
					.attr("class", "callout")
					.attr("display", '')
			else
				callout.attr("display", 'none')

Template.map.destroyed = ->
	@handle and @handle.stop()


# ## The 'Create' area

show_create_popup_at_coords = (coords) ->
	Session.set 'showCreatePopup', true

	$popup = $(".create-popup")
	[width, height] = [$popup.outerWidth(), $popup.outerHeight()]

	$popup.css top: coords.y-height-10, left: coords.x - (width / 2) + 10

Template.page.showCreatePopup = ->
	Session.get 'showCreatePopup'

Template.createPopup.events
	'click .save' : (event, template) ->
		party = 
			description: template.find(".description").value
			location: template.find(".location").value
			host: template.find(".host").value
			coords: Session.get 'createCoords'

		if party.description.length and party.location.length
			add_party(party)
			Session.set 'showCreatePopup', false
		else
			Session.set 'createError', "Lägg till en kort beskrivning och plats – hur ska man
				annars vet vad din jävla fest är om?"

	'click .close' : (event, template) ->
		Session.set 'showCreatePopup', false

Template.createPopup.error = ->
	Session.get 'createError'

add_party = (party) ->
	Meteor.call 'create_party',
		description: party.description
		location: party.location
		host: party.host
		x: party.coords.x
		y: party.coords.y
	, (error, the_party) ->
		Session.set 'selected', the_party unless error




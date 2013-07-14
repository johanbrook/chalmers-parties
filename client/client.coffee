# Code which runs on the client.

# The client has to subscribe to the `parties` and `dummies`
# collections from the server.
Meteor.subscribe "parties"
Meteor.subscribe "dummies"

# # Initialization

# Meteor startup
Meteor.startup ->
	Meteor.loginAnonymously()
	Meteor.hideToolbar()

# In order to login anonymously, we create a method which calls
# the built-in `login` function with a parameter hash which 
# contains `anonymous: true`. This will be passed to our custom
# login handler (see *server.coffee*). 
# 
# On success, make the user logged in with our generated token and user id.
Meteor.loginAnonymously = (fn) ->
	Meteor.call 'login', anonymous: true, (err, user) ->
		Accounts._makeClientLoggedIn(user.id, user.token) unless err
		fn? and fn()

# Hide toolbar on iPhone
Meteor.hideToolbar = ->
	window.top.scrollTo(0, 1);

# # Template helpers and functions

# ## Details area

# Helper to provide how many active visitors are looking at the site.
Template.howMany.nrVisitors = ->
	if Dummies.find() isnt undefined
	    return Dummies.find().fetch().length

	return 'Well well well...';

# Helper to provide the currently selected party from the map.
Template.details.party = ->
	Parties.findOne Session.get("selected")

# ## Attendees area

# Check to see if the current active user is attending the currently
# selected party. 
Template.attendees.is_attending = ->
	attendees = Parties.findOne(Session.get 'selected').attendees
	not _.contains attendees, Meteor.userId()


# ## Map area

# When the map is rendered, we hook up a callback to handle redrawing
# of the circles and labels.
# 
# A "handle" is used for the `Deps.autorun` part. The code block in the
# autorun callback will be run once and then for everytime its reactive
# data sources change. Read more in the [Meteor docs](http://docs.meteor.com/#deps_autorun).
Template.map.rendered = ->
	self = this
	self.node = self.find("svg")
	$map = $(self.find(".map"))

	# Setup custom touch events for the map
	bindTouchEvents(self)

	unless self.handle
		self.handle = Deps.autorun ->
			selected = Session.get 'selected'
			selected_party = selected and Parties.findOne(selected)

			# Helper function to compute an arbitrary radius number
			# for a given `party`.
			radius = (party) ->
				10 + Math.sqrt(attending(party)) * 5

			# Draw circles
			# Set properties on the circles in the map according
			# to properties from the party representing the circle.
			update_circles = (group) ->		
				group
					.attr("id", (party) -> party._id)
					.attr("cx", (party) -> party.x)
					.attr("cy", (party) -> party.y)
					.attr("r", (party) -> radius party)
					.style("opacity", (party) -> 
						if selected is party._id then 1 else 0.6)

			# Draw and update labels with attendee count.
			update_attendees = (group) ->
				group
					.attr("id", (party) -> party._id)
					.attr("x", (party) -> party.x)
					.attr("y", (party) -> party.y + radius(party) / 2)
					.text((party) -> attending(party) or "")
					.style("font-size", (party) -> radius(party) * 1.25 + "px")

			# Do the actual glueing of the vector elements and the data sources from
			# the database. The `circles` and `labels` variables will now be connected
			# to the parties in the database.
			circles = d3
				.select(self.node).select(".circles").selectAll("circle")
				.data(Parties.find().fetch(), (party) -> party._id)

			labels = d3
				.select(self.node).select(".labels").selectAll("text")
				.data(Parties.find().fetch(), (party) -> party._id)

			# Add some nice transitions when drawing the circles and labels
			# by adding some transitions.
			update_circles(circles.enter().append("circle"))
			update_circles(circles.transition().duration(250).ease("cubic-out"))
			circles.exit().transition().duration(250).attr("r", 0).remove()

			update_attendees(labels.enter().append("text"))
			update_attendees(labels.transition().duration(250).ease("cubic-out"))
			labels.exit().remove()

			# The "callout" is a larger circle with a stroke which marks the
			# currently selected party (if it exists). 
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

# When the map template is destroy, stop the current autorun computation object.
Template.map.destroyed = ->
	@handle and @handle.stop()


# ## The 'Create' area

# Provide the contents of the `createError` session variable.
Template.createPopup.error = ->
	Session.get 'createError'

# # Events

# Here we hook up some events to DOM objects in the templates.

# ## General

Template.page.events
	"tap .panel-toggle" : (event, template) ->
		event.preventDefault()
		$details = $(".details-container")
		$details.toggleClass "show"

# ## Attendees

Template.attendees.events
	# When clicking the 'Attend' button, we call the `attend_party()` function.
	'click #rsvp-yes' : (event, template) ->
		attend_party()

# ## Map

Template.map.events
	# When selecting a party on the map, set it to selected along
	# with its `id` attribute (which is the _id attribute for the object
	# in the database).
	"mousedown circle, mousedown text" : (event, template) ->
		Session.set 'selected', event.currentTarget.id

	# When doubleclicking on the map we want to add a new party. 
	"dblclick .map" : (event, template) ->
		event.stopPropagation()
		# Map out the correct coordinates on the map for the party.
		setCoordinates(event)

		# Show the "Create party" popup along with the coords.
		show_create_popup_at_position(event, template)

# ## The "Create Party" popup

Template.createPopup.events
	# Let users create a party by hitting the 'enter' key
	# when done instead of clicking the 'Save' button.
	'keydown' : (event, template) ->
		switch event.which
			when 13 then $(template.find(".save")).trigger("click")
			when 27 then hide_popup()

	# When finished, hitting the 'Save' button should try
	# to save the party.
	'click .save' : (event, template) ->
		party = 
			description: template.find(".description").value
			location: template.find(".location").value
			host: template.find(".host").value
			coords: Session.get 'createCoords'

		# Only add the party if description and location exists.
		if party.description.length and party.location.length
			add_party(party)
			hide_popup()
		else
			Session.set 'createError', "Lägg till en kort beskrivning och plats – hur ska man
				annars vet vad din jävla fest är om?"

	# When hitting 'Close', hide the popup.
	'click .close' : (event, template) ->
		hide_popup()

# # Helpers functions

# Various helper functions to abstract away boring logic from the event code et al.

# Bind custom touch events, i.e. event types which aren't
# supported by Meteor.
bindTouchEvents = (template) ->
	$map = $(template.firstNode)

	# On long tap, show create dialog and center it in the map viewport.
	$map.on "longTap", (evt) ->
		setCoordinates(evt)

		[w, h] = [$(".popup-container").outerWidth(), $(".popup-container").outerHeight()]

		center = 
			x: $map[0].scrollLeft + ($map.outerWidth() / 2) - (w / 2)
			y: $map[0].scrollTop + ($map.outerHeight() / 2) - (h / 2)

		show_create_popup_at_coords(center, template, focus: false)

# Reveal the 'Create Party' popup.
show_create_popup = (options) ->
	defaults =
		focus: true
	settings = $.extend {}, defaults, options	
	$popup = $(".popup-container").addClass("show")
	$popup.find("input:first").focus() if settings.focus

	return $popup

# Show the 'Create Party' popup at certain coordinates in the map. 
show_create_popup_at_coords = (coords, template, options) ->
	$popup = show_create_popup(options)
	$popup.css top: coords.y, left: coords.x

# Show the 'Create Party' popup at the position where the user double clicked/tapped
# on the map.
show_create_popup_at_position = (event, template, options) ->
	$popup = show_create_popup(options)
	coords = coordsRelativeToElement(event, event.currentTarget)
	[width, map_height] = [$popup.outerWidth(), $(template.find(".map")).outerHeight()]

	$popup.css bottom: map_height-coords.y+15, left: coords.x - (width / 2) + 10

# Fetch the coordinates for the point selected in the map, and set global
# session variable.
setCoordinates = (event) ->
	coords = coordsRelativeToElement(event, event.currentTarget)
	Session.set 'createCoords', x: coords.x, y: coords.y
	Session.set 'createError', null
	return coords

# Compute the correct coordinates in an `element` stemmed from and `event`.
coordsRelativeToElement = (event, element) ->
	offset = $(element).offset()
	[scrollLeft, scrollTop] = [event.currentTarget.scrollLeft, event.currentTarget.scrollTop]
	data = 
		x: event.pageX - offset.left + scrollLeft
		y: event.pageY - offset.top + scrollTop

	return data

# Returns the center position of the map
getMapCenter = ->
	[$(".map").outerWidth() / 2, $(".map").outerHeight() / 2]

# Adds a new party to the database collection by calling our exposed
# `create_party` method (see *models.coffee*) with given parameters.
add_party = (party) ->
	Meteor.call 'create_party',
		description: party.description
		location: party.location
		host: party.host
		x: party.coords.x
		y: party.coords.y
	, (error, the_party) ->
		# On successful add, select the party and automatically attend to it
		# (since you created it, duh).
		unless error
			Session.set 'selected', the_party
			attend_party(the_party)

# Lets the current user attend to a given `party` or the currently selected one by
# calling our exposed `attend` method (see *models.coffee*).
attend_party = (party) ->
	Meteor.call 'attend', party or Session.get('selected'), Meteor.userId()

# Hides the 'Create party' popup.
hide_popup = ->
	$popup = $(".popup-container")
	$popup
	.find(".description").val("").end()
	.find(".host").val("").end()
	.find(".location").val("").end()
	.removeClass("show")

# Client

Meteor.subscribe "parties"


# ## Details area
Template.details.party = ->
	Parties.findOne Session.get("selected")

Template.details.anyParties = ->
	Parties.find().count() > 0

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

			# Draw circles
			update_circles = (group) ->
				
				group
					.attr("id", (party) -> party._id)
					.attr("cx", (party) -> party.x)
					.attr("cy", (party) -> party.y)
					.attr("r", 10)
					.style("opacity", (party) -> 
						if selected is party._id then 1 else 0.6)

			circles = d3
				.select(self.node).select(".circles").selectAll("circle")
				.data(Parties.find().fetch(), (party) -> party._id)

			update_circles(circles.enter().append("circle"))
			update_circles(circles.transition().duration(250).ease("cubic-out"))
			circles.exit().transition().duration(250).attr("r", 0).remove()

			callout = d3.select(self.node).select("circle.callout")
			        .transition().duration(250).ease("cubic-out")

			if selected_party
				callout.attr("cx", selected_party.x)
					.attr("cy", selected_party.y)
					.attr("r", 20)
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




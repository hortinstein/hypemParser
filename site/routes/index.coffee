
#
#GET home page.
#

index = (req, res) ->
	options =
		id: 'home'
		title: 'Look for songs!'
	res.render 'index', options


search = (req, res) ->
	options =
		id: 'home'
		title: 'Look for songs!'
	res.render 'index', options


exports.search = search


partials = (req, res) ->
	name = req.params.name
	res.render 'partials/' + name


exports.index = index
exports.partials = partials
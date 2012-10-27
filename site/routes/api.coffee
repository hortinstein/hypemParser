
#
#SEARCH
#

search = (req, res) ->

	search_string = req.query["query"]

	#PERFORM SEARCH

	test_song =
		id: '1235'
		title: 'My Test Song'
		artist: 'Farid Zakaria'

		
	res.json([test_song])


exports.search = search
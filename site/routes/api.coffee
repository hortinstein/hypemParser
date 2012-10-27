
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
	test_song2 =
		id: '1337'
		title: 'not My Test Song'
		artist: 'Alex'

		
	res.json([test_song,test_song2])


exports.search = search
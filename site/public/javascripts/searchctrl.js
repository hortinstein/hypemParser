function SearchCtrl($scope, $http, $location) {

	$http.get('/api/search').success(function(data) {

		$scope.songs = data;

	});

	$scope.search = function(query) {

		console.log("Query: " + query);

		$location.path("search").search( { 'query' : query } );
	};

};
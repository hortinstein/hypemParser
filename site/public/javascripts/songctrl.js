

function SongCtrl($scope, $http, $location){

	$http.get('/search').success(function(data) {

		$scope.songs = data;

	});

};
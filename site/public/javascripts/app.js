angular.module('myApp', []).
	config(['$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {
		$routeProvider.
			when('/', {
				templateUrl: 'partials/index',
			}).
			when('/search', {
				templateUrl: 'partials/search_results',
				controller: SearchCtrl
			}).
			otherwise({
				redirectTo: '/'
			});
		$locationProvider.html5Mode(true);
	}]);
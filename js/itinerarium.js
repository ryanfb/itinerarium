// Generated by CoffeeScript 1.6.3
(function() {
  var addConnection, addConnectionToDropdown, ajaxSpinner, bboxIsPoint, calculateDistance, calculateDistanceBetweenConnections, connectionURL, createDropdown, createProgressBars, current_connection, davis_app, displayConnection, displayConnectionMarker, displayDistance, displayPrevNextButtons, flickrMachineSearch, flickrPageURL, flickrSearch, flickrThumbURL, flickr_api_key, flickr_rest_url, google_map, google_map_marker, google_map_rectangle, google_maps_api_key, instagramSearch, instagram_client_id, instagram_search_url, itineraryHandler, itineraryURLHandler, itinerary_connections, itinerary_loaded, itinerary_places, itinerary_url, known_itineraries, loadItinerary, pleiadesURL, pleiades_url, postConnectionsLoad, sortByLongitude;

  itinerary_places = [];

  itinerary_connections = [];

  itinerary_url = null;

  known_itineraries = [
    {
      title: "Hadrian's Wall",
      path: "hadrian_full"
    }, {
      title: "Hadrian's Wall (milecastles and turrets only)",
      path: "hadrian_partial"
    }, {
      title: "Vicarello Beaker 1",
      path: "vicarello_1"
    }, {
      title: "Vicarello Beaker 2",
      path: "vicarello_2"
    }, {
      title: "Vicarello Beaker 3",
      path: "vicarello_3"
    }, {
      title: "Vicarello Beaker 4",
      path: "vicarello_4"
    }
  ];

  flickr_api_key = 'f6bca6b68d42d5a436054222be2f530e';

  flickr_rest_url = 'http://api.flickr.com/services/rest/?jsoncallback=?';

  instagram_client_id = '0bb344d5e9454a8a8ac70f0b715be3d8';

  instagram_search_url = 'https://api.instagram.com/v1/media/search?';

  google_maps_api_key = 'AIzaSyBoQNYbbHb-MEGa4_oq83_JCLt9cKfd4vg';

  google_map = null;

  google_map_marker = null;

  google_map_rectangle = null;

  pleiades_url = 'http://pleiades.stoa.org/places/';

  itinerary_loaded = false;

  current_connection = 0;

  loadItinerary = function() {
    var connection, _i, _len, _results;
    if (!itinerary_loaded) {
      itinerary_loaded = true;
      $('#known-itinerary-list').remove();
      _results = [];
      for (_i = 0, _len = itinerary_places.length; _i < _len; _i++) {
        connection = itinerary_places[_i];
        _results.push(addConnection(connection, itinerary_places.length));
      }
      return _results;
    }
  };

  itineraryHandler = function(req) {
    if (itinerary_loaded) {
      current_connection = parseInt(req.params['connection_id']);
      return displayConnection(itinerary_connections[current_connection]);
    } else {
      console.log(req.params['itinerary']);
      itinerary_places = req.params['itinerary'].split(',');
      current_connection = parseInt(req.params['connection_id']);
      $('.container').append("<br/>");
      return loadItinerary();
    }
  };

  itineraryURLHandler = function(req) {
    if (itinerary_loaded) {
      current_connection = parseInt(req.params['connection_id']);
      return displayConnection(itinerary_connections[current_connection]);
    } else {
      itinerary_url = unescape(req.params['itinerary_url']);
      console.log(itinerary_url);
      return $.getJSON(itinerary_url, function(result) {
        $('.container').append("<h2>" + result.title + "</h2>");
        $('.container').append("<h3>" + result.description + "</h3>");
        itinerary_places = result.connectsWith;
        current_connection = parseInt(req.params['connection_id']);
        return loadItinerary();
      });
    }
  };

  davis_app = Davis(function() {
    this.get('/', function(req) {
      var itinerary, _i, _len, _results;
      if (!window.location.hash) {
        console.log("No itinerary.");
        $('<div/>').attr('id', 'known-itinerary-list').appendTo('.container');
        _results = [];
        for (_i = 0, _len = known_itineraries.length; _i < _len; _i++) {
          itinerary = known_itineraries[_i];
          $('<a/>').attr('href', "#/itinerary_url/itineraries%2F" + itinerary.path + ".json").text(itinerary.title).appendTo('#known-itinerary-list');
          _results.push($('<br/>').appendTo('#known-itinerary-list'));
        }
        return _results;
      }
    });
    this.get('/#/itinerary/:itinerary', function(req) {
      return Davis.location.assign(new Davis.Request("#/itinerary/" + req.params['itinerary'] + "/connection/0"));
    });
    this.get('/#/itinerary_url/:itinerary_url', function(req) {
      return Davis.location.assign(new Davis.Request("#/itinerary_url/" + req.params['itinerary_url'] + "/connection/0"));
    });
    this.get('#/itinerary/:itinerary/connection/:connection_id', itineraryHandler);
    this.get('/#/itinerary/:itinerary/connection/:connection_id', itineraryHandler);
    this.get('#/itinerary_url/:itinerary_url/connection/:connection_id', itineraryURLHandler);
    return this.get('/#/itinerary_url/:itinerary_url/connection/:connection_id', itineraryURLHandler);
  });

  pleiadesURL = function(id) {
    return pleiades_url + id + '/json';
  };

  sortByLongitude = function(a, b) {
    return a.reprPoint[0] - b.reprPoint[0];
  };

  flickrThumbURL = function(photo) {
    return "http://farm" + photo.farm + ".staticflickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_q.jpg";
  };

  flickrPageURL = function(photo) {
    return "http://www.flickr.com/photos/" + photo.owner + "/" + photo.id;
  };

  bboxIsPoint = function(bbox) {
    return (bbox[0] === bbox[2]) && (bbox[1] === bbox[3]);
  };

  connectionURL = function(connection_id) {
    if (itinerary_url) {
      return location.href.replace(location.hash, "") + ("#/itinerary_url/" + (encodeURIComponent(itinerary_url)) + "/connection/" + connection_id);
    } else {
      return location.href.replace(location.hash, "") + ("#/itinerary/" + (itinerary_places.join()) + "/connection/" + connection_id);
    }
  };

  flickrMachineSearch = function(id, selector) {
    var parameters;
    if (selector == null) {
      selector = '.container';
    }
    ajaxSpinner().appendTo(selector);
    parameters = {
      api_key: flickr_api_key,
      method: 'flickr.photos.search',
      format: 'json',
      sort: 'interestingness-desc',
      machine_tags: "pleiades:*=" + id
    };
    return $.getJSON(flickr_rest_url, parameters, function(data) {
      var photo, _i, _len, _ref, _results;
      $("" + selector + " .spinner").remove();
      if (data.photos.photo.length === 0) {
        return $('<p/>').text('No results found.').appendTo(selector);
      } else {
        _ref = data.photos.photo;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          photo = _ref[_i];
          _results.push($('<a/>').attr('href', flickrPageURL(photo)).attr('target', '_blank').append($('<img/>').attr('src', flickrThumbURL(photo))).appendTo(selector));
        }
        return _results;
      }
    });
  };

  ajaxSpinner = function() {
    return $('<img/>').attr('src', 'spinner.gif').attr('class', 'spinner');
  };

  instagramSearch = function(lat, long, distance, selector) {
    var parameters;
    if (distance == null) {
      distance = 1000;
    }
    if (selector == null) {
      selector = '.container';
    }
    ajaxSpinner().appendTo(selector);
    parameters = {
      lat: lat,
      lng: long,
      client_id: instagram_client_id,
      distance: distance
    };
    return $.ajax({
      dataType: 'jsonp',
      data: parameters,
      url: instagram_search_url,
      type: 'GET',
      crossDomain: true,
      success: function(data) {
        var photo, _i, _len, _ref, _results;
        $("" + selector + " .spinner").remove();
        if (data.data.length === 0) {
          return $('<p/>').text('No results found.').appendTo(selector);
        } else {
          _ref = data.data;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            photo = _ref[_i];
            _results.push($('<a/>').attr('href', photo.link).attr('target', '_blank').append($('<img/>').attr('src', photo.images.thumbnail.url)).appendTo(selector));
          }
          return _results;
        }
      }
    });
  };

  flickrSearch = function(bbox, selector) {
    var parameters;
    if (selector == null) {
      selector = '.container';
    }
    ajaxSpinner().appendTo(selector);
    parameters = {
      api_key: flickr_api_key,
      method: 'flickr.photos.search',
      format: 'json',
      min_taken_date: '1800-01-01 00:00:00',
      extras: 'geo'
    };
    if (bboxIsPoint(bbox)) {
      parameters.lon = bbox[0];
      parameters.lat = bbox[1];
      parameters.radius = 0.5;
    } else {
      parameters.bbox = bbox.join(',');
    }
    return $.getJSON(flickr_rest_url, parameters, function(data) {
      var photo, _i, _len, _ref, _results;
      $("" + selector + " .spinner").remove();
      if (data.photos.photo.length === 0) {
        return $('<p/>').text('No results found.').appendTo(selector);
      } else {
        _ref = data.photos.photo;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          photo = _ref[_i];
          _results.push($('<a/>').attr('href', flickrPageURL(photo)).attr('target', '_blank').append($('<img/>').attr('src', flickrThumbURL(photo))).appendTo(selector));
        }
        return _results;
      }
    });
  };

  calculateDistance = function(lat1, lon1, lat2, lon2) {
    var R, a, c, d, dLat, dLon;
    R = 6371;
    dLat = (lat2 - lat1) * Math.PI / 180;
    dLon = (lon2 - lon1) * Math.PI / 180;
    lat1 = lat1 * Math.PI / 180;
    lat2 = lat2 * Math.PI / 180;
    a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return d = R * c;
  };

  calculateDistanceBetweenConnections = function(index1, index2) {
    var index, total_distance, _i;
    total_distance = 0.0;
    for (index = _i = index1; index1 <= index2 ? _i < index2 : _i > index2; index = index1 <= index2 ? ++_i : --_i) {
      total_distance += calculateDistance(itinerary_connections[index].reprPoint[1], itinerary_connections[index].reprPoint[0], itinerary_connections[index + 1].reprPoint[1], itinerary_connections[index + 1].reprPoint[0]);
    }
    return total_distance;
  };

  displayDistance = function() {
    var distance;
    if (current_connection !== 0) {
      distance = calculateDistance(itinerary_connections[current_connection].reprPoint[1], itinerary_connections[current_connection].reprPoint[0], itinerary_connections[current_connection - 1].reprPoint[1], itinerary_connections[current_connection - 1].reprPoint[0]);
      $('<em/>').text("" + (distance.toFixed(2)) + "km from " + itinerary_connections[current_connection - 1].title + ".").append($('<br/>')).appendTo('.connection-container');
    }
    if (current_connection !== (itinerary_connections.length - 1)) {
      distance = calculateDistance(itinerary_connections[current_connection].reprPoint[1], itinerary_connections[current_connection].reprPoint[0], itinerary_connections[current_connection + 1].reprPoint[1], itinerary_connections[current_connection + 1].reprPoint[0]);
      $('<em/>').text("" + (distance.toFixed(2)) + "km to " + itinerary_connections[current_connection + 1].title + ".").append($('<br/>')).appendTo('.connection-container');
    }
    return $('<br/>').appendTo('.connection-container');
  };

  displayPrevNextButtons = function() {
    $('#prev-next-container').empty();
    $('<br/>').appendTo('#prev-next-container');
    $('<a/>').attr('id', 'prev-button').attr('class', 'btn btn-primary btn-lg').attr('role', 'button').attr('href', connectionURL(parseInt(current_connection) - 1)).text("Prev").appendTo('#prev-next-container');
    $('#prev-next-container').append(' ');
    $('<a/>').attr('id', 'next-button').attr('class', 'btn btn-primary btn-lg').attr('role', 'button').attr('href', connectionURL(parseInt(current_connection) + 1)).text("Next").appendTo('#prev-next-container');
    if (current_connection === 0) {
      $('#prev-button').attr('disabled', 'disabled');
    }
    if (current_connection === (itinerary_connections.length - 1)) {
      return $('#next-button').attr('disabled', 'disabled');
    }
  };

  displayConnectionMarker = function(connection) {
    var marker, marker_options, rectangle_options, _i, _len, _ref;
    _ref = [google_map_marker, google_map_rectangle];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      marker = _ref[_i];
      if (marker !== null) {
        marker.setMap(null);
        marker = null;
      }
    }
    if (!bboxIsPoint(connection.bbox)) {
      rectangle_options = {
        strokeWeight: 2,
        strokeColor: '#FF0000',
        strokeOpacity: 0.8,
        fillColor: '#FF0000',
        fillOpacity: 0.35,
        map: google_map,
        bounds: new google.maps.LatLngBounds(new google.maps.LatLng(connection.bbox[1], connection.bbox[0]), new google.maps.LatLng(connection.bbox[3], connection.bbox[2]))
      };
      google_map_rectangle = new google.maps.Rectangle(rectangle_options);
    }
    marker_options = {
      position: new google.maps.LatLng(connection.reprPoint[1], connection.reprPoint[0]),
      map: google_map,
      title: connection.title
    };
    return google_map_marker = new google.maps.Marker(marker_options);
  };

  displayConnection = function(connection) {
    displayConnectionMarker(connection);
    $('.connection-container').remove();
    $('<div/>').attr('class', 'connection-container').attr('id', "place-" + connection.id).appendTo('.container');
    $('<h4/>').appendTo("#place-" + connection.id);
    $('<a/>').attr('href', "" + pleiades_url + connection.id).attr('target', '_blank').text(connection.title).appendTo("#place-" + connection.id + " h4");
    $('<p/>').text(connection.description).appendTo("#place-" + connection.id);
    displayDistance();
    $('<div/>').attr('class', 'flickr-machine').appendTo("#place-" + connection.id);
    $('<h5/>').text('Flickr Machine Tags:').appendTo("#place-" + connection.id + " .flickr-machine");
    $('<br/>').appendTo("#place-" + connection.id);
    $('<div/>').attr('class', 'flickr-geo').appendTo("#place-" + connection.id);
    $('<h5/>').text('Flickr Geo Search:').appendTo("#place-" + connection.id + " .flickr-geo");
    $('<br/>').appendTo("#place-" + connection.id);
    $('<div/>').attr('class', 'instagram').appendTo("#place-" + connection.id);
    $('<h5/>').text('Instagram:').appendTo("#place-" + connection.id + " .instagram");
    flickrMachineSearch(connection.id, "#place-" + connection.id + " .flickr-machine");
    flickrSearch(connection.bbox, "#place-" + connection.id + " .flickr-geo");
    instagramSearch(connection.reprPoint[1], connection.reprPoint[0], 500, "#place-" + connection.id + " .instagram");
    $('#connections-progress').attr('style', "width: " + ((current_connection / (itinerary_connections.length - 1)) * 100) + "%");
    $('#distance-progress').attr('style', "width: " + ((calculateDistanceBetweenConnections(0, current_connection) / calculateDistanceBetweenConnections(0, itinerary_connections.length - 1)) * 100) + "%");
    displayPrevNextButtons();
    return $('#connections-select').val(current_connection);
  };

  addConnectionToDropdown = function(connection_index) {
    var connection;
    connection = itinerary_connections[connection_index];
    return $('<option/>').attr('value', connection_index).text(connection.title).appendTo('#connections-select');
  };

  createDropdown = function(connections) {
    var connection_index, _i, _ref;
    $('<select/>').attr('class', 'form-control').attr('id', 'connections-select').appendTo('.container');
    for (connection_index = _i = 0, _ref = connections.length; 0 <= _ref ? _i < _ref : _i > _ref; connection_index = 0 <= _ref ? ++_i : --_i) {
      addConnectionToDropdown(connection_index);
    }
    return $('#connections-select').change(function(event) {
      return Davis.location.assign(new Davis.Request(connectionURL($('#connections-select').val())));
    });
  };

  createProgressBars = function() {
    $('<div/>').attr('id', 'progress-bar-container').appendTo('.container');
    $('<div/>').attr('class', 'progress').append($('<div/>').attr('class', 'progress-bar progress-bar-info').attr('role', 'progressbar').attr('style', 'width: 0%').attr('id', 'connections-progress').text('Places visited')).appendTo('#progress-bar-container');
    return $('<div/>').attr('class', 'progress').append($('<div/>').attr('class', 'progress-bar progress-bar-warning').attr('role', 'progressbar').attr('style', 'width: 0%').attr('id', 'distance-progress').text('Distance traveled')).appendTo('#progress-bar-container');
  };

  postConnectionsLoad = function() {
    var connections_bbox, item, latitudes, longitudes, map_options, matching_connection, place, route_path, route_polyline, unordered_itinerary_connections, _i, _len;
    $('#load-progress-container').toggle();
    unordered_itinerary_connections = itinerary_connections.slice(0);
    itinerary_connections = [];
    for (_i = 0, _len = itinerary_places.length; _i < _len; _i++) {
      place = itinerary_places[_i];
      matching_connection = _.find(unordered_itinerary_connections, function(connection) {
        return parseInt(connection.id) === parseInt(place);
      });
      if (matching_connection.bbox !== null) {
        itinerary_connections.push(matching_connection);
      }
    }
    longitudes = _.flatten((function() {
      var _j, _len1, _results;
      _results = [];
      for (_j = 0, _len1 = itinerary_connections.length; _j < _len1; _j++) {
        item = itinerary_connections[_j];
        _results.push([item.bbox[0], item.bbox[2]]);
      }
      return _results;
    })());
    latitudes = _.flatten((function() {
      var _j, _len1, _results;
      _results = [];
      for (_j = 0, _len1 = itinerary_connections.length; _j < _len1; _j++) {
        item = itinerary_connections[_j];
        _results.push([item.bbox[1], item.bbox[3]]);
      }
      return _results;
    })());
    connections_bbox = [Math.min.apply(Math, longitudes), Math.min.apply(Math, latitudes), Math.max.apply(Math, longitudes), Math.max.apply(Math, latitudes)];
    createProgressBars();
    createDropdown(itinerary_connections);
    $('<div/>').attr('id', 'prev-next-container').appendTo('.container');
    map_options = {
      center: new google.maps.LatLng(-34.397, 150.644),
      zoom: 8,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    google_map = new google.maps.Map(document.getElementById("map_canvas"), map_options);
    google_map.fitBounds(new google.maps.LatLngBounds(new google.maps.LatLng(connections_bbox[1], connections_bbox[0]), new google.maps.LatLng(connections_bbox[3], connections_bbox[2])));
    route_polyline = {
      path: (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = itinerary_connections.length; _j < _len1; _j++) {
          item = itinerary_connections[_j];
          if (bboxIsPoint(item.bbox)) {
            _results.push(new google.maps.LatLng(item.bbox[1], item.bbox[0]));
          }
        }
        return _results;
      })(),
      strokeColor: "#FF0000",
      strokeOpacity: 1.0,
      strokeWeight: 2
    };
    route_path = new google.maps.Polyline(route_polyline);
    route_path.setMap(google_map);
    return displayConnection(itinerary_connections[current_connection]);
  };

  addConnection = function(connection, length) {
    return $.getJSON(pleiadesURL(connection), function(result) {
      itinerary_connections.push(result);
      $('#load-progress').attr('style', "width: " + ((itinerary_connections.length / length) * 100) + "%;");
      if (itinerary_connections.length === length) {
        return postConnectionsLoad();
      }
    });
  };

  $(document).ready(function() {
    davis_app.start();
    if (window.location.hash) {
      return Davis.location.assign(new Davis.Request("/" + window.location.hash));
    } else {
      return davis_app.lookupRoute('get', '/').run(new Davis.Request('/'));
    }
  });

}).call(this);

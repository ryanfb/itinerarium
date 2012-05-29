$ ?= require 'jquery' # For Node.js compatibility
_ ?= require 'underscore'

hadrian_id = 91358
hadrian_connections = []

flickr_api_key = 'f6bca6b68d42d5a436054222be2f530e'
flickr_rest_url = 'http://api.flickr.com/services/rest/?jsoncallback=?'

google_maps_api_key = 'AIzaSyBoQNYbbHb-MEGa4_oq83_JCLt9cKfd4vg'

pleiadesURL = (id) ->
  'http://pleiades.stoa.org/places/' + id + '/json'

sortByLongitude = (a, b) ->
  a.reprPoint[0] - b.reprPoint[0]

flickrURL = (photo) ->
  "http://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_q.jpg"

bboxIsPoint = (bbox) ->
  (bbox[0] == bbox[2]) && (bbox[1] == bbox[3])

flickrMachineSearch = (id) ->
  parameters =
    api_key: flickr_api_key
    method: 'flickr.photos.search'
    format: 'json'
    sort: 'interestingness-desc'
    machine_tags: "pleiades:*=#{id}"

  $.getJSON flickr_rest_url, parameters, (data) ->
    $('<br/>').appendTo('.container')
    $('<img/>').attr('src',flickrURL(photo)).appendTo('.container') for photo in data.photos.photo

flickrSearch = (bbox) ->
  parameters =
    api_key: flickr_api_key
    method: 'flickr.photos.search'
    format: 'json'
    min_taken_date: '1800-01-01 00:00:00'
    extras: 'geo'
    # sort: 'interestingness-desc'
  
  if bboxIsPoint(bbox)
    parameters.lon = bbox[0]
    parameters.lat = bbox[1]
    parameters.radius = 0.5
  else
    parameters.bbox = bbox.join(',')

  $.getJSON flickr_rest_url, parameters, (data) ->
    $('<br/>').appendTo('.container')
    $('<img/>').attr('src',flickrURL(photo)).appendTo('.container') for photo in data.photos.photo[0..4]

displayConnection = (connection) ->
  flickrSearch(connection.bbox)

addConnection = (connection, length) ->
  $.getJSON pleiadesURL(connection), (result) ->
    hadrian_connections.push result
    # $('body').append "Added #{result.title} (#{result.id}): #{result.description}<br/>"
    $('#load-progress').attr('style',"width: #{(hadrian_connections.length / length)*100}%;")
    if hadrian_connections.length == length
      $('#load-progress-container').toggle()
      hadrian_connections = (hadrian_connection for hadrian_connection in hadrian_connections when hadrian_connection.title.match(/(milecastle|turret)/i))
      $('.container').append "Done. #{hadrian_connections.length} places.<br/>"
      hadrian_connections = hadrian_connections.sort(sortByLongitude)
      longitudes = _.flatten([item.bbox[0],item.bbox[2]] for item in hadrian_connections)
      latitudes = _.flatten([item.bbox[1],item.bbox[3]] for item in hadrian_connections)
      connections_bbox = [(Math.min longitudes...), (Math.min latitudes...), (Math.max longitudes...), (Math.max latitudes...)]
      # flickrMachineSearch(hadrian_connection.id) for hadrian_connection in hadrian_connections
      displayConnection(hadrian_connection) for hadrian_connection in hadrian_connections
      map_options =
        center: new google.maps.LatLng(-34.397, 150.644)
        zoom: 8
        mapTypeId: google.maps.MapTypeId.ROADMAP
      map = new google.maps.Map(document.getElementById("map_canvas"),map_options)
      map.fitBounds(new google.maps.LatLngBounds(new google.maps.LatLng(connections_bbox[1],connections_bbox[0]),new google.maps.LatLng(connections_bbox[3],connections_bbox[2])))
      route_polyline =
        path: (new google.maps.LatLng(item.bbox[1],item.bbox[0]) for item in hadrian_connections when bboxIsPoint(item.bbox))
        strokeColor: "#FF0000"
        strokeOpacity: 1.0
        strokeWeight: 2
      route_path = new google.maps.Polyline(route_polyline)
      route_path.setMap(map)

$(document).ready ->
  $.getJSON pleiadesURL(hadrian_id), (result) ->
    $('.container').append "<h2>#{result.title}</h2>"
    $('.container').append "<h3>#{result.description}</h3>"
    addConnection(connection, result.connectsWith.length) for connection in result.connectsWith

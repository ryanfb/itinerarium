# $ ?= require 'jquery' # For Node.js compatibility
# _ ?= require 'underscore'

hadrian_id = 91358
hadrian_connections = []

flickr_api_key = 'f6bca6b68d42d5a436054222be2f530e'
flickr_rest_url = 'http://api.flickr.com/services/rest/?jsoncallback=?'

instagram_client_id = '0bb344d5e9454a8a8ac70f0b715be3d8'
instagram_search_url = 'https://api.instagram.com/v1/media/search?'

google_maps_api_key = 'AIzaSyBoQNYbbHb-MEGa4_oq83_JCLt9cKfd4vg'
google_map = null
google_map_marker = null

pleiades_url = 'http://pleiades.stoa.org/places/'

itinerary_loaded = false

current_connection = 0

loadItinerary = ->
  unless itinerary_loaded
    $.getJSON pleiadesURL(hadrian_id), (result) ->
      $('.container').append "<h2>#{result.title}</h2>"
      $('.container').append "<h3>#{result.description}</h3>"
      addConnection(connection, result.connectsWith.length) for connection in result.connectsWith
      itinerary_loaded = true

davis_app = Davis ->
  this.get '/', (req) ->
    console.log("GET /")
    loadItinerary()
  this.get '/#/connection/:connection_id', (req) ->
    loadItinerary()
    current_connection = parseInt(req.params['connection_id'])
    $('#connections-select').val(current_connection)
    displayConnection(hadrian_connections[current_connection])
  this.get '/#/place/:place_id', (req) ->
    loadItinerary()
    console.log(req.params['place_id'])
    connection = _.find hadrian_connections, (connection) ->
      connection.id == req.params['place_id']
    console.log(connection)
    displayConnection(connection)

pleiadesURL = (id) ->
  pleiades_url + id + '/json'

sortByLongitude = (a, b) ->
  a.reprPoint[0] - b.reprPoint[0]

flickrURL = (photo) ->
  "http://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_q.jpg"

bboxIsPoint = (bbox) ->
  (bbox[0] == bbox[2]) && (bbox[1] == bbox[3])

flickrMachineSearch = (id, selector = '.container') ->
  parameters =
    api_key: flickr_api_key
    method: 'flickr.photos.search'
    format: 'json'
    sort: 'interestingness-desc'
    machine_tags: "pleiades:*=#{id}"

  $.getJSON flickr_rest_url, parameters, (data) ->
    if data.photos.photo.length == 0
      $('<p/>').text('No results found.').appendTo(selector)
    else
      $('<img/>').attr('src',flickrURL(photo)).appendTo(selector) for photo in data.photos.photo

instagramSearch = (lat, long, distance = 1000, selector = '.container') ->
  parameters =
    lat: lat
    lng: long
    client_id: instagram_client_id
    distance: distance

  $.getJSON instagram_search_url, parameters, (data) ->
    if data.data.length == 0
      $('<p/>').text('No results found.').appendTo(selector)
    else
      $('<img/>').attr('src',photo.images.thumbnail.url).appendTo(selector) for photo in data.data

flickrSearch = (bbox, selector = '.container') ->
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
    if data.photos.photo.length == 0
      $('<p/>').text('No results found.').appendTo(selector)
    else
      $('<img/>').attr('src',flickrURL(photo)).appendTo(selector) for photo in data.photos.photo

# http://www.movable-type.co.uk/scripts/latlong.html
calculateDistance = (lat1, lon1, lat2, lon2) ->
  R = 6371 # km
  dLat = (lat2-lat1) * Math.PI / 180
  dLon = (lon2-lon1) * Math.PI / 180
  lat1 = lat1 * Math.PI / 180
  lat2 = lat2 * Math.PI / 180

  a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  d = R * c

displayDistance = ->
  if current_connection != 0
    distance = calculateDistance(hadrian_connections[current_connection].reprPoint[1],hadrian_connections[current_connection].reprPoint[0],hadrian_connections[current_connection - 1].reprPoint[1],hadrian_connections[current_connection - 1].reprPoint[0])
    $('<em/>').text("#{distance.toFixed(2)}km from #{hadrian_connections[current_connection - 1].title}.").append($('<br/>')).appendTo('.connection-container')
  if current_connection != (hadrian_connections.length - 1)
    distance = calculateDistance(hadrian_connections[current_connection].reprPoint[1],hadrian_connections[current_connection].reprPoint[0],hadrian_connections[current_connection + 1].reprPoint[1],hadrian_connections[current_connection + 1].reprPoint[0])
    $('<em/>').text("#{distance.toFixed(2)}km to #{hadrian_connections[current_connection + 1].title}.").append($('<br/>')).appendTo('.connection-container')
  $('<br/>').appendTo('.connection-container')

displayPrevNextButtons = ->
  $('#prev-next-container').empty()
  $('<br/>').appendTo('#prev-next-container')
  $('<a/>').attr('id','prev-button').attr('class','btn btn-primary btn-lg').attr('role','button').attr('href',"#/connection/#{parseInt(current_connection) - 1}").text("Prev").appendTo('#prev-next-container')
  $('#prev-next-container').append(' ')
  $('<a/>').attr('id','next-button').attr('class','btn btn-primary btn-lg').attr('role','button').attr('href',"#/connection/#{parseInt(current_connection) + 1}").text("Next").appendTo('#prev-next-container')

  if current_connection == 0
    $('#prev-button').attr('disabled','disabled')
  else if current_connection == (hadrian_connections.length - 1)
    $('#next-button').attr('disabled','disabled')

displayConnectionMarker = (connection) ->
  marker_options =
    position: new google.maps.LatLng(connection.reprPoint[1], connection.reprPoint[0])
    map: google_map
    title: connection.title

  if google_map_marker != null
    google_map_marker.setMap(null)
    google_map_marker = null

  google_map_marker = new google.maps.Marker(marker_options)

displayConnection = (connection) ->
  displayConnectionMarker(connection)
  $('.connection-container').remove()
  $('<div/>').attr('class','connection-container').attr('id',"place-#{connection.id}").appendTo('.container')
  $('<h4/>').appendTo("#place-#{connection.id}")
  $('<a/>').attr('href',"#{pleiades_url}#{connection.id}").attr('target','_blank').text(connection.title).appendTo("#place-#{connection.id} h4")
  $('<p/>').text(connection.description).appendTo("#place-#{connection.id}")
  displayDistance()
  $('<div/>').attr('class','flickr-machine').appendTo("#place-#{connection.id}")
  $('<h5/>').text('Flickr Machine Tags:').appendTo("#place-#{connection.id} .flickr-machine")
  $('<br/>').appendTo("#place-#{connection.id}")
  $('<div/>').attr('class','flickr-geo').appendTo("#place-#{connection.id}")
  $('<h5/>').text('Flickr Geo Search:').appendTo("#place-#{connection.id} .flickr-geo")
  $('<br/>').appendTo("#place-#{connection.id}")
  $('<div/>').attr('class','instagram').appendTo("#place-#{connection.id}")
  $('<h5/>').text('Instagram:').appendTo("#place-#{connection.id} .instagram")

  flickrMachineSearch(connection.id, "#place-#{connection.id} .flickr-machine")
  flickrSearch(connection.bbox, "#place-#{connection.id} .flickr-geo")
  instagramSearch(connection.reprPoint[1], connection.reprPoint[0], 500, "#place-#{connection.id} .instagram")

  displayPrevNextButtons()

addConnectionToDropdown = (connection_index) ->
  connection = hadrian_connections[connection_index]
  $('<option/>').attr('value',connection_index).text(connection.title).appendTo('#connections-select')

createDropdown = (connections) ->
  $('<select/>').attr('class','form-control').attr('id','connections-select').appendTo('.container')
  addConnectionToDropdown(connection_index) for connection_index in [0...connections.length]
  $('#connections-select').change (event) ->
    Davis.location.assign(new Davis.Request("/#/connection/#{$('#connections-select').val()}"))


postConnectionsLoad = ->
  $('#load-progress-container').toggle()
  hadrian_connections = (hadrian_connection for hadrian_connection in hadrian_connections when hadrian_connection.title.match(/(milecastle|turret)/i))
  $('.container').append "Done. #{hadrian_connections.length} places.<br/>"
  hadrian_connections = hadrian_connections.sort(sortByLongitude)
  longitudes = _.flatten([item.bbox[0],item.bbox[2]] for item in hadrian_connections)
  latitudes = _.flatten([item.bbox[1],item.bbox[3]] for item in hadrian_connections)
  connections_bbox = [(Math.min longitudes...), (Math.min latitudes...), (Math.max longitudes...), (Math.max latitudes...)]
  createDropdown(hadrian_connections)
  $('<div/>').attr('id','prev-next-container').appendTo('.container')
  map_options =
    center: new google.maps.LatLng(-34.397, 150.644)
    zoom: 8
    mapTypeId: google.maps.MapTypeId.ROADMAP
  google_map = new google.maps.Map(document.getElementById("map_canvas"),map_options)
  google_map.fitBounds(new google.maps.LatLngBounds(new google.maps.LatLng(connections_bbox[1],connections_bbox[0]),new google.maps.LatLng(connections_bbox[3],connections_bbox[2])))
  route_polyline =
    path: (new google.maps.LatLng(item.bbox[1],item.bbox[0]) for item in hadrian_connections when bboxIsPoint(item.bbox))
    strokeColor: "#FF0000"
    strokeOpacity: 1.0
    strokeWeight: 2
  route_path = new google.maps.Polyline(route_polyline)
  route_path.setMap(google_map)
  if Davis.location.current() == '/'
    Davis.location.assign(new Davis.Request("/#/connection/0"))

addConnection = (connection, length) ->
  $.getJSON pleiadesURL(connection), (result) ->
    hadrian_connections.push result
    $('#load-progress').attr('style',"width: #{(hadrian_connections.length / length)*100}%;")
    if hadrian_connections.length == length
      postConnectionsLoad()

$(document).ready ->  
  davis_app.start()
  davis_app.lookupRoute('get', '/').run(new Davis.Request('/'))
# $ ?= require 'jquery' # For Node.js compatibility
# _ ?= require 'underscore'

itinerary_places = []
itinerary_connections = []
itinerary_url = null

known_itineraries = [
  {title: "Hadrian's Wall", path: "hadrian_full"},
  {title: "Hadrian's Wall (milecastles and turrets only)", path: "hadrian_partial"},
  {title: "Vicarello Beaker 1", path: "vicarello_1"},
  {title: "Vicarello Beaker 2", path: "vicarello_2"},
  {title: "Vicarello Beaker 3", path: "vicarello_3"},
  {title: "Vicarello Beaker 4", path: "vicarello_4"},]

flickr_api_key = 'f6bca6b68d42d5a436054222be2f530e'
flickr_rest_url = 'http://api.flickr.com/services/rest/?jsoncallback=?'

instagram_client_id = '0bb344d5e9454a8a8ac70f0b715be3d8'
instagram_search_url = 'https://api.instagram.com/v1/media/search?'

google_maps_api_key = 'AIzaSyBoQNYbbHb-MEGa4_oq83_JCLt9cKfd4vg'
google_map = null
google_map_marker = null
google_map_rectangle = null

pleiades_url = 'http://pleiades.stoa.org/places/'

itinerary_loaded = false

current_connection = 0

loadItinerary = ->
  unless itinerary_loaded
    itinerary_loaded = true
    $('#known-itinerary-list').remove()
    addConnection(connection, itinerary_places.length) for connection in itinerary_places

itineraryHandler = (req) ->
  if itinerary_loaded
    current_connection = parseInt(req.params['connection_id'])
    displayConnection(itinerary_connections[current_connection])
  else
    console.log(req.params['itinerary'])
    itinerary_places = req.params['itinerary'].split(',')
    current_connection = parseInt(req.params['connection_id'])
    $('.container').append "<br/>"
    loadItinerary()

itineraryURLHandler = (req) ->
  if itinerary_loaded
    current_connection = parseInt(req.params['connection_id'])
    displayConnection(itinerary_connections[current_connection])
  else
    itinerary_url = unescape(req.params['itinerary_url'])
    console.log(itinerary_url)
    $.getJSON itinerary_url, (result) ->
      $('.container').append "<h2>#{result.title}</h2>"
      $('.container').append "<h3>#{result.description}</h3>"
      itinerary_places = result.connectsWith
      current_connection = parseInt(req.params['connection_id'])
      loadItinerary()

davis_app = Davis ->
  this.get '/', (req) ->
    unless window.location.hash
      console.log("No itinerary.")
      $('<div/>').attr('id','known-itinerary-list').appendTo('.container')
      for itinerary in known_itineraries
        $('<a/>').attr('href',"#/itinerary_url/#{encodeURIComponent(window.location.pathname)}itineraries%2F#{itinerary.path}.json").text(itinerary.title).appendTo('#known-itinerary-list')
        $('<br/>').appendTo('#known-itinerary-list')
  this.get "#{window.location.pathname}#/itinerary/:itinerary", (req) ->
    Davis.location.assign(new Davis.Request("#{window.location.pathname}#/itinerary/#{req.params['itinerary']}/connection/0"))
  this.get "#{window.location.pathname}#/itinerary_url/:itinerary_url", (req) ->
    Davis.location.assign(new Davis.Request("#{window.location.pathname}#/itinerary_url/#{req.params['itinerary_url']}/connection/0"))
  this.get '#/itinerary/:itinerary/connection/:connection_id', itineraryHandler
  this.get "#{window.location.pathname}#/itinerary/:itinerary/connection/:connection_id", itineraryHandler
  this.get '#/itinerary_url/:itinerary_url/connection/:connection_id', itineraryURLHandler
  this.get "#{window.location.pathname}#/itinerary_url/:itinerary_url/connection/:connection_id", itineraryURLHandler

pleiadesURL = (id) ->
  if window.location.hostname == 'ryanfb.github.io'
    'http://ryanfb.github.io/pleiades-geojson/geojson/' + id + '.geojson'
  else
    pleiades_url + id + '/json'

sortByLongitude = (a, b) ->
  a.reprPoint[0] - b.reprPoint[0]

flickrThumbURL = (photo) ->
  "http://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_q.jpg"

flickrPageURL = (photo) ->
  "http://www.flickr.com/photos/#{photo.owner}/#{photo.id}"

bboxIsPoint = (bbox) ->
  (bbox[0] == bbox[2]) && (bbox[1] == bbox[3])

connectionURL = (connection_id) ->
  if itinerary_url
    location.href.replace(location.hash,"") + "#/itinerary_url/#{encodeURIComponent(itinerary_url)}/connection/#{connection_id}"
  else
    location.href.replace(location.hash,"") + "#/itinerary/#{itinerary_places.join()}/connection/#{connection_id}"

flickrMachineSearch = (id, selector = '.container') ->
  ajaxSpinner().appendTo(selector)
  parameters =
    api_key: flickr_api_key
    method: 'flickr.photos.search'
    format: 'json'
    sort: 'interestingness-desc'
    machine_tags: "pleiades:*=#{id}"

  $.getJSON flickr_rest_url, parameters, (data) ->
    $("#{selector} .spinner").remove()
    if data.photos.photo.length == 0
      $('<p/>').text('No results found.').appendTo(selector)
    else
      $('<a/>').attr('href',flickrPageURL(photo)).attr('target','_blank').append($('<img/>').attr('src',flickrThumbURL(photo))).appendTo(selector) for photo in data.photos.photo

ajaxSpinner = ->
  $('<img/>').attr('src','spinner.gif').attr('class','spinner')

instagramSearch = (lat, long, distance = 1000, selector = '.container') ->
  ajaxSpinner().appendTo(selector)
  parameters =
    lat: lat
    lng: long
    client_id: instagram_client_id
    distance: distance

  $.ajax
    dataType: 'jsonp'
    data: parameters
    url: instagram_search_url
    type: 'GET'
    crossDomain: true
    success: (data) ->
      $("#{selector} .spinner").remove()
      if data.data.length == 0
        $('<p/>').text('No results found.').appendTo(selector)
      else
        $('<a/>').attr('href',photo.link).attr('target','_blank').append($('<img/>').attr('src',photo.images.thumbnail.url)).appendTo(selector) for photo in data.data

flickrSearch = (bbox, selector = '.container') ->
  ajaxSpinner().appendTo(selector)
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
    $("#{selector} .spinner").remove()
    if data.photos.photo.length == 0
      $('<p/>').text('No results found.').appendTo(selector)
    else
      $('<a/>').attr('href',flickrPageURL(photo)).attr('target','_blank').append($('<img/>').attr('src',flickrThumbURL(photo))).appendTo(selector) for photo in data.photos.photo

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

calculateDistanceBetweenConnections = (index1, index2) ->
  total_distance = 0.0
  (total_distance += calculateDistance(itinerary_connections[index].reprPoint[1], itinerary_connections[index].reprPoint[0], itinerary_connections[index+1].reprPoint[1], itinerary_connections[index+1].reprPoint[0])) for index in [index1...index2]
  return total_distance

displayDistance = ->
  if current_connection != 0
    distance = calculateDistance(itinerary_connections[current_connection].reprPoint[1],itinerary_connections[current_connection].reprPoint[0],itinerary_connections[current_connection - 1].reprPoint[1],itinerary_connections[current_connection - 1].reprPoint[0])
    $('<em/>').text("#{distance.toFixed(2)}km from #{itinerary_connections[current_connection - 1].title}.").append($('<br/>')).appendTo('.connection-container')
  if current_connection != (itinerary_connections.length - 1)
    distance = calculateDistance(itinerary_connections[current_connection].reprPoint[1],itinerary_connections[current_connection].reprPoint[0],itinerary_connections[current_connection + 1].reprPoint[1],itinerary_connections[current_connection + 1].reprPoint[0])
    $('<em/>').text("#{distance.toFixed(2)}km to #{itinerary_connections[current_connection + 1].title}.").append($('<br/>')).appendTo('.connection-container')
  $('<br/>').appendTo('.connection-container')

displayPrevNextButtons = ->
  $('#prev-next-container').empty()
  $('<br/>').appendTo('#prev-next-container')
  $('<a/>').attr('id','prev-button').attr('class','btn btn-primary btn-lg').attr('role','button').attr('href',connectionURL(parseInt(current_connection) - 1)).text("Prev").appendTo('#prev-next-container')
  $('#prev-next-container').append(' ')
  $('<a/>').attr('id','next-button').attr('class','btn btn-primary btn-lg').attr('role','button').attr('href',connectionURL(parseInt(current_connection) + 1)).text("Next").appendTo('#prev-next-container')

  # console.log("Length: #{itinerary_connections.length}")
  if current_connection == 0
    $('#prev-button').attr('disabled','disabled')
  if current_connection == (itinerary_connections.length - 1)
    $('#next-button').attr('disabled','disabled')

displayConnectionMarker = (connection) ->
  for marker in [google_map_marker, google_map_rectangle]
    if marker != null
      marker.setMap(null)
      marker = null

  unless bboxIsPoint(connection.bbox)
    rectangle_options =
      strokeWeight: 2
      strokeColor: '#FF0000'
      strokeOpacity: 0.8
      fillColor: '#FF0000'
      fillOpacity: 0.35
      map: google_map
      bounds: new google.maps.LatLngBounds(new google.maps.LatLng(connection.bbox[1],connection.bbox[0]),new google.maps.LatLng(connection.bbox[3],connection.bbox[2]))
    google_map_rectangle = new google.maps.Rectangle(rectangle_options)

  marker_options =
    position: new google.maps.LatLng(connection.reprPoint[1], connection.reprPoint[0])
    map: google_map
    title: connection.title
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

  $('#connections-progress').attr('style',"width: #{(current_connection / (itinerary_connections.length - 1))*100}%")
  $('#distance-progress').attr('style',"width: #{(calculateDistanceBetweenConnections(0, current_connection) / calculateDistanceBetweenConnections(0, itinerary_connections.length - 1))*100}%")
  displayPrevNextButtons()

  $('#connections-select').val(current_connection)

addConnectionToDropdown = (connection_index) ->
  connection = itinerary_connections[connection_index]
  $('<option/>').attr('value',connection_index).text(connection.title).appendTo('#connections-select')

createDropdown = (connections) ->
  $('<select/>').attr('class','form-control').attr('id','connections-select').appendTo('.container')
  addConnectionToDropdown(connection_index) for connection_index in [0...connections.length]
  $('#connections-select').change (event) ->
    Davis.location.assign(new Davis.Request(connectionURL($('#connections-select').val())))

createProgressBars = ->
  $('<div/>').attr('id','progress-bar-container').appendTo('.container')
  $('<div/>').attr('class','progress').append($('<div/>').attr('class','progress-bar progress-bar-info').attr('role','progressbar').attr('style','width: 0%').attr('id','connections-progress').text('Places visited')).appendTo('#progress-bar-container')
  $('<div/>').attr('class','progress').append($('<div/>').attr('class','progress-bar progress-bar-warning').attr('role','progressbar').attr('style','width: 0%').attr('id','distance-progress').text('Distance traveled')).appendTo('#progress-bar-container')

postConnectionsLoad = ->
  $('#load-progress-container').toggle()
  unordered_itinerary_connections = itinerary_connections.slice(0)
  itinerary_connections = []
  for place in itinerary_places
    matching_connection = _.find(unordered_itinerary_connections, (connection) -> parseInt(connection.id) == parseInt(place))
    unless matching_connection.bbox == null
      itinerary_connections.push(matching_connection) 
  longitudes = _.flatten([item.bbox[0],item.bbox[2]] for item in itinerary_connections)
  latitudes = _.flatten([item.bbox[1],item.bbox[3]] for item in itinerary_connections)
  connections_bbox = [(Math.min longitudes...), (Math.min latitudes...), (Math.max longitudes...), (Math.max latitudes...)]
  createProgressBars()
  createDropdown(itinerary_connections)
  $('<div/>').attr('id','prev-next-container').appendTo('.container')
  map_options =
    center: new google.maps.LatLng(-34.397, 150.644)
    zoom: 8
    mapTypeId: google.maps.MapTypeId.ROADMAP
  google_map = new google.maps.Map(document.getElementById("map_canvas"),map_options)
  google_map.fitBounds(new google.maps.LatLngBounds(new google.maps.LatLng(connections_bbox[1],connections_bbox[0]),new google.maps.LatLng(connections_bbox[3],connections_bbox[2])))
  route_polyline =
    path: (new google.maps.LatLng(item.bbox[1],item.bbox[0]) for item in itinerary_connections when bboxIsPoint(item.bbox))
    strokeColor: "#FF0000"
    strokeOpacity: 1.0
    strokeWeight: 2
  route_path = new google.maps.Polyline(route_polyline)
  route_path.setMap(google_map)

  displayConnection(itinerary_connections[current_connection])

addConnection = (connection, length) ->
  $.getJSON pleiadesURL(connection), (result) ->
    itinerary_connections.push result
    $('#load-progress').attr('style',"width: #{(itinerary_connections.length / length)*100}%;")
    if itinerary_connections.length == length
      postConnectionsLoad()

$(document).ready ->  
  davis_app.start()
  if window.location.hash
    Davis.location.assign(new Davis.Request("#{window.location.pathname}#{window.location.hash}"))
  else
    davis_app.lookupRoute('get', '/').run(new Davis.Request('/'))
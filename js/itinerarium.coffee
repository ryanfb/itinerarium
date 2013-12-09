# $ ?= require 'jquery' # For Node.js compatibility
# _ ?= require 'underscore'

hadrian_id = 91358
hadrian_connections = []

flickr_api_key = 'f6bca6b68d42d5a436054222be2f530e'
flickr_rest_url = 'http://api.flickr.com/services/rest/?jsoncallback=?'

instagram_client_id = '0bb344d5e9454a8a8ac70f0b715be3d8'
instagram_search_url = 'https://api.instagram.com/v1/media/search?'

google_maps_api_key = 'AIzaSyBoQNYbbHb-MEGa4_oq83_JCLt9cKfd4vg'

pleiades_url = 'http://pleiades.stoa.org/places/'

itinerary_loaded = false

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

displayConnection = (connection) ->
  $('.connection-container').remove()
  $('#connections_dropdown_button').text(connection.title)
  $('<div/>').attr('class','connection-container').attr('id',"place-#{connection.id}").appendTo('.container')
  $('<h4/>').appendTo("#place-#{connection.id}")
  $('<a/>').attr('href',"#{pleiades_url}#{connection.id}").attr('target','_blank').text(connection.title).appendTo("#place-#{connection.id} h4")
  $('<p/>').text(connection.description).appendTo("#place-#{connection.id}")
  $('<div/>').attr('class','flickr-machine').appendTo("#place-#{connection.id}")
  $('<p/>').text('Flickr Machine Tags:').appendTo("#place-#{connection.id} .flickr-machine")
  $('<br/>').appendTo("#place-#{connection.id}")
  $('<div/>').attr('class','flickr-geo').appendTo("#place-#{connection.id}")
  $('<p/>').text('Flickr Geo Search:').appendTo("#place-#{connection.id} .flickr-geo")
  $('<br/>').appendTo("#place-#{connection.id}")
  $('<div/>').attr('class','instagram').appendTo("#place-#{connection.id}")
  $('<p/>').text('Instagram:').appendTo("#place-#{connection.id} .instagram")

  flickrMachineSearch(connection.id, "#place-#{connection.id} .flickr-machine")
  flickrSearch(connection.bbox, "#place-#{connection.id} .flickr-geo")
  instagramSearch(connection.reprPoint[1], connection.reprPoint[0], 500, "#place-#{connection.id} .instagram")

addConnectionToDropdown = (connection) ->
  $('<li/>').attr('role','presentation').attr('id',"li-#{connection.id}").appendTo('#connections_dropdown > ul')
  $('<a/>').attr('role','menuitem').attr('tabindex','-1').attr('href',"#/place/#{connection.id}").text(connection.title).appendTo("#li-#{connection.id}")

createDropdown = (connections) ->
  $('<div/>').attr('class','dropdown').attr('id','connections_dropdown').appendTo('.container')
  $('<button/>').attr('class','btn btn-default dropdown-toggle').attr('style','width: 100%').attr('type','button').attr('id','connections_dropdown_button').attr('data-toggle','dropdown').appendTo('#connections_dropdown')
  $('<span/>').attr('class','caret').appendTo('#connections_dropdown > button')
  $('<ul/>').attr('class','dropdown-menu').attr('role','menu').attr('aria-labelledby','connections_dropdown_button').appendTo('#connections_dropdown')
  addConnectionToDropdown(connection) for connection in connections

addConnection = (connection, length) ->
  $.getJSON pleiadesURL(connection), (result) ->
    hadrian_connections.push result
    $('#load-progress').attr('style',"width: #{(hadrian_connections.length / length)*100}%;")
    if hadrian_connections.length == length
      $('#load-progress-container').toggle()
      hadrian_connections = (hadrian_connection for hadrian_connection in hadrian_connections when hadrian_connection.title.match(/(milecastle|turret)/i))
      $('.container').append "Done. #{hadrian_connections.length} places.<br/>"
      hadrian_connections = hadrian_connections.sort(sortByLongitude)
      longitudes = _.flatten([item.bbox[0],item.bbox[2]] for item in hadrian_connections)
      latitudes = _.flatten([item.bbox[1],item.bbox[3]] for item in hadrian_connections)
      connections_bbox = [(Math.min longitudes...), (Math.min latitudes...), (Math.max longitudes...), (Math.max latitudes...)]
      createDropdown(hadrian_connections)
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
      if Davis.location.current() == '/'
        Davis.location.assign(new Davis.Request("/#/place/#{hadrian_connections[0].id}"));

$(document).ready ->  
  davis_app.start()
  davis_app.lookupRoute('get', '/').run(new Davis.Request('/'))
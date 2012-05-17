$ ?= require 'jquery' # For Node.js compatibility

hadrian_id = 91358
hadrian_connections = []

flickr_api_key = 'f6bca6b68d42d5a436054222be2f530e'

pleiadesURL = (id) ->
  'http://pleiades.stoa.org/places/' + id + '/json'

sortByLongitude = (a, b) ->
  a.reprPoint[0] - b.reprPoint[0]

bboxIsPoint = (bbox) ->
  (bbox[0] == bbox[2]) && (bbox[1] == bbox[3])

flickrSearch = (bbox) ->
  parameters =
    api_key: flickr_api_key
    method: 'flickr.photos.search'
    format: 'json'
    bbox: bbox.join(',')
    min_taken_date: '1800-01-01 00:00:00'
    sort: 'interestingness-desc'

  $.getJSON 'http://api.flickr.com/services/rest/?jsoncallback=?', parameters, (data) ->
    $('body').append "Success."

displayConnection = (connection) ->
  flickrSearch(connection.bbox)

addConnection = (connection, length) ->
  $.getJSON pleiadesURL(connection), (result) ->
    hadrian_connections.push result
    $('body').append "Added #{result.title} (#{result.id}): #{result.description}<br/>"
    if hadrian_connections.length == length
      $('body').append "Done.<br/>"
      hadrian_connections = hadrian_connections.sort(sortByLongitude)
      displayConnection(hadrian_connections[0])

$(document).ready ->
  $.getJSON pleiadesURL(hadrian_id), (result) ->
    addConnection(connection, result.connectsWith.length) for connection in result.connectsWith

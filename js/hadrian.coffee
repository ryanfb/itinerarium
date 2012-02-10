$ ?= require 'jquery' # For Node.js compatibility

yqlURL = (url) ->
  'http://query.yahooapis.com/v1/public/yql?q=' + encodeURIComponent('select * from html where url="' + url + '"') + '&format=json'

pleiadesURL = (url) ->
  'http://pleiades.stoa.org/places/' + url + '/json'

$(document).ready ->
  hadrian = 91358

  $.getJSON yqlURL(pleiadesURL(hadrian)), (data) ->
    alert "Hadrian."

fs = require 'fs'
util = require 'util'
http = require 'http'
init = require './init'
under = require 'underscore'
request = require 'request'
FormData = require 'form-data'

exports.MediaTransport = new JS.Class({
  initialize: (localHost, cloudHost) ->
    this.localHost = localHost
    this.cloudHost = cloudHost

  upload: (mediaId) ->
    this.transfer(mediaId, this.localHost, this.cloudHost)

  download: (mediaId) ->
    this.transfer(mediaId, this.cloudHost, this.localHost)

  transfer: (mediaId, srcHost, destHost) ->
    util.log("Transporting media[" + mediaId + "]")
    downloadUrl = 'http://' + srcHost+ '/download/media/' + mediaId
    uploadUrl = 'http://' + destHost+ '/upload/media/' + mediaId
    transfer(downloadUrl, uploadUrl)
})

transfer = (downloadUrl, uploadUrl) ->
  requestWithRedirect downloadUrl,  (response) ->
    form = new FormData()
    form.append('file', response)
    form.getLength (err, length) ->
      util.log("Content-Length: " + length)
      put = request.put(uploadUrl)
      put.setHeader('Content-Length', length)
      put._form = form

requestWithRedirect = (url, callback) ->
  http.get url, (response) ->
    if response.statusCode == 302
      location = sanitizeRedirect(response.headers.location)
      requestWithRedirect(location, callback)
    else if response.statusCode == 200
      callback(response)
    else
      util.log('Failed to request url: ' + url)

sanitizeRedirect = (url) ->
  url.split("?")[0]

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

  upload: (mediaId, callback) ->
    this.transfer(mediaId, this.localHost, this.cloudHost, callback)

  download: (mediaId, callback) ->
    this.transfer(mediaId, this.cloudHost, this.localHost, callback)

  # Check if downloaded file exists
  checkDownload: (mediaId, callback) ->
    util.log("Checking existence for media[" + mediaId + "]")
    downloadUrl = 'http://' + this.cloudHost + '/download/media/' + mediaId
    # This is a quick test for now
    http.get downloadUrl, (response) ->
      if response.statusCode  == 302
        callback()
      response.on 'error', (err) ->
        util.log("Failed to check download: " +  err)

  transfer: (mediaId, srcHost, destHost, callback) ->
    util.log("Transporting media[" + mediaId + "]")
    downloadUrl = 'http://' + srcHost+ '/download/media/' + mediaId
    uploadUrl = 'http://' + destHost+ '/upload/media/' + mediaId
    transfer(downloadUrl, uploadUrl, callback)
})

transfer = (downloadUrl, uploadUrl, callback) ->
  requestWithRedirect downloadUrl,  (response) ->
    form = new FormData()
    form.append('file', response)
    form.getLength (err, length) ->
      util.log("Content-Length: " + length)
      put = request.put uploadUrl, (error, response, body) ->
        if !error and response.statusCode == 200
          util.log("Done uploading to: " + uploadUrl)
          callback()
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

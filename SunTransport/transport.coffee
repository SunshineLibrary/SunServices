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
    http.get(downloadUrl, (response) ->
      status = response.statusCode
      if status == 302
        callback()
      else
        util.log("Check download failed with status code: " +  status)
    ).on 'error', (err) ->
      util.log("Failed to check download: " +  err)

  transfer: (mediaId, srcHost, destHost, callback) ->
    self = this
    util.log("Transporting media[" + mediaId + "]")
    downloadUrl = 'http://' + srcHost+ '/download/media/' + mediaId
    uploadUrl = 'http://' + destHost+ '/upload/media/' + mediaId
    transfer downloadUrl, uploadUrl, callback, (progress) ->
      self.onProgress(mediaId, progress)

  onProgress: (mediaId, progress) ->
    util.log("Transfering media[" + mediaId + "]: " + progress)
})

transfer = (downloadUrl, uploadUrl, callback, updateProgress) ->
  requestWithRedirect downloadUrl,  (response) ->
    form = new FormData()
    form.append('file', response)
    form.getLength (err, length) ->
      util.log("Content-Length: " + length)
      put = request.put uploadUrl, (error, response, body) ->
        if !error and response.statusCode == 200
          util.log("Done uploading to: " + uploadUrl)
          updateProgress(100)
          callback()
      put.setHeader('Content-Length', length)
      put._form = form

      bytesReceived = 0
      lastUpdateTime = 0
      response.on 'data', (chunk) ->
        bytesReceived += chunk.length
        uptime = process.uptime()
        if bytesReceived == length
          updateProgress(99)
        else if uptime - lastUpdateTime > 5
          progress = Math.floor(bytesReceived * 100 / length)
          lastUpdateTime = uptime
          updateProgress(progress)

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

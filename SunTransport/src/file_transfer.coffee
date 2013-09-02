util = require 'util'
http = require 'http'
request = require 'request'
FormData = require 'form-data'

# Transfer file from one server to another through HTTP Get and HTTP Post
exports.FileTransferHandler = FileTransferHandler = () ->
  this.retryCounts = {}
  return this

# Implements task handler interface to handle fileTransfer tasks
#
# Sample file transfer task:
# {
#   id: 12345
#   , action: 'fileTransfer'
#   , params: {
#     auth: 'Auth token depending on applicaiton (optional)'
#     , downloadUrl: http://cloud.sunshine-library.org/media/1a2s3d4f
#     , uploadUrl: http://localhost/media/1a2s3d4f
#   }
# }
FileTransferHandler.prototype.handleTask = (task) ->
  self = this
  params = task.params
  self.transfer params.downloadUrl, params.uploadUrl, params.auth, (success)->
    if success
      task.done()
    else
      self.retry(task)

# Check if the requested resource exist
FileTransferHandler.prototype.transfer = (downloadUrl, uploadUrl, auth, callback) ->
  self = this
  util.log("Starting Transfer: " + downloadUrl)
  transfer downloadUrl, uploadUrl, auth, callback, (progress) ->
    self.onProgress(downloadUrl, progress)

FileTransferHandler.prototype.onProgress = (downloadUrl, progress) ->
  util.log("Transfer: " + downloadUrl + '[' + progress + ']')

# Retry download if not successful
FileTransferHandler.prototype.retry = (task) ->
  retryCount = this.retryCounts[task.id] || 0
  if retryCount < 5
    task.retry(60)
    this.retryCounts[task.id] = retryCount + 1
  else
    task.done()

transfer = (downloadUrl, uploadUrl, auth, callback, updateProgress) ->
  requestWithRedirect downloadUrl,  (response) ->
    if not response
      return callback(false)
    form = new FormData()
    form.append('auth', auth) if auth
    form.append('file', response)
    form.getLength (err, length) ->
      util.log("Content-Length: " + length)
      put = request.put uploadUrl, (error, response, body) ->
        if !error and response.statusCode == 200
          util.log("Done uploading to: " + uploadUrl)
          updateProgress(100)
          callback(true)
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
  http.get(url, (response) ->
    if response.statusCode == 302
      location = sanitizeRedirect(response.headers.location)
      requestWithRedirect(location, callback)
    else if response.statusCode == 200
      callback(response)
    else
      util.log('Failed to request url: ' + url)
      callback()
  ).on('error', (e) ->
    util.log("Http error: " + e.message)
    callback()
  )

sanitizeRedirect = (url) ->
  url.split("?")[0]

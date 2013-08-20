util = require 'util'
http = require 'http'
request = require 'request'
FormData = require 'form-data'

###########################################################################
#                                                                         #
# Transfer file from one server to another through HTTP Get and HTTP Post #
#                                                                         #
###########################################################################
exports.FileTransferTask = FileTransferTask = () ->
  this.retryCounts = {}
  return this

###########################################################################
#                                                                         #
# Implements task handler interface                                       #
#                                                                         #
###########################################################################
FileTransferTask.prototype.handleTask = (task) ->
  self = this
  params = task.params
  self.checkDownload(params.downloadUrl, (success) ->
      if success
        self.transfer params.downloadUrl, params.uploadUrl, ->
          task.done()
      else
        self.retry(task)

###########################################################################
#                                                                         #
# Check if the requested file exists                                      #
#                                                                         #
###########################################################################
FileTransferTask.prototype.checkDownload = (downloadUrl, callback) ->
  util.log("Checking existence: " + downloadUrl)
  http.get(downloadUrl, (response) ->
    status = response.statusCode
    if status == 302
      callback(true)
    else
      util.log("Check download failed with status code: " +  status)
      callback(false)
  ).on 'error', (err) ->
    util.log("Failed to check download: " +  err)
    callback(false)

FileTransferTask.prototype.transfer = (downloadUrl, uploadUrl, callback) ->
  self = this
  transfer downloadUrl, uploadUrl, callback, (progress) ->
    self.onProgress(downloadUrl, progress)

FileTransferTask.prototype.onProgress = (downloadUrl, progress) ->
  util.log("Transfer: " + downloadUrl + '[' + progress + ']')


###########################################################################
#                                                                         #
# Retry download if not successful                                        #
#                                                                         #
###########################################################################
FileTransferTask.prototype.retry = (task) ->
  retryCount = this.retryCountss[task.id] || 0
  if retryCount < 5
    task.retry(60)
    this.retryCounts[task.id] = retryCount + 1
  else
    task.done()

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

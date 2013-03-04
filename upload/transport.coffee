fs = require 'fs'
util = require 'util'
path = require 'path'
init = require './init'
under = require 'underscore'
request = require 'request'

exports.MediaTransport = new JS.Class({
  initialize: (localHost, cloudHost) ->
    this.localHost = localHost
    this.cloudHost = cloudHost

  upload: (mediaId) ->
    this.transfer(mediaId, this.localHost, this.cloudHost)

  download: (mediaId) ->
    this.transfer(mediaId, this.cloudHost, this.localHost)

  transfer: (mediaId, srcHost, destHost) ->
    downloadUrl = 'http://' + srcHost+ '/download/media/' + mediaId
    uploadUrl = 'http://' + destHost+ '/upload/media/' + mediaId
    request(downloadUrl).pipe(request.put(uploadUrl))
    # download(downloadUrl, (filepath) ->
    #   upload(uploadUrl, {'uuid': mediaId}, filepath, true)
    # )
})

upload = (url, params, filepath, deleteOnComplete) ->
  fs.stat filepath, (err, stats) ->
    data = under.clone(params)
    data['file'] = rest.file(filepath, null, stats.size, null, null)

    rest.post(url, {multipart: true, data: data})
      .on 'complete', (data) ->
        util.log("Uploaded file: " + filepath)
        fs.unlink(filepath) if deleteOnComplete


download = (url, callback) ->
  safeMkdir ->
    http.get(url, (response) ->
      util.log(url)
      debugger
      filepath = getFilePathFromUri(response.request.uri)

      response.on 'data', (chunk) ->
        writeToFile(filepath, chunk)

      response.on 'end', ->
        callback(filepath)

      util.log('Downloading ' + uri + ' to ' + filepath)
    ).on 'error', (err) ->
      util.log('Download failed: ' + e.message)

writeToPath = (filepath, chunk) ->
  fs.appendFile(filepath, chunk, (err) ->
    util.log('Error writing to file: ' + filepath)
  )


TMP_PATH = path.resolve(__dirname, 'tmp')

safeMkdir = (callback) ->
  fs.exists TMP_PATH , (exists) ->
    if exists
      callback()
    else
      fs.mkdir(TMP_PATH, '0755', callback)

getFilePathFromUri = (uri) ->
  path.resolve(TMP_PATH, uri.path.split('/').pop())

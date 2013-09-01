util = require 'util'
http = require 'http'
request = require 'request'


# Post data as json across servers
exports.JsonPostHandler = JsonPostHandler = () ->
  this.retryCounts = {}
  return this

# Implements task handler interface to handle jsonPost tasks
#
# Sample json post task:
# {
#   id: 12345
#   , action: 'jsonPost'
#   , params: {
#     auth: 'Auth token depending on application (optional'
#     , postUrl: http://cloud.sunshine-library.org/pieces
#     , payload: {
#       uuid: '12d389d819f12983a'
#       , title: 'New Piece'
#       ...
#     }
#   }
# }
JsonPostHandler.prototype.handleTask = (task) ->
  self = this
  params = task.params
  json = {payload: params.payload}
  json.auth = params.auth if params.auth
  request(
    { method:'POST'
    , uri: params.postUrl
    , json: json
    }
  , (error, response, body) ->
    if error
      util.log(error)
      task.done()
    else if response.statusCode == 200
      task.done()
    else
      self.retry(task)
  )

# Retry post if not successful
JsonPostHandler.prototype.retry = (task) ->
  retryCount = this.retryCounts[task.id] || 0
  if retryCount < 5
    task.retry(60)
    this.retryCounts[task.id] = retryCount + 1
  else
    task.done()

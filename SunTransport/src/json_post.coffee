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
#     postUrl: http://cloud.sunshine-library.org/pieces
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
  request(
    { method:'POST'
    , uri: params.postUrl
    , json:
      { payload: params.payload }
    }
  , (error, response, body) ->
    if reponse.statusCode == 201
      task.done()
    else
      self.retry(task)
  )

# Retry post if not successful
JsonPostHandler.prototype.retry = (task) ->
  retryCount = this.retryCountss[task.id] || 0
  if retryCount < 5
    task.retry(60)
    this.retryCounts[task.id] = retryCount + 1
  else
    task.done()


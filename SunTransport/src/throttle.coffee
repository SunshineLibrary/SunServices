util = require 'util'
events = require 'events'

exports.Throttler = Throttler = (concurrency) ->
  this.queue = queue = []
  numRunning = 0

  doneFn = (throttle) ->
    ->
      throttle.emit 'done'

  nextFn = (throttle) ->
    ->
      throttle.emit 'next'

  done = doneFn(this)
  next = nextFn(this)

  this.on 'next', ->
    if queue.length > 0 and numRunning < concurrency
      numRunning++
      callback = queue.shift()
      callback(done)
    util.log('[Throttler] Running: ' + numRunning + "; Pending: " + queue.length + "; Allowed: " + concurrency)

  this.on 'done', ->
    numRunning--
    next()

  return this

util.inherits(Throttler, events.EventEmitter)

Throttler.prototype.add = (callback) ->
  this.queue.push(callback)
  this.emit 'next'

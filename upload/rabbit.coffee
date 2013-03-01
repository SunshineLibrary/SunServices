clc     = require 'cli-color'
init    = require './init.js'
amqp    = require 'amqp'
util    = require 'util'
events  = require 'events'

exports.RabbitMessenger = new JS.Class(events.EventEmitter, {
  initialize: (connectionParams, listenQueueName, listenExchangeName, publishExchangeName) ->
    this.connectionParams = connectionParams
    this.listenQueueName = listenQueueName
    this.listenExchangeName = listenExchangeName
    this.publishExchangeName = publishExchangeName

    this.pendingMessages = []
    this.connection = null
    this.listenQueue = null
    this.publishExchange = null

  start: ->
    self = this
    util.log('Connecting to RabbitMQ server...')
    this.connection = amqp.createConnection(this.connectionParams)
    this.connection.on('ready', -> self.onConnected())

  onConnected: ->
    self = this
    util.log('Declaring listen queue: ' + this.listenQueueName)
    queueParams = {durable: true, exclusive: false, autoDelete: false}

    this.connection.queue(this.listenQueueName, queueParams, (queue) ->
      util.log(clc.green('Declared queue: ' + self.listenQueueName))
      util.log('Binding ' + self.listenQueueName + ' to ' + self.listenExchangeName)
      queue.bind(self.listenExchangeName, '')
      queue.on('error', (error) ->
        util.log(clc.red('Failed to bind to exchange: ' + self.listenExchangeName))
      )
      queue.on('queueBindOk', ->
        util.log(clc.green('Bound ' + self.listenQueueName + ' to exchange: ' + self.listenExchangeName))
        self.listenQueue = queue
        self.bindListener()
      )
    )

    util.log('Declaring exchange: ' + self.publishExchangeName)
    exchangeParams = {durable: true, type: 'fanout', autoDelete: false}
    exchange = this.connection.exchange(this.publishExchangeName, exchangeParams, (exchange) ->
      util.log(clc.green('Declared exchange: ' + self.publishExchangeName))
      self.publishExchange = exchange
      self.publish message for message in self.pendingMessages
      self.pendingMessages = []
    )

    exchange.on('error', (error) ->
      util.log clc.red('Failed to create exchange: ' + self.listenExchangeName)
    )

  bindListener: ->
    self = this
    this.listenQueue.subscribe (message, headers, deliveryInfo) ->
      util.log 'Received a message...'
      self.emit('message', message, headers, deliveryInfo)

  send: (message) ->
    if this.publishExchange == null
      util.log("Exchange not connected, pending count:" + this.pendingMessages.length)
      this.pendingMessages.push message
    else
      this.publish message

  publish: (message) ->
      util.log("Sending message: "+ this.stringify(message))
      this.publishExchange.publish "", message

  stringify: (message) ->
    if message instanceof String
      message
    else
      JSON.stringify message
})

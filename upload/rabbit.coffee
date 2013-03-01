clc     = require 'cli-color'
init    = require './init.js'
amqp    = require 'amqp'
util    = require 'util'
config  = require './config'

JS.require('JS.Class')

exports.RabbitMessenger = new JS.Class({
    initialize: (listenQueueName, listenExchangeName, publishExchangeName) ->
        this.listenQueueName = listenQueueName
        this.listenExchangeName = listenExchangeName
        this.publishExchangeName = publishExchangeName

        this.connection = null
        this.listenQueue = null
        this.publishExchange = null

        this.isListening = false
        this.pendingMessages = []

    start: ->
        self = this
        util.log('Connecting to RabbitMQ server...')
        this.connection = amqp.createConnection(config.connection_params)
        this.connection.on('ready', -> self.onConnected())

    onConnected: ->
        self = this
        util.log('Declaring listen queue: ' + this.listenQueueName)
        queueParams = {durable: true, exclusive: false, autoDelete: false}

        this.connection.queue(this.listenQueueName, queueParams, (queue) ->
            util.log(clc.green('Declared queue: ' + self.listenExchangeName))
            util.log('Binding ' + self.listenQueueName + ' to ' + self.listenExchangeName)
            queue.bind(self.listenExchangeName, '')
            queue.on('error', (error) ->
                util.log(clc.red('Failed to bind to exchange: ' + self.listenExchangeName))
            )
            queue.on('queueBindOk', ->
                util.log(clc.green('Bound ' + self.listenQueueName + ' to exchange: ' + self.listenExchangeName))
                self.listenQueue = queue
            )
        )

        util.log('Declaring exchange: ' + self.listenExchangeName)
        exchangeParams = {durable: true, type: 'fanout', autoDelete: false}
        exchange = this.connection.exchange(this.publishExchangeName, exchangeParams, (exchange) ->
            util.log(clc.green('Declared exchange: ' + self.listenExchangeName))
            self.publishExchange = exchange
        )

        exchange.on('error', (error) ->
            util.log(clc.red('Failed to create exchange: ' + self.listenExchangeName))
        )

    setListener: (listener) ->
        this.listener = listener
        if this.listenQueue == null
            return
})

#!/usr/bin/env coffee
rabbit = require './rabbit'
config = require './local_config'
transport = require './transport'
LocalService = require './local_service'

messenger = new rabbit.RabbitMessenger(
  config.connectionParams, config.queueName, config.exchangeName, config.pubExchangeName)

transport = new transport.MediaTransport('localhost', '10.8.0.2')

models = require('./models').models

localService = new LocalService(config.pool, models, messenger, transport)

localService.start()

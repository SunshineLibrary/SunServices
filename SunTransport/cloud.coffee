util = require 'util'
under = require 'underscore'

rabbit = require './rabbit'
database = require './database'
config= require './cloud_config'

messenger = new rabbit.RabbitMessenger(
  config.connectionParams, config.queueName, config.exchangeName, config.pubExchangeName)



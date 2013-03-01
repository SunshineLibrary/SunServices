config  = require './config'
rabbit = require './rabbit'

queueName = 'local.' + config.hostname
exchangeName = 'cloud.updates.broadcast'
pubExchangeName = 'local.updates.publish'

messenger = new rabbit.RabbitMessenger(queueName, exchangeName, pubExchangeName)
messenger.start()

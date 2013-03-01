rabbit = require './rabbit'

connectionParams = {
  host: '42.121.108.196'
  , login: 'cloud_server'
  , password: 'gf84hvf893'
  , vhost: '/sunshine'
}

queueName = 'cloud.publisher'
exchangeName = 'local.updates.publish'
pubExchangeName = 'cloud.updates.broadcast'

messenger = new rabbit.RabbitMessenger(connectionParams, queueName, exchangeName, pubExchangeName)

messenger.on 'message', (message) ->
  # console.log(key + " " + value) for key, value of message
  console.log JSON.stringify(message)
messenger.start()

rabbit = require './rabbit'
message = require './message'

connectionParams = {
    host: '42.121.108.196'
    , login: 'local_server'
    , password: '8he90zhn3o'
    , vhost: '/sunshine'
}

queueName = 'local.' + require('os').hostname()
exchangeName = 'cloud.updates.broadcast'
pubExchangeName = 'local.updates.publish'

messenger = new rabbit.RabbitMessenger(connectionParams, queueName, exchangeName, pubExchangeName)
messenger.start()

builder1 = new message.DataMessageBuilder('pieces', 'uuid', ['body', 'title'])
builder2 = new message.DataMessageBuilder('folder_pieces', ['folder_id', 'piece_id'], ['type'])

console.log(builder1)
console.log(builder2)

messenger.send(builder1.newDeleteMessage({uuid: '1', title: 'Title Delete', body: 'Body Delete'}))
messenger.send(builder1.newUpdateMessage({uuid: '2', title: 'Title Update', body: 'Body Update'}))
messenger.send(builder1.newPublishMessage({uuid: '3', title: 'Title Publish', body: 'Body Publish'}))

messenger.send(builder2.newDeleteMessage({folder_id: '1', piece_id: '1', type: 'Delete'}))
messenger.send(builder2.newUpdateMessage({folder_id: '2', piece_id: '2', type: 'Update'}))
messenger.send(builder2.newPublishMessage({folder_id: '3', piece_id: '2', type: 'Publish'}))

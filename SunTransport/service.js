config = require('./config')
TaskService = require('warpgate').TaskService
JsonPostHandler = require('./lib/json_post').JsonPostHandler
FileTransferHandler = require('./lib/file_transfer').FileTransferHandler

service = new TaskService(config.connectionParams, config.role, config.hostname)

service.setHandler('jsonPost', new JsonPostHandler())
service.setHandler('fileTransfer', new FileTransferHandler())

service.start()

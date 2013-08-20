SunServices
===========

Supporting services for the infrastructure

SunTransport
============
Transport data and files between local and cloud servers

WarpGate
=======
node.js service for sending HTTP payloads asynchronously. Includes ruby gem for use in Rails projects.

Gem: WarpGate

``
WarpGate.post(type: :json, role: 'local', url: 'http://localhost/pieces', payload: @piece.to_json)
WarpGate.post(type: :file, role: 'local', url: 'htpp://localhost/medium/upload', source: 'http://10.8.9.0.2/system/files/medium/1.mp4')
WarpGate.put(type: :json, role: 'local', url: 'http://localhost/pieces/123456789', payload: @piece.to_json)
``

``
class ItemsController < ActionController
  def update
    authenticate_post_boy
    payload = WarpGate.unload(params)
    item = Item.where(uuid: payload[:uuid]).first
    item && item.update_attributes(updates)
  end
end
``

``
WarpGate.setup do |config|

  config.role = 'cloud'

  config.salt = 'Sunshine Library Rocks'

  config.environment = :production

  config.messenger.host = '127.0.0.1'

  config.messenger.port = '4023'

  config.messenger.vhost = '/'

  config.messenger.username = ''

  config.messenger.password = ''

end
``

Module: WarpGate

``
messenger = Messenger.new('127.0.0.1', '/', 'username', 'password')

gate = WarpGate.new(messenger, 'role')
gate.start()
``

``
Messenger.onRequest(function(request, done) {
    // { source: 'cloud', role: 'local', path: '', payload: '', type: 'json'}
    done()
})
``

``
Transport.sendFile(srcUrl, destUrl, callback)
``

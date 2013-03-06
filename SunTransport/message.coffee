init = require './init.js'
under = require 'underscore'

hostname = require('os').hostname()

exports.DataMessageBuilder = new JS.Class({
  initialize: (type, key, fields) ->
    if key instanceof Array
      this.key = key
    else
      this.key = [key]

    this.fields = fields
    this.type = type

  newPublishMessage: (data) ->
    {
      source: hostname
      , type: this.type
      , action: 'publish'
      , id: this.getId(data)
      , content: this.getContent(data)
    }

  newUpdateMessage: (data) ->
    {
      source: hostname
      , type: this.type
      , action: 'update'
      , id: this.getId(data)
      , content: this.getContent(data)
    }

  newDeleteMessage: (data) ->
    {
      source: hostname
      , type: this.type
      , action: 'delete'
      , id: this.getId(data)
    }

  getId: (data) ->
    under.pick(data, this.key)

  getContent: (data) ->
    under.pick(data, this.fields)

})

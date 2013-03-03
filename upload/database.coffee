clc     = require 'cli-color'
init   = require './init.js'
util   = require 'util'
events = require 'events'

QUERY_CONDITION = 'sync_status = 1 OR sync_status = 3 OR sync_status = 4'

exports.Table = new JS.Class({
  initialize: (pool, tableName, fields) ->
    this.pool = pool
    this.fields = fields
    this.tableName = tableName

    this.insertQuery = 'INSERT INTO ' + tableName + join(fields) + ' VALUES '
    this.selectQuery = 'SELECT * FROM ' + tableName + ' WHERE ' + QUERY_CONDITION

  insert: (row) ->
    this.execute(this.insertQuery + joinValues(row, this.fields), 'insert')

  query: () ->
    this.execute(this.selectQuery, 'query')

  update: () ->
    this.execute(

  execute: (statement, type) ->
    emitter = new events.EventEmitter()
    this.pool.getConnection (err, connection) ->
      connection.query(statement)
        .on 'error', (err) ->
          util.log(clc.red(err))
        .on 'result', (result) ->
          console.log("Result" + result)
          emitter.emit('row', result) if type == 'query'
        .on 'end', ->
          connection.end()
    return emitter
})

exports.TableMonitor = new JS.Class(events.EventEmitter, {
  initialize: (pool, table, interval=600000) ->
    this.pool = pool
    this.table = table
    this

  start: ->
    this.pollData()

  pollData: ->
    self = this
    this.table.query()
      .on 'row', (row) ->
        self.processRow(row)

  processRow: (row) ->
    for key, value of row
      if value instanceof Buffer
        row[key] = value.toString()

    if row.sync_status == 1
      this.emit 'publish', row
    else if row.sync_status == 3
      this.emit 'update', row
    else if row.sync_status == 4
      this.emit 'delete', row
})

joinValues = (input, fields) ->
  result = []
  for f in fields
    if input[f]?
      result.push escapeString(input[f])
    else
      result.push null
  return join(result)

escapeString = (value) ->
  if value? and typeof value == 'string'
    return '"' + value + '"'
  else
    return null

join = (arr) ->
  if arr.length == 0
    return '()'
  str = '('
  for a in arr
    str += a + ','
  return str.substr(0, str.length - 1) + ')'

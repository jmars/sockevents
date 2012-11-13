Socket = require 'sockjs-client'
{EventEmitter2} = require 'EventEmitter2'

module.exports = ->
  if SERVER?
    Socket = new WebSocket "ws://#{window.location.hostname}:3000"
  else
    Socket = new SockJS "http://#{window.location.hostname}:3000/socket"
  class ProxyEmitter extends EventEmitter2
    constructor: ->
      super
    on: (event, args...) ->
      Socket.send JSON.stringify ['subscribe', event]
      super
    once: (event, args...) ->
      if event isnt 'socket.open'
        Socket.send JSON.stringify ['subscribe', event]
      super
    off: (event, callback) ->
      Socket.send JSON.stringify ['unsubscribe', event]
  emitter = new ProxyEmitter
    wildcard: true
    delimiter: '.'
    maxListeners: 20
  emitter.onAny ->
    Socket.send JSON.stringify ['propagate', @event].concat arguments
  Socket.onopen = ->
    emitter.emit 'socket.open'
  Socket.onclose = ->
    emitter.emit 'socket.close'
  Socket.onmessage = (e) ->
    [command, args] = JSON.parse e.data
    emitter[command].apply emitter, args
  return emitter
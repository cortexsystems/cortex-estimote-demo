class View
  constructor: ->
    @_nearByUsers = 0

    window.Cortex.app.onData 'com.estimote.data.user_count', @_onData

  prepare: (offer) =>
    container = document.getElementById('container')
    offer (done) =>
      container.innerHTML = "<h1>#{@_nearByUsers}</h1>"
      setTimeout done, 5000

  _onData: (data) =>
    if not data? or data.length == 0
      return

    @_nearByUsers = data[0]?.count

module.exports = View

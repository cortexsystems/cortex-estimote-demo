promise = require 'promise'

class View
  constructor: ->
    @_activeViews = 0
    @_maxActiveViews = 3
    @_nearByUsers = 0

    @_images = {}
    @_urls = []
    @_idx = 0

    window.Cortex.app.onData 'com.estimote.data.user-count.images', @_onImages
    window.Cortex.app.onData 'com.estimote.data.user-count', @_onData

  prepare: (offer) =>
    offer()

  _onData: (data) =>
    if not data? or data.length == 0
      return

    @_nearByUsers = data[0]?.count
    if @_nearByUsers > 0 and @_activeViews < @_maxActiveViews
      viewCount = @_maxActiveViews - @_activeViews
      for i in [1..viewCount]
        @_offer()

  _offer: ->
    if @_urls.length == 0
      console.warn "_offer returns, no images to render."
      return

    if @_idx >= @_urls.length
      @_idx = 0

    url = @_urls[@_idx]
    @_idx += 1
    if not (url of @_images)
      console.warn "_offer returns, bad image url #{url}"
      return

    console.warn "Submitting view for #{url}"

    node = @_images[url].node
    duration = @_images[url].duration

    view = (done) =>
      console.warn "Rendering view for #{url}"
      @_activeViews -= 1
      container = document.getElementById 'container'
      while container.firstChild?
        container.removeChild container.firstChild
      container.appendChild node
      setTimeout done, duration

    onDiscard = =>
      @_activeViews -= 1

    window.Cortex.scheduler.requestFocus view, {
      onDiscard: onDiscard,
      contentLabel: url}

    @_activeViews += 1

  _createDOMNode: (row) ->
    new promise (resolve, reject) ->
      opts =
        cache:
          mode: 'normal'
          ttl:  7 * 24 * 60 * 60 * 1000

      window.Cortex.net.get row?.url, opts
        .then ->
          img = new Image()
          img.onload = ->
            resolve img
          img.onerror = reject
          img.src = row.url
        .catch reject

  _onImages: (data) =>
    if not data? or data.length == 0
      return

    @_images = {}
    @_urls = []
    for image in data
      do (image) =>
        @_createDOMNode image
          .then (node) =>
            console.warn "Image node created for #{image.url}"
            @_urls.push image.url
            @_images[image.url] =
              node: node
              duration: image.duration
          .catch (e) ->
            console.error "Failed to create DOM node", e

module.exports = View

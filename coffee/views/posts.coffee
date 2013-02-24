define [
  "jquery"
  "underscore"
  "models/post"
  "views/base/collection_view"
  "views/post"
  "views/dialog_delete"
  "lib/websocket_handler"
  "lib/utils"
  "templates/preloader"
], ($, _, Post, CollectionView, PostView, DialogDeleteView, WebSocketHandler,
    utils, preloader) ->
  "use strict"

  class PostsView extends CollectionView

    _(@prototype).extend WebSocketHandler

    container: "#main"
    itemView: PostView

    SCROLL_THRESHOLD: 100

    getView: (model) ->
      new @itemView model: model, dialog: @subview "dialog"

    initialize: (options) ->
      super options
      if options?.pageble?
        @pageble = options.pageble
      else
        @pageble = true
      @subscribeEvent "!ws:new_message", @onNewPost

    afterInitialize: ->
      super
      dialog = new DialogDeleteView()
      @subview "dialog", dialog
      @fetch(true).done => @initWebSocket()

    fetch: (first = false) ->
      return if @$(".preloader").length
      unless first
        if @collection.hasPages() then @collection.incPage() else return

      @$el.append utils.renderTemplate preloader
      d = @collection.fetch()
      d.always =>
        @$(".preloader").remove()
      d

    afterRender: ->
      super
      $(window).scroll @onScroll if @pageble

    dispose: ->
      $(window).off "scroll", @onScroll
      @closeWebSocket()
      super

    onScroll: =>
      position = $(window).scrollTop() + $(window).height()
      height = $(document).height()
      @fetch() if height - position < @SCROLL_THRESHOLD

    onNewPost: (postData) ->
      post = new Post postData
      @collection.add post, at: 0

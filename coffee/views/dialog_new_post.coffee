define [
  "jquery"
  "underscore"
  "views/base/dialog"
  "lib/utils"
  "templates/dialog_new_post"
], ($, _, DialogView, utils, template) ->
  "use strict"

  class DialogNewPostView extends DialogView

    container: "body"
    template: template
    autoRender: true
    events:
      "click #post-form-submit": "post"
      "keypress #post-form-text": "keypress"

    afterRender: ->
      super
      @modal.on "shown", =>
        $("#post-form-text").focus()

    post: ->
      return unless utils.isLogged()

      textarea = $("#post-form-text")
      [tags, clubs, text] = @parsePost textarea.val()
      submit = $("#post-form-submit").prop("disabled", true)
      cancel = $("#post-form-cancel").prop("disabled", true)
      i = submit.children("i").toggleClass("icon-refresh icon-spin")

      d = utils.post "post", {tags, clubs, text}
      d.always ->
        submit.prop("disabled", false)
        cancel.prop("disabled", false)
        i.toggleClass("icon-refresh icon-spin")
      d.done (data) =>
        textarea.val("")
        @hide()
        utils.gotoUrl "/p/#{data.id}"

    parsePost: (text) ->
      ###Obtain possible tags, clubs and remaining text from post.
      Return array of tags, clubs and text. Reference:
      <https://github.com/stiletto/bnw/blob/master/bnw_xmpp/handlers.py>
      ###
      # XXX: Yeap, that's too silly to parse like that. But it works.
      matches = text.match ///
        ^
        (?:([\*!]\S+)\s+)?  # Tag/club 1-5
        (?:([\*!]\S+)\s+)?
        (?:([\*!]\S+)\s+)?
        (?:([\*!]\S+)\s+)?
        (?:([\*!]\S+)\s)?
        ([^]*)              # Post text
        $
      ///
      text = _(matches).last()
      matches = matches[1...-1]  # Without all match and text
      tags = (tag[1..] for tag in matches when tag? and tag[0] == "*")
      tags = if tags.length then tags.join "," else undefined
      clubs = (club[1..] for club in matches when club? and club[0] == "!")
      clubs = if clubs.length then clubs.join "," else undefined
      [tags, clubs, text]

    keypress: (e) ->
      if e.ctrlKey and (e.keyCode == 13 or e.keyCode == 10)
        # FIXME: Should we use some instance variable for check
        # is we already sending message?
        unless $("#post-form-submit").prop("disabled")
          @post()

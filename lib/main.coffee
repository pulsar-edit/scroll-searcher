ScrollSearch = require './scroll-searcher-view'
ScrollMarker = require './scroll-marker'
{CompositeDisposable, Emitter} = require 'event-kit'
{TextEditor} = require 'atom'

class Main
  editor: null
  subscriptions: null
  model: null
  scrollMarker: null
  previousHeight: null
  previousScrollHeight: null
  activated: false
  config:
    color:
      type: 'color'
      default: 'red'
      title: 'Set the color of scroll-searchers'
      description: 'Pick a color for scroll-searchers from the color box'
    size:
      type: 'integer'
      default:0
      title: 'Set the size of scroll-searchers'
      enum: [0, 1, 2]
      description: 'Pick a size for scroll-searchers from the drop-down list'
    scrOpacity:
      type: 'integer'
      default: 65
      title: 'Scrollbar Opacity'
      minimum: 0
      maximum: 80
      description: 'Set the scrollbar opacity for better visibility'
  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @emitter = new Emitter
    @previousHeight = 0
    @subs = new CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @subs.add atom.commands.add 'atom-workspace',
      'scroll-searcher:toggle': => @toggle()
      'core:close': => @deactivate()

  deactivate: ->
    @subscriptions.dispose()
    @subs.dispose()
    if @scrollMarker
      @scrollMarker.destroy()
    @emitter.emit 'did-deacitvate'
    @activated = false

  isPackageActive: (findPackage) =>
    if findPackage.name == 'find-and-replace'
      @initialize()

  initialize: ->
    if @activated
      @model = atom.packages.getActivePackage('find-and-replace')
      if @model
        @scrollMarker = new ScrollMarker(@model,this)
      else
        return
      @subscriptions.add atom.workspace.observePaneItems(@on)
      @subscriptions.add atom.workspace.observeActivePaneItem(@markOnEditorChange)

  toggle: ->
    if not @activated
      @activated = true
      @subscriptions = new CompositeDisposable
      @subscriptions.add atom.packages.onDidActivatePackage(@isPackageActive)
      @initialize()
    else
      @activated = false
      @subscriptions.dispose()
      if @scrollMarker?
        @scrollMarker.destroy()
      @emitter.emit 'did-deacitvate'

  onDidDeactivate: (callback) ->
    @emitter.on 'did-deacitvate', callback

  markOnHeightUpdate: =>
    if @editor?
      if @editor instanceof TextEditor
        if @editor.displayBuffer.height != @previousHeight
          @previousHeight = @editor.displayBuffer.height
          @scrollMarker.updateMarkers()
      else
        return

  markOnEditorChange: (editor) =>
    @editor = editor
    if @editor instanceof TextEditor
      @model = atom.packages.getActivePackage('find-and-replace')
      if @model
        @scrollMarker.updateModel(@model)
        @scrollMarker.updateMarkers()
        if @verticalScrollbar
          @verticalScrollbar.style.opacity = atom.config.get('scroll-searcher.scrOpacity')
    else
      return

  on: (editor) =>
    if editor instanceof TextEditor
      if @scrollSearcherExists(editor)
        @subscriptions.add atom.views.getView(editor).component.presenter.onDidUpdateState(@markOnHeightUpdate.bind(this))
        scrollSearch = new ScrollSearch(this)
        @editorView = atom.views.getView(editor).component.rootElement?.firstChild
        @editorView.appendChild(scrollSearch.getElement())
        @verticalScrollbar = atom.views.getView(editor).component.rootElement?.querySelector('.vertical-scrollbar')
        @verticalScrollbar.style.opacity = "0.65"


  scrollSearcherExists: (editor) ->
    @scrollView = atom.views.getView(editor).rootElement?.querySelector('.scroll-searcher')
    if @scrollView?
      return false
    else
      return true

module.exports = new Main()

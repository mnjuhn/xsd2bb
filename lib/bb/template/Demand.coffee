window.aurora.Demand.defaults
  dt: 1
  knob: 1
  start_time: 0

window.aurora.Demand::resolve_references = (deferred, object_with_id) ->
  self = @
  deferred.push ->
    @set 'link', object_with_id.link[@get('link_id')]
    throw "Demand instance can't find link for obj id == #{link_id}" unless link
    link.set 'demand', self

window.aurora.Demand::encode_references = ->
  @set('link_id', @get('link').id)
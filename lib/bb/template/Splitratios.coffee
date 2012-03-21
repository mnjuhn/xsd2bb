window.aurora.Splitratios.defaults
  dt: 1
  start_time: 0

window.aurora.Splitratios::resolve_references = (deferred, object_with_id) ->
  deferred.push =>
    node_id = @get('node_id')
    node = object_with_id.node[node_id]
    @set 'node', node
    throw "splitratios instance can't find node for obj id == #{node_id}" unless node
    node.set 'splitratios', @

window.aurora.Splitratios::encode_references = ->
  @set 'node_id', @get('node').id
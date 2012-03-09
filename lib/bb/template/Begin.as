package aurora {

public dynamic class Begin {
  public function resolve_references(deferred:Array, object_with_id:Object) {
    deferred.push(function() {
      node = object_with_id.node[node_id] as Node;
      if (!node) {
        throw("Begin instance can't find node for obj id == " + node_id);
      }
    });
  }
  
  public function encode_references() {
    node_id = node.id;
  }
  
  public var node : Node;
}

}

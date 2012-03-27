package aurora {

public dynamic class Splitratios {
  public function Splitratios() {
    dt = 1;
    start_time = 0;
  }

  public function resolve_references(deferred:Array, object_with_id:Object) {
    var self = this;
    deferred.push(function() {
      node = object_with_id.node[node_id] as Node;
      if (!node) {
        throw("Splitratios instance can't find node for obj id == " + node_id);
      }
      node.splitratios = self;
    });
  }
  
  public function encode_references() {
    node_id = node.id;
  }
  
  public var node : Node;
}

}

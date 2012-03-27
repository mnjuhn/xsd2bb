package aurora {

public dynamic class Od {
  public function resolve_references(deferred:Array, object_with_id:Object) {
    deferred.push(function() {
      begin_node = object_with_id.node[begin] as Node;
      if (!begin_node) {
        throw("Od instance can't find node for obj id == " + begin); // throw something?
      }
      end_node = object_with_id.node[end] as Node;
      if (!end_node) {
        throw("Od instance can't find node for obj id == " + end);
      }
    });
  }
  
  public function encode_references() {
    begin = begin_node.id;
    end = end_node.id;
  }
  
  public function Od() {
    pathlist = new PathList();
  }
  
  public var begin_node : Node;
  public var end_node : Node;
}

}

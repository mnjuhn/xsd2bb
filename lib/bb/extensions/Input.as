package aurora {

public dynamic class Input {
  public function resolve_references(deferred:Array, object_with_id:Object) {
    deferred.push(function() {
      link = object_with_id.link[link_id] as Link;
      if (!link) {
        throw("Input instance can't find link for obj id == " + link_id);
      }
    });
  }
  
  public function encode_references() {
    link_id = link.id;
  }
  
  public var link : Link;
}

}

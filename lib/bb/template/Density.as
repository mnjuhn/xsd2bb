 package aurora {

public dynamic class Density {
  public function resolve_references(deferred:Array, object_with_id:Object) {
    var self = this;
    deferred.push(function() {
      link = object_with_id.link[link_id] as Link;
      if (!link) {
        throw("Density instance can't find link for obj id == " + link_id);
      }
      link.density = self;
    });
  }
  
  public function encode_references() {
    link_id = link.id;
  }
  
  public var link : Link;
}

}


package aurora {

public dynamic class Capacity {

  public function Capacity() {
    dt = 1;
    start_time = 0;
  }

  public function resolve_references(deferred:Array, object_with_id:Object) {
    var self = this;
    deferred.push(function() {
      link = object_with_id.link[link_id] as Link;
      if (!link) {
        throw("Capacity instance can't find link for obj id == " + link_id);
      }
      link.capacity = self;
    });
  }
  
  public function encode_references() {
    link_id = link.id;
  }
  
  public var link : Link;

}
}

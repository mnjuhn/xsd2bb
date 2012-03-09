package aurora {

public dynamic class Demand {

  public function Demand() {
    dt = 1;
    knob = 1;
    start_time = 0;
  }
  
  public function resolve_references(deferred:Array, object_with_id:Object) {
    var self = this;
    deferred.push(function() {
      link = object_with_id.link[link_id] as Link;
      if (!link) {
        throw("Demand instance can't find link for obj id == " + link_id);
      }
      link.demand = self;
    });
  }
  
  public function encode_references() {
    link_id = link.id;
  }
  
  public var link : Link;

}
}

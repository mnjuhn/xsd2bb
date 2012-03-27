package aurora {

public dynamic class Controller {
  public function Controller() {
    parameters = {};
    planlist = new PlanList();
    plansequence = new PlanSequence();
  }

  public function get display_point() {
    if (!display_position) {
      display_position = new Display_position();
      var p:Point = new Point();
      display_position.point.push(p);
      
      var pos_elt;
      if (link) {
        pos_elt = link.begin.node;
      }
      else if (node) {
        pos_elt = node;
      }
      else if (network) {
        pos_elt = network;
      }
      
      if (pos_elt && pos_elt.position &&
          pos_elt.position.point && pos_elt.position.point[0]) {
        var elt_pt:Point = pos_elt.position.point[0];
        p.lat = elt_pt.lat;
        p.lng = elt_pt.lng;
      }
      else {
        p.lat = 0;
        p.lng = 0;
      }
    }

    return display_position.point[0];
  }

  public function get display_lat() {return display_point.lat};
  public function get display_lng() {return display_point.lng};

  public function set display_lat(lat) {display_point.lat = lat};
  public function set display_lng(lng) {display_point.lng = lng};

  public function resolve_references(deferred:Array, object_with_id:Object) {
    deferred.push(function() {
      node = object_with_id.node[node_id] as Node;
      link = object_with_id.link[link_id] as Link;
      network = object_with_id.network[network_id] as Network;

      if (!node && !link && !network) {
        throw("Controller instance can't find node, link, or network for obj ids " +
          [node_id, link_id, network_id].join(", "));
      }
    });
  }
  
  public function encode_references() {
    if (node) node_id = node.id;
    if (link) link_id = link.id;
    if (network) network_id = network.id;
  }
  
  public var node : Node;
  public var link : Link;
  public var network : Network;
}

}

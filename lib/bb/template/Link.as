package aurora {

public dynamic class Link {
  public var capacity : Capacity;
  public var demand : Demand;
  public var density : Density;

  public function Link() {
    type = "ST";
    lanes = 1;
    lane_offset = 0;
    record = true; // default per GG request, 31Oct2011
    qmax = new Qmax();
    fd = new Fd();
    dynamics = new Dynamics();
  }

  // return links with the same begin and end as this link
  public function get parallel_links() {
    var begin_node = begin.node;
    var end_node = end.node;

    var a = [];

    for each (var output:Output in begin_node.outputs.output) {
      var link2 = output.link;
      if (link2 != this && link2.end.node == end_node) {
        a.push(link2);
      }
    }

    return a;
  }
}
}

package aurora {

public dynamic class Node {
  public var splitratios : Splitratios;
  public var signal : Signal;
  
  public function get terminal():Boolean {
    return type == "T";
  }
  
  public function get signalized():Boolean {
    return type == "S";
  }
  
  // Return array [ {link:.., index:...}, ...] with one entry
  // for each input that goes from other_node to this node.
  public function input_indexes(other_node:Node) {
    var idx = 0;
    var a = [];
    for each (var input in inputs.input) {
      var link:Link = input.link;
      if (link.begin.node == other_node) {
        a.push({
          link: link,
          index: idx
        });
      }
      idx += 1;
    }
    return a;
  }
  
  // Return array [ {link:.., index:...}, ...] with one entry
  // for each output that goes from this node to other_node.
  public function output_indexes(other_node:Node) {
    var idx = 0;
    var a = [];
    for each (var output in outputs.output) {
      var link:Link = output.link;
      if (link.end.node == other_node) {
        a.push({
          link: link,
          index: idx
        });
      }
      idx += 1;
    }
    return a;
  }
}

}

package aurora {

public dynamic class Signal {
  public function Signal() {
    phase = [];
  }

  public function resolve_references(deferred:Array, object_with_id:Object) {
    var s:Signal = this;
    deferred.push(function() {
      node = object_with_id.node[node_id] as Node;
      if (!node) {
        throw("Signal instance can't find node for obj id == " + node_id);
      }
      node.signal = s;
    });
  }
  
  public function encode_references() {
    node_id = node.id;
  }
  
  public function phase_with_nema(nema:int) {
    for each (var ph:Phase in phase) {
      if (ph.nema == nema) return ph;
    }
    return null;
  }
  
  public function calc_phase_row_col() {
    var ph:Phase;
    
    for each (ph in phase) {
      if (ph.nema <= 4) ph.row = 0;
      else ph.row = 1;

      ph.column = (ph.nema-1)%4;
    }
    
    for each (ph in phase) {
      if (ph.lag) {
        if (ph.nema % 2 == 1) {
          var alt_ph = phase_with_nema(ph.nema + 1);
          ph.column += 1;
          alt_ph.column -= 1;
        }
        else {
          trace("phase cannot have lag=true and nema=" + ph.nema);
        }
      }
    }
  }

  public var node : Node;
}

}

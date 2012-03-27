package aurora {
public dynamic class Scenario {

  public static function from_xml(xml:XML):Scenario {
      var object_with_id = {
        network: {},
        node: {},
        link: {},
        path: {},
        sensor: {}
      };
      var sc = Scenario.from_xml1(xml, object_with_id);
      sc.object_with_id = object_with_id;
      
      // populate per-link and per-node profiles from the global profile sets,
      // for easier manipulation while in memory. See encode_references() for
      // the inverse operation.
      
      if (sc.demandprofileset) {
        for each (var demand in sc.demandprofileset.demand) {
          demand.link.demand = demand;
        }
        sc.demandprofileset.demand = [];
      }
      
      if (sc.capacityprofileset) {
        for each (var capacity in sc.capacityprofileset.capacity) {
          capacity.link.capacity = capacity;
        }
        sc.capacityprofileset.capacity = [];
      }
      
      if (sc.initialdensityprofile) {
        for each (var density in sc.initialdensityprofile.density) {
          density.link.density = density;
        }
        sc.initialdensityprofile.density = [];
      }
      
      if (sc.splitratioprofileset) {
        for each (var splitratios in sc.splitratioprofileset.splitratios) {
          splitratios.node.splitratios = splitratios;
        }
        sc.splitratioprofileset.splitratios = [];
      }
      
      return sc;
  }
  
  public function Scenario() {
      schemaVersion = SchemaVersion;
      object_with_id = {
        network: {},
        node: {},
        link: {},
        path: {},
        sensor: {}
      };
      settings = new Settings();
      network = new Network();
  }
  
  public function network_with_id(id:String):Network {
    return object_with_id.network[id] as Network;
  }
  
  public function node_with_id(id:String):Node {
    return object_with_id.node[id] as Node;
  }
  
  public function link_with_id(id:String):Link {
    return object_with_id.link[id] as Link;
  }
  
  public function set_network_with_id(id:String, network:Network) {
    if (network) {
      object_with_id.network[id] = network;
    }
    else {
      delete object_with_id.network[id];
    }
  }
  
  public function set_node_with_id(id:String, node:Node) {
    if (node) {
      object_with_id.node[id] = node;
    }
    else {
      delete object_with_id.node[id];
    }
  }
  
  public function set_link_with_id(id:String, link:Link) {
    if (link) {
      object_with_id.link[id] = link;
    }
    else {
      delete object_with_id.link[id];
    }
  }
  
  public function stampSchemaVersion() {
    schemaVersion = SchemaVersion;
  }
  
  public function encode_references() {
    if (demandprofileset && demandprofileset.demand) {
      demandprofileset.demand = [];
    }
    
    if (capacityprofileset && capacityprofileset.capacity) {
      capacityprofileset.capacity = [];
    }
    
    if (initialdensityprofile && initialdensityprofile.density) {
      initialdensityprofile.density = [];
    }
    
    if (splitratioprofileset && splitratioprofileset.splitratios) {
      splitratioprofileset.splitratios = [];
    }
    
    if (network && network.linklist && network.linklist.link) {
      for each (var link:Link in network.linklist.link) {
        if (link.demand) {
          if (!demandprofileset) {
            demandprofileset = new DemandProfileSet();
          }
          if (!demandprofileset.demand) {
            demandprofileset.demand = [];
          }
          demandprofileset.demand.push(link.demand);
        }
        
        if (link.capacity) {
          if (!capacityprofileset) {
            capacityprofileset = new CapacityProfileSet();
          }
          if (!capacityprofileset.capacity) {
            capacityprofileset.capacity = [];
          }
          capacityprofileset.capacity.push(link.capacity);
        }
        
        if (link.density) {
          if (!initialdensityprofile) {
            initialdensityprofile = new InitialDensityProfile ();
          }
          if (!initialdensityprofile.density) {
            initialdensityprofile.density = [];
          }
          initialdensityprofile.density.push(link.density);
        }
      }
    }

    if (network && network.nodelist && network.nodelist.node) {
      for each (var node:Node in network.nodelist.node) {
        if (node.splitratios) {
          if (!splitratioprofileset) {
            splitratioprofileset = new SplitRatioProfileSet();
          }
          if (!splitratioprofileset.splitratios) {
            splitratioprofileset.splitratios = [];
          }
          splitratioprofileset.splitratios.push(node.splitratios);
        }
      }
    }
  }
  
  public var object_with_id : Object;
}

}

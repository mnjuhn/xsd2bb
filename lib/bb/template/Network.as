package aurora {

public dynamic class Network {

  public function Network() {
    nodelist = new NodeList();
    linklist = new LinkList();
    networklist = new NetworkList();
    odlist = new ODList();
    sensorlist = new SensorList();
    signallist = new SignalList();
    monitorlist = new MonitorList();
    description = new Description();
    position = new Position();
    position.point.push(new Point());
    
    ml_control = false;
    q_control = false;
    dt = 300;
  }
  
  public function get description_text():String {
    return description.text;
  }

  public function set description_text(s:String) {
    description.text = s;
  }

}
}

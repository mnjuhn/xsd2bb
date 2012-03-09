package aurora {

public dynamic class Sensor {
  public function get point() {
    if (!position.point[0]) {
      position.point.push(new Point());
    }
    return position.point[0];
  }

  public function get display_point() {
    if (display_position) {
      var p:Point = display_position.point[0];
      if (!p) {
        p = new Point();
        p.lat = lat;
        p.lng = lng;
        display_position.point.push(p);
      }
      return p;
    }
    else {
      return point;
    }
  }

  public function get lat() {return point.lat};
  public function get lng() {return point.lng};
  public function get elevation() {return point.elevation};

  public function set lat(lat) {point.lat = lat};
  public function set lng(lng) {point.lng = lng};
  public function set elevation(elevation) {point.elevation = elevation};
  
  public function get display_lat() {return display_point.lat};
  public function get display_lng() {return display_point.lng};

  public function set display_lat(lat) {display_point.lat = lat};
  public function set display_lng(lng) {display_point.lng = lng};

  public function Sensor() {
    position = new Position();
    parameters = {};
  }
  
  public static function from_station_row(row:Object):Sensor {
    var sensor:Sensor = new Sensor();
    
    sensor.id             = ""; // chosen when added to SensorList
    sensor.description    = new Description();
    sensor.description.text = row.description;
    sensor.type           = row.type;
    sensor.link_type      = row.link_type;
    sensor.links          = null;
    
    if (sensor.link_type == "HV") sensor.link_type = "HOV";
    if (sensor.link_type == "ML") sensor.link_type = "FW";

    sensor.lat = row.lat;
    sensor.lng = row.lng;
    sensor.elevation = 0;
    
    // set these so that they can change out of sync with lat/lng
    sensor.display_position = new Display_position();
    sensor.display_lat = row.lat;
    sensor.display_lng = row.lng;

    sensor.parameters.data_id        = row.vds;
    sensor.parameters.length         = row.length;
    sensor.parameters.offset_in_link = 0.0;
    sensor.parameters.vds            = row.vds;
    sensor.parameters.hwy_name       = row.hwy_name;
    sensor.parameters.hwy_dir        = row.hwy_dir;
    sensor.parameters.postmile       = row.postmile;
    sensor.parameters.lanes          = row.lanes;
    sensor.parameters.start_time     = 0;

    return sensor;
  }
}

}

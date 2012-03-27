package aurora {

public dynamic class Phase {
  public var row:int;
  public var column:int;
  
  public function Phase() {
    yellow_time = 0;
    red_clear_time = 0;
    min_green_time = 0;

    links = new Links();
  }
}

}

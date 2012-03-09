package aurora {
  // class to add essential iteration functionality to XMLLists
  // Usage:
  //   var a:Array = XMLListMap.from(xmllist).to_a(function (item) {...});
  public class XMLListMap {
    public var xmllist:XMLList;

    public static function from(xl:XMLList) {
      var mapper = new XMLListMap;
      mapper.xmllist = xl;
      return mapper;
    }

    // apply f to each xml item, returning array of results; any additional
    // argument is passed on to f
    public function to_a(f:Function, param = null, param2 = null) {
      var a:Array = [];
      var item:XML;
      for each (item in xmllist) {
        if (param2) {
          a.push(f(item, param, param2));
        }
        else if (param) {
          a.push(f(item, param));
        }
        else {
          a.push(f(item));
        }
      }
      return a;
    }
  }
}

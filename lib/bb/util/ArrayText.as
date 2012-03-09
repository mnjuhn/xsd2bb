package aurora {
  // Class to parse structured text in xml elements that represents an array.
  //
  // Usage:
  //   var a:Array = ArrayText.parse(xml.text, delims, cell_type, obj_with_id);
  //
  // The cell_type must be "String", "Number", etc.
  //
  // The delims argument is an array of strings that specifies the delimiters
  // used for each dimension. See AS3::Class for details. The length
  // of the delims array is the same as the dimensions of the data array.
  //
  // The obj_with_id is a hash that maps ids (strings) to objects. This should
  // be provided by the Scenario object, for example. Note that in Scenario
  // the object_with_id is a two-layer hash, but here it is just one layer.
  // In other words, pass object_with_id.link instead of object_with_id.
  //
  // Typically, the delims value will come from a _default_ value for the
  // delims attr, which is specified in the xsd. In effect, delims is a static
  // (per-class) constant.
  //
  // The presence of separators determines how the data cells are 
  // arranged in the resulting array.
  //
  // Note that parse("1,2;3,4", [","], "Number"); will not fail, but will
  // return the possibly undesired array ["1", "2;3", "4"].
  //
  public class ArrayText {
    internal static function convert_cell_to_string(s:String): String {
      return s;
    }

    internal static function convert_cell_to_number(s:String): Number {
      var n:Number = Number(s);
      if (isNaN(n)) {
        throw("Invalid numeric data in cell: " + s);
      }
      return n;
    }

    internal static function
        fn_to_convert_cell_from(cell_type:String,
        object_with_id:Object): Function {
      switch (cell_type) {
        case "String":
          return convert_cell_to_string;

        case "Number":
          return convert_cell_to_number;
        
        default:
          return function(id:String){return object_with_id[id];};
      }
    }

    public static function parse(input:Object,
        delims:Array, cell_type:String, object_with_id:Object): Object {
      var data:String = input.toString();
        //# toString needed because input might be multiple xml text chunks
      
      var convert:Function = fn_to_convert_cell_from(cell_type, object_with_id);
      if (convert == null) {
        throw new Error("bad input, cell_type=" + cell_type, 1);
      }
      
      return slice_and_dice(data, delims, convert);
    }
    
    internal static function slice_and_dice(data:String,
        delims:Array, convert:Function): Object {
      var dim = delims.length;
      
      switch (dim) {
        case 0:
          return convert(data);
        
        case 1:
          if (data.length == 0) {
            return [];
          }
          else {
            return data.split(delims[0]).map(function(s){return convert(s)});
          }

        default:
          var rest_delims = delims.slice(1,1000000);
          return data.split(delims[0]).map(function(s){
            return slice_and_dice(s, rest_delims, convert)});
      }
    }

    public static function emit(input:Object,
        delims:Array = null, indenter:String = ""): String {
      var dim:int = delims ? delims.length : 0;
      var ind:String;
      
      switch (dim) {
        case 0:
          return input.toString();
        
        case 1:
          return input.join(delims[0]);
        
        case 2:
          ind = indenter + "  ";
          return ind +
            input.map(
              function(a){return emit(a, delims.slice(1, 2), indenter)}
            ).join(delims[0] + ind);
        
        case 3:
          ind = indenter + "  ";
          return ind +
            input.map(
              function(a){
                return a.map(function(a1){
                  return a1.join(delims[2])
                }).join(delims[1]);
              }).join(delims[0] + ind);
        
        default:
          return input.toString(); //# ???
      }
      
      return result;
    }
  }
}

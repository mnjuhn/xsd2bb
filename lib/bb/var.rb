require 'bb/generative'

module BB
  class Var
    include Generative
    
    # BB::Class instance to which this Var belongs.
    attr_reader :bb_class
    
    # Name of variable--i.e. how it is referenced in source code.
    attr_reader :name

    # Data type. Can be either native type (Number, String, Array, Date,
    # Boolean, int, Object) _or_
    # class defined by schema (gen. by instance of BB::Class).
    attr_reader :type
    
    # If the type is a class (rather than a native type), then this is the
    # name of the type (eg. "node", but not "Node").
    attr_reader :references
    
    # Name of attr or element in which value is stored (nil in text case).
    attr_reader :xml_name
    
    # How is the variable's value stored in the xml? The value can be stored
    # in an attribute, a subelement, the text body (either with
    # simpleContent or mixed="true" in a complexType), or as a
    # <parameters> block.
    attr_reader :xml_storage_class
    
    # Does the variable store a collection of values, or just a single value?
    attr_reader :collection
    
    # The default value of the variable, if it is optional. The value is
    # expressed as a string in BB syntax. I.e., default=='"foo"' represents
    # an BB string of length 3.
    attr_reader :default
    
    XML_STORAGE_ATTRIBUTE   = :attribute
    XML_STORAGE_SUBELEMENT  = :subelement
    XML_STORAGE_TEXT        = :text
    XML_STORAGE_PARAMETERS  = :parameters
    
    # This is still useful for detecting the difference between scalar types and
    # "objects". The values in this hash are obsolete.
    VAR_TYPE_FROM_SIMPLE_XS_TYPE = {
      "xs:string" => "String",
      "xs:integer" => "int",
      "xs:boolean" => "Boolean",
      "xs:decimal" => "Number"
    }

    class StaticVarException < Exception
      def self.[](*args); new(*args); end
      
      attr_reader :content
      
      def initialize *args
        @content = args
      end
    end
    
    class CellTypeException < StaticVarException; end
    class DimException < StaticVarException; end
    
    def initialize bb_class, name, type, opts = {}
      @bb_class = bb_class
      @name = name
      @type = type
      @xml_name = opts[:xml_name]
      @xml_storage_class = opts[:xml_storage_class]
      @collection = opts[:collection]
      @default = opts[:default]
      
      if @name =~ /(.*)_id$/
        @references = $1
      end
    end

    # Convert attr declaration to BB:Var instance.
    #
    # There are two special cases: attrs named "cellType" or "delims" are not
    # converted into variables, and actually should not be provided in the xml.
    # Instead, they are class-level declarations about the structure of the text
    # contained in the element and how it should be (de)serialized.
    #
    def self.from_xs_attribute xs_attr, bb_class
      xml_name = xs_attr.attributes["name"].value
      case xml_name
      when "class" # reserved identifier in BB/CS
        bb_attr_name = "class_name"
      else
        bb_attr_name = xml_name.dup
      end
      
      type_attr = xs_attr.attributes["type"]
      if type_attr
        xs_type = type_attr.value
      else
        restriction = xs_attr.xpath("./xs:simpleType/xs:restriction").first
        xs_type = restriction && restriction.attributes["base"]
        xs_type &&= xs_type.value
        unless xs_type
          raise SyntaxError, "Attribute #{xs_attr} has no type delcaration."
        end
        ## should do more to examine the restrictions and generate
        ## appropriate code
      end
      bb_attr_type = VAR_TYPE_FROM_SIMPLE_XS_TYPE[xs_type]
      
      bb_attr_default =
        xs_attr.attributes["use"] &&
        xs_attr.attributes["use"].value == "optional" &&
        xs_attr.attributes["default"] &&
        xs_attr.attributes["default"].value
      
      case bb_attr_name
      when "cellType"
        # Special case, since there is no way in xsd to signal that this
        # kind of attr should have its actual given values converted to the
        # type indicated by the attr's default value.

        unless bb_attr_default
          raise SyntaxError,
            "Use of 'cellType' requires that a default type be given."
        end

        cell_type = VAR_TYPE_FROM_SIMPLE_XS_TYPE[bb_attr_default]
        
        if cell_type
          cells_are_ids = false
        else
          # fall back to the stated type, such as "link"
          cell_type = bb_attr_default
          cells_are_ids = true
        end
          
        raise CellTypeException[cell_type, cells_are_ids]
          # cell_type will become a compile-time attribute of the BB::Class
          # instance (a ruby object) which defines this var; it is not stored
          # in the run-time BB class
      
      when "delims"
        # Another special case: but simpler. Just treat the value as a static.
        raise DimException[bb_attr_default.split("")]
      
      else
        case bb_attr_type
        when "String"
          if bb_attr_default
            bb_attr_default = bb_attr_default.inspect
              # so we can interpolate literal (otherwise, we lose a layer of
              # quotation marks)
          end
        end
      end

      Var.new(bb_class, bb_attr_name, bb_attr_type,
        :xml_name => xml_name,
        :xml_storage_class => XML_STORAGE_ATTRIBUTE,
        :default => bb_attr_default)
    end
    
    def gen_lines
      # Nothing to declare in coffeescript
    end
    
    # +target+ is string containing code that references the object which
    # owns this variable; +xml+ is string containing code that references the
    # XML object.
    def gen_xml_importer(target, xml)
      defer = false
      
      xml_find = xml_name ? "#{xml_name} = xml.children('#{xml_name}')" : ""
      xml_read =
        case xml_storage_class
        when XML_STORAGE_ATTRIBUTE
          xml_find = "#{xml_name} = $(xml).attr('#{xml_name}')"
          n = xml_name
          if default
            "(#{xml_name}.length == 0 ? #{default} : #{xml_name}) if #{xml_name}?"
          else
            "#{xml}.#{n}"
          end
        
        when XML_STORAGE_SUBELEMENT
          if collection
            "#{xml}.children('#{xml_name}')" # XMLList
          else
            "#{xml}.children('#{xml_name}')[0]" # Unique matching child
          end
        
        when XML_STORAGE_PARAMETERS
          "#{xml}.find('#{xml_name}')"
        
        when XML_STORAGE_TEXT
          "#{xml}.text()"
        end
      
      rhs =
      case type
      when "String"
        xml_name
      
      when "int", "uint", "Number"
        "Number(#{xml_name})"
      
      when "Boolean"
        "(#{xml_name}.toString().toLowerCase() == 'true') if #{xml_name}?"
      
      when "Object"
        unless xml_storage_class == XML_STORAGE_PARAMETERS
          raise "Object type must use parameter storage."
        end
        
    %{_.reduce(parameters.find("parameter"),
          (acc,par_xml) ->
            wrapped_xml = $(par_xml);
            acc[wrapped_xml.attr('name')] = wrapped_xml.attr('value')
            acc
          {}
    )}
      
      when "Array"
        delims = bb_class.delims
        cell_type = bb_class.cell_type
        unless delims and cell_type
          raise SyntaxError, "#{bb_class.name} needs delims and cellType."
        end
        
        if bb_class.cells_are_ids
          defer = true
          id_map_name = "object_with_id.#{cell_type}"
        else
          id_map_name = "null"
        end

        args = [xml_read, "@delims", cell_type.inspect, id_map_name]
        "$a.ArrayText.parse(#{args.join(", ")})" ### See util dir

      else # complex object or collection-based class (our class, not Array)
        unless xml_storage_class == XML_STORAGE_SUBELEMENT
          raise "Complex type must use subelement storage."
        end
        
        if collection
          "_.map($(#{xml_name}), (#{xml_name}_i) -> $a.#{type}.from_xml2($(#{xml_name}_i), deferred, object_with_id))"
        else
          "$a.#{type}.from_xml2(#{xml_name}, deferred, object_with_id)"
        end
      end
      
      unless xml_storage_class == XML_STORAGE_TEXT && type == "String"
        assign = [xml_find, 
                  "#{target}.set('#{name}', #{rhs})"]
      else
        assign = ["#{target}.set('#{name}', #{xml_read})"]
      end
      
      if defer
        "deferred.push(=> #{assign})"
      else
        assign
      end
    end
    
    # +xml+ is string containing code that references the
    # XML object. We assume that 'this' is the object to be exported.
    def gen_xml_exporter(xml)
      case xml_storage_class
      when XML_STORAGE_ATTRIBUTE
        xn = xml_name
        
        if default
          "if @has('#{name}') && @#{name} != #{default} " +
            "then xml.setAttribute('#{xn}', @get('#{name}'))"
        else
          "#{xml}.setAttribute('#{xn}', @get('#{name}')) if @has('#{name}')"
        end

      when XML_STORAGE_SUBELEMENT
        if collection
          "_.each(@get('#{name}') || [], " +
          "(a_#{name}) -> #{xml}.appendChild(a_#{name}.to_xml(doc)))"
        else
          "#{xml}.appendChild(@get('#{name}').to_xml(doc)) if @has('#{name}')"
        end

      when XML_STORAGE_TEXT
        delims = bb_class.delims
        if delims
          if bb_class.cells_are_ids
            "#{xml}.appendChild(doc.createTextNode($a.ArrayText.emit((@get('#{name}') || []).map((x) -> x.id), @delims)))"
          else
            "#{xml}.appendChild(doc.createTextNode($a.ArrayText.emit(@get('#{name}') || [], @delims)))"
          end
        else
          "#{xml}.appendChild(doc.createTextNode($a.ArrayText.emit(@get('#{name}') || [])))"
        end
      
      when XML_STORAGE_PARAMETERS
   %{if @has('#{name}')
      parameters_xml = doc.createElement('#{xml_name}')
      _.each(@get('#{name}'), (par_val, par_name) ->
          parameter_xml = doc.createElement('parameter')
          parameter_xml.setAttribute(par_name, par_val)
          parameters_xml.appendChild(parameter_xml)
      )
      #{xml}.appendChild(parameters_xml)
    }

      else raise
      end
    end
    
    def gen_inspect(ary_name)
      s =
        if collection
          "(#{name} && '[' + #{name}.map((x) -> x && (indenter + '  ' + x.inspect(depth, indent, orig_depth+1))) + ']')"
        else
          case type
          when "String"
            %{"'" + #{name} + "'"}

          when "int", "uint", "Boolean", "Number", "Date"
            name
          
          when "Array"
            if bb_class.cells_are_ids
              %{(ArrayText.emit((#{name}||[]).map((x) -> x.inspect(depth, indent, orig_depth+1)), delims, indenter))}
            else
              %{(ArrayText.emit((#{name}||[]), delims, indenter))}
            end
          
          when "Object"
            %{(#{name} &&
        function(){
          var par_str:String = "{";
	        for(var par_name:String in #{name}){
            par_str += indenter + '    ' + par_name + ': ' + #{name}[par_name];
          }
          par_str += "}";
          return par_str;
        }())}

          else # complex object defined by schema
            "(#{name} && #{name}.inspect(depth, indent, orig_depth))"
          end
        end

      "#{ary_name}.push(' #{name}: ' + #{s})"
    end
  end
end

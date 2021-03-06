require 'bb/generative'
require 'bb/const'
require 'bb/var'

module BB
  class Class
    include Generative

    attr_reader :name
    attr_reader :vars
    attr_reader :consts # "consts" are really just class instance vars
    
    # The text of the xml element represents the value of a variable.
    # Cell type of the text var, if any. Value is String, such as "Number".
    #
    # In the xsd this type is specified using something like:
    #
    #  <xs:attribute name="cellType"
    #   type="xs:string" use="optional" default="xs:decimal" />
    #
    attr_reader :cell_type
    
    # Are cells in the text var ids that reference other elements in the xml?
    attr_reader :cells_are_ids
    
    # Instances of this class are referenced by ID in the xml repr. of
    # some other class, such as PathList referencing a list of link IDs.
    attr_reader :referenced
    
    # Name of the class as used in references to it, such as "link" for Link.
    # Also used as key in object_with_id hashes.
    attr_reader :ref_name

    # Dim of the array-structured text var, if any. Value is Integer.
    attr_reader :dim
    
    # Delimiters of the array-structured text var, if any. Value is Array.
    # For example, [";", ",", ":"] signifies 3 dim data with rows separated by
    # semicolons, colums separated by commas, and "stacks" separated by colons.
    #
    # In the xsd, this list is specified using something like:
    #
    #      <xs:attribute name="delims"
    #       type="xs:string" use="optional" default=";,:" />
    #
    attr_reader :delims
    
    # Does this object accept any given attribute (defined by xs:anyAttribute)?
    attr_reader :any_attr
    
    def initialize name = nil, vars = [], consts = []
      @name = name
      fix_name!
      @vars = vars
      @consts = consts
      @cell_type = nil
      @cells_are_ids = false
      @referenced = false
      @dim = nil
      @delims = nil
      @any_attr = false
      yield self if block_given?
    end

    def fully_qualified_class_name 
      "window.#{@package_name}.#{@name}"
    end
    
    # Declare that this class is referenced from some other element.
    def referenced! ref_name
      @referenced = true
      @ref_name = ref_name
    end
    
    def fix_name!
      @name &&= Class.fix_name(@name)
    end
    
    def Class.fix_name s
      s.sub(/\A./) {|c| c.upcase}
    end
    
    def self.from_element e, package
      new {|c| c.populate_from_element e, package}
    end
    
    def populate_from_element e, package
      @xml_name = @name = e.attributes["name"].value
      @package_name = package.name
      fix_name!
      
      populate_vars_from_element(e)

      if vars.find {|var| var.name == "schemaVersion"}
        consts << Const.new(self, "SchemaVersion", package.schema_version)
      end
      
    rescue => ex
      ex.message << ". In element:\n#{e.to_s}."
      raise ex
    end
    
    def populate_vars_from_element e
      complexType = e.xpath("./xs:complexType").first

      if complexType
        if complexType.attributes["mixed"].to_s == "true"
          populate_vars_from_mixed complexType, e
        else
          populate_vars_from_subelements complexType, e
        end
      
      else
        populate_vars_from_simple_type e
      end
    end
    
    def populate_vars_from_mixed complexType, element
      populate_vars_from_subelements complexType, element
      populate_text_var
    end
    
    def populate_vars_from_subelements complexType, element
      complexType.xpath("./xs:*").each do |elt|
        case elt.name
        when "attribute"
          populate_var_from_attr(elt)
        
        when "anyAttribute"
          @any_attr = true
        
        when "all", "choice", "sequence"
          elt.xpath(".//xs:element").each do |e|
            ref_attr = e.attributes["ref"]
            
            if not ref_attr
              raise "Unhandled ref_attr:\n\n  #{e}\n\n"
            end
            
            case ref_attr.value
            when "parameters" # special case
              populate_parameters_var
            else
              populate_var_from_subelement ref_attr.value, e
            end
          end
        
        else
          raise "Unhandled element:\n\n  #{elt}\n\n"
        end
      end
    end

    def populate_var_from_subelement ref_elt_name, subelt
      maxOccurs = subelt.attributes["maxOccurs"]

      collection = maxOccurs && (
        maxOccurs.value == "unbounded" || maxOccurs.value.to_i > 1)

      vars << Var.new(self,
        ref_elt_name.downcase,
        Class.fix_name(ref_elt_name),
        :xml_name => ref_elt_name,
        :xml_storage_class => Var::XML_STORAGE_SUBELEMENT,
        :collection => collection
      )
    end
    
    # A parameter subelement generates a 'parameters' BB var whose value is
    # an object whose keys/values will be read from the parameter entries.
    def populate_parameters_var
      vars << Var.new(self,
        "parameters",
        "Object",
        :xml_name => "parameters",
        :xml_storage_class => Var::XML_STORAGE_PARAMETERS,
        :default => "{}"
      )
    end

    def populate_var_from_attr xs_attr
      vars << Var.from_xs_attribute(xs_attr, self)

    rescue Var::CellTypeException => ex
      cell_type, cells_are_ids = ex.content
      # Treat this one as a _static_ variable (i.e. a class var)
      raise if @cell_type and @cell_type != cell_type
      @cell_type = cell_type
      @cells_are_ids = cells_are_ids

    rescue Var::DimException => ex
      # Treat this one as a _static_ variable (i.e. a class var)
      raise if @dim and @delims != ex.content[0]
      @delims = ex.content[0]
      @dim = @delims.size
    end
    
    def populate_text_var
      text_var_name, text_var_type =
        case dim
        when nil
          ["text", "String"]
        when 0
          ["value", @cell_type]
        when Integer
          ["cells", "Array"]
        else raise
        end
      
      vars << Var.new(self, text_var_name, text_var_type,
        :xml_storage_class => Var::XML_STORAGE_TEXT)
    end
        
    def populate_vars_from_simple_type e
      var_name = "text" # NOT: e.attributes["name"].value
      xs_type = e["type"] || 
        e.xpath('xs:simpleType/xs:restriction').first["base"]
      var_type = Var::VAR_TYPE_FROM_SIMPLE_XS_TYPE[xs_type]
      var_type or raise "No type for #{xs_type.inspect}"
      vars << Var.new(self, var_name, var_type,
        :xml_storage_class => Var::XML_STORAGE_TEXT)
    end

    def gen_lines
      lines = []
      lines << "class #{fully_qualified_class_name} extends Backbone.Model"
      
      if dim
        lines << ["@dim = #{dim}"]
        lines << ["@delims = #{delims.inspect}"]
      end

      if cell_type
        lines << ["@cell_type = #{cell_type.inspect}"]
      end

      lines << [
        "### $a = alias for #{@package_name} namespace ###",
        "$a = window.#{@package_name}", 
        "@from_xml1: (xml, object_with_id) ->",
        gen_from_xml_body(), "",
        
        "@from_xml2: (xml, deferred, object_with_id) ->",
        gen_from_xml2_body(), "",
        
        "to_xml: (doc) ->",
        gen_to_xml_body(), "", 
           
        "deep_copy: -> #{name}.from_xml1(@to_xml(), {})",

        "inspect: (depth = 1, indent = false, orig_depth = -1) -> null",       
        "make_tree: -> null",
     ]
    end
    
    def gen_from_xml_body
      a = []
      a << "deferred = []"
      a << "obj = @from_xml2(xml, deferred, object_with_id)"
      a << "fn() for fn in deferred"
      a << "obj"
      a
    end
    
    def gen_from_xml2_body
      a = []
      
      a << "return null if (not xml? or xml.length == 0)"
      
      a << "obj = new #{fully_qualified_class_name}()"
      vars.each do |var|
        code = var.gen_xml_importer("obj", "xml")
        case code
        when Array
          a.concat code
        else
          a << code
        end
      end
      
      if referenced
        a << "if object_with_id.#{ref_name}"
        a << [
          "object_with_id.#{ref_name}[obj.id] = obj"
        ]
        # note that object_with_id.#{ref_name} might be null in deep_copy().
      end
      
      a << "if obj.resolve_references"
      a << [
        "obj.resolve_references(deferred, object_with_id)"
      ]
      
      a << "obj"
      a
    end
    
    def gen_to_xml_body
      a = []
      a << "xml = doc.createElement('#{@xml_name}')"
      
      a << "if @encode_references"
      a << [
        "@encode_references()"
      ]
      
      vars.each do |var|
        code = var.gen_xml_exporter("xml")
        case code
        when Array
          a.concat code
        else
          a << code
        end
      end
      
      a << "xml"
      a
    end
    
    ### We don't need this if there is something better in BB
    def gen_inspect_body
      a = []
    end
    
    # Generates a function to recursively build a data structure of
    # hashes with label and children keys, which can be added to
    # an ArrayCollection that is bound to a tree control. There is also
    # an object key whose value is a reference back to the corresponding
    # instance of this class (i.e. the application data class).
    ### we probably don't need this, so it's not ported to BB yet
    def gen_make_tree
      a = []
    end
  end
end

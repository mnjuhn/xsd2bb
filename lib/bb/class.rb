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
      lines << "window.#{@package_name}.#{name} = Backbone.model.extend("
      
      if dim
        lines << ["@dim = #{dim}"]
        lines << ["@delims = #{delims.inspect}"]
      end

      if cell_type
        lines << ["@cell_type = #{cell_type.inspect}"]
      end

      lines << [
        "#{name}.from_xml1 = (xml, object_with_id) ->",
        gen_from_xml_body(), "",
        
        "#{name}.from_xml2 = (xml, deferred, object_with_id) ->",
        gen_from_xml2_body(), "",
        
        "to_xml: ->",
        gen_to_xml_body(), "",
        
        "toString: ->",
        ["inspect()"], "",
        
        "inspect: (depth = 1, indent = false, orig_depth = -1) ->",
        gen_inspect_body(), "",
        
        "deep_copy: ->",
        [
          "objs = {};",
          "#{name}.from_xml1(to_xml(), {})"
        ], "",
        
        "make_tree():Array {",
        gen_make_tree(),
        "}", ""
      ]
      
      lines << "# #{name} Constants"
      lines << consts.map {|const| const.gen_lines}.compact
      lines << ""
      
      lines << "# #{name} Instance Variables"
      lines << vars.map {|var| var.gen_lines}.compact
      lines << ""
    end
    
    def gen_from_xml_body
      a = []
      a << "var deferred = []"
      a << "var obj = from_xml2(xml, deferred, object_with_id)"
      a << "for fn in deferred"
      a << ["fn()"]
      a << "obj"
      a
    end
    
    def gen_from_xml2_body
      a = []
      
      a << "return null if not xml"
      
      a << "obj = new #{name}"
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
      
      a << "return obj"
      a
    end
    
    def gen_to_xml_body
      a = []
      a << "xml = <#{@xml_name}/>;" ### need to instantiate xml element
      
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
      a << "a = ['<#{name}']"
      a << "indenter = ''"
      
      a << "if orig_depth == -1 then orig_depth = depth"
      a << "depth--;"
      a << "if depth > 0"
      if_block = []
      a << if_block
      if_block << "if indent then indenter = '\\n' + StringIndenter.indent(orig_depth - depth)"
        ### see util dir
      if_block << "a.push(':')"
      
      vars.each do |var|
        if_block << "if indent then a.push(indenter)"
        code = var.gen_inspect("a")
        case code
        when Array
          if_block.concat code
        else
          if_block << code
        end
      end
      
      if any_attr
        if_block.concat [
          "for own dyn_attr of this",
          [
            "if indent then a.push(indenter)",
            "a.push(' ' + dyn_attr + ': ' + this[dyn_attr].toString())"
              ### should recurse if needed
          ]
        ]
      end
      
      a << "a.push('>')"
      a << "return a.join('')"
      a
    end
    
    # Generates a function to recursively build a data structure of
    # hashes with label and children keys, which can be added to
    # an ArrayCollection that is bound to a tree control. There is also
    # an object key whose value is a reference back to the corresponding
    # instance of this class (i.e. the application data class).
    ### we probably don't need this, so it's not ported to BB yet
    def gen_make_tree
      a = []
      a << "var level:Array = [];"
      have_myself = false
      
      vars.each do |var|
        case var.type
        when "Number", "String", "Array", "Date", "Boolean", "int", "uint"
          a << %{level.push({label: "#{var.name}", object: this});}
        else # complex object
          if var.collection
            unless have_myself
              have_myself = true
              a << "var myself = this;"
            end
            
            c = [
              "#{var.name}.map(function(x) {",
              ["return x ? {",
               "label: x.name || 'UNNAMED',",
               "children: x.make_tree(),",
               "object: myself} : {} })"]
              ]
          else
            c = ["#{var.name} && #{var.name}.make_tree()"]
          end
          a << "level.push({"
          a << [
            "label: '#{var.name}',",
            "object: this,",
            "children:", c
          ]
          a << "});"
        end
      end
      
      a << "return level;"
      a          
    end
  end
end

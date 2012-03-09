require 'bb/class'

module BB
  class Package
    include Generative
    
    attr_reader :name
    
    # Classes in the package.
    attr_reader :classes
    
    # List of classes that might be referenced by ID in an xml doc. For
    # example, PathList references a list of link IDs, so referenced_classes
    # should include the BB::Class instance for Link.
    attr_reader :referenced_classes
    
    # This gets read from version attr of schema element.
    attr_reader :schema_version
    
    def initialize name
      @name = name
      @classes = []
      @referenced_classes = []
    end
    
    def populate_from_schema(schema)
      @schema_version = schema["version"]
      
      @classes = schema.xpath("./xs:element").map do |elt|
        yield elt if block_given?
        BB::Class.from_element(elt, self)
      end
    end
    
    def scan_for_reference_types(&block)
      @classes.each do |c|
        if c.cells_are_ids
          handle_reference_type c.cell_type, &block
        end
        
        c.vars.each do |var|
          if var.references
            handle_reference_type var.references, &block
          end
        end
      end
    end
    
    def handle_reference_type ref_type_name
      ref_name = Class.fix_name(ref_type_name)
      ref_cl = @classes.find {|rc| rc.name == ref_name}

      unless ref_cl
        raise "Cannot resolve reference to class #{ref_type_name.inspect}."
      end

      unless ref_cl.referenced
        yield ref_cl if block_given?
        referenced_classes << ref_cl ## might not need this
        ref_cl.referenced!(ref_type_name)
      end
    end
    
    def gen_string_from_class cl
      class_lines = cl.gen_lines
require 'pp'
pp [cl.name, class_lines]
      gen_string {class_lines}
    end
    
    def gen_lines
      lines = []
      lines << "package #{name} {" << ""
      lines.concat yield if block_given? # concat not <<, to avoid indent
      lines << "" << "}" << ""
      lines
    end
  end
end

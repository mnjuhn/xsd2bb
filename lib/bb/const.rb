require 'bb/generative'

module BB
  class Const
    include Generative
    
    # BB::Class instance to which this Const belongs.
    attr_reader :bb_class
    
    # Name of constant--i.e. how it is referenced in source code.
    attr_reader :name

    # Value of constant, as a ruby object.
    attr_reader :value

    def initialize bb_class, name, value
      @bb_class = bb_class
      @name = name
      @value = value
    end
    
    def gen_lines
      "@#{name} = #{value.inspect};"
    end
  end
end

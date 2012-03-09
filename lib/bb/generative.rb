module BB
  # The class into which this module is included should define #gen_lines,
  # which should return an array of line strings, with nesting arrays 
  # representing indented code blocks.
  module Generative
    def gen_string(&block)
      indent(gen_lines(&block).compact).join("\n")
    end
    
    # expand nested arrays, adding indentation
    def indent(lines, result = [], depth = 0)
      spaces = nil
      lines.each do |line|
        case line
        when Array
          indent(line, result, depth + 2)
        else
          spaces ||= " "*depth
          result << line.sub(/^/, spaces)
        end
      end
      result
    end
  end
end

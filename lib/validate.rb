require 'rubygems'
require 'nokogiri'

class SchemaError < StandardError; end
class InputError < StandardError; end

def validate xml_file, schema_file
  begin
    xsd = Nokogiri::XML::Schema(File.read(schema_file))
  rescue => e
    raise SchemaError, e
  end
  
  begin
    doc = Nokogiri::XML(File.read(xml_file))
  rescue => e
    raise InputError, e
  end

  xsd.validate(doc).each do |error|
    yield "Line #{error.line}: #{error.message}"
  end
end

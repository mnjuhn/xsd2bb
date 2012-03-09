#!/usr/bin/env ruby
if __FILE__ == $0
  $LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
end
require 'xsd2bb'
Xsd2bb.run ARGV

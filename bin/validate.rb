#!/usr/bin/env ruby

if __FILE__ == $0
  $LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
end

require 'validate'

verbose = ARGV.delete("-v")

if ARGV.delete("-h") or ARGV.delete("--help") or ARGV.size != 2
  puts <<-END
    Usage: #{$0} [options] <input.xml> <schema.xsd>
    
    Validate <input.xml> against <schema.xsd>.
    
    Options:
    
    -h, --help    This help.
    
    -v            Be verbose.
    
  END
  exit
end

passed = true

begin
  validate ARGV[0], ARGV[1] do |msg|
    $stderr.puts(msg || ".") if verbose
    passed = false
  end

rescue => e
  passed = false
  $stderr.puts "#{e.class}: #{e.message}"

else
  $stderr.puts passed ? "Passed." : "Failed."
  $stderr.puts "(Use -v to see why.)" if !passed and !verbose
end

exit(passed)

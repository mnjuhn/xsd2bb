require 'rubygems'
require 'nokogiri'
require 'fileutils'
require 'pp'

require 'argos'
require 'bb/package'

module Xsd2bb
  USAGE = <<-END
    
    Usage: #{$0} [options] <input-schema.xsd> <output-dir-name>
    
    Generate CoffeeScript files in <output-dir-name> that can be
    used to work with an XML file that matches the <input-schema.xsd>.
    
    Options:
    
    -h, --help    This help.
    
    -v            Be verbose.
    
  END

  def self.run argv
    optdef = {
      "v"             => true,
      "h"             => true,
      "help"          => true
    }
    
    begin
      cli_opts = Argos.parse_options(argv, optdef)
    rescue Argos::OptionError => ex
      $stderr.puts ex.message
      exit
    end

    verbose = cli_opts["v"]
    help = cli_opts["h"] || cli_opts["help"]

    if help or argv.size != 2
      puts USAGE
      exit
    end
    
    argv[0] =~ /(\w+).xsd$/

    gen_opts = {
      :pkg_name       => $1, # from argv[0] regex match
      :out_dir        => argv[1]
    }

    make_bb_dir_from_xsd_file argv[0], gen_opts do |msg|
      $stderr.print(msg || ".") if verbose
    end
    $stderr.puts if verbose
  end
  
  def self.make_bb_dir_from_xsd_file xsd_file, opts = {}
    pkg_name, out_dir =
      opts.values_at(:pkg_name, :out_dir)
    
    doc = Nokogiri::XML(File.read(xsd_file))
    schema = doc.children[0]
    pkg = BB::Package.new(pkg_name)
    pkg.populate_from_schema(schema) do |elt|
      yield "C" if block_given?
    end
    
    pkg.scan_for_reference_types do |cl|
      yield "R" if block_given?
    end
    
    FileUtils.makedirs out_dir # check if exists, empty, etc
    
    pkg.classes.each do |cl|
      File.open("#{out_dir}/#{cl.name}.coffee", "w") do |f|
        yield "W" if block_given?
        f << pkg.gen_string_from_class(cl)
      end
    end
  end
end

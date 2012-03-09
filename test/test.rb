libdir = File.expand_path('../lib', File.dirname(__FILE__))
$LOAD_PATH.unshift libdir

require 'xsd2bb'

# This test reads the xsd and the _expected_ as3 files from input dir,
# which is also the working lib/aurora dir.
# It writes the _actual_ generated as3 files to test/output.
# Then it recursively compares the dirs.
# Note that the input files are in git, but the outputs are not.

in_dir = "expected"
out_dir = "output"

xsd_file = ARGV[0]

system "rm -rf #{out_dir}"

begin
  gen_opts = {
    :pkg_name       => "aurora",
    :out_dir        => out_dir
  }

  Xsd2bb.make_bb_dir_from_xsd_file xsd_file, gen_opts do |msg|
    $stderr.print(msg || ".")
  end

rescue => e
  puts
  puts "#{e.class}:#{e.message}"
  puts "At " + e.backtrace.join("\n  from ")
  exit
end
$stderr.puts

passed = system "diff -x '*.swc' -r #{in_dir} #{out_dir}"
$stderr.puts( passed ? "Passed." : "Failed." )

# This program is just test framework for the _algorithm_ used in as3 code to
# parse array data. It is faster and easier to tinker with the algorithm in
# an interpreted language like ruby, which also has better string and array
# handling.

class DataError < StandardError; end

def numeric s
  begin
    Integer(s) rescue Float(s)
  rescue
    raise DataError, "Not numeric data: #{s.inspect}"
  end
end

def symbolic s
  s.strip
end

def parse data, dim
  comma = data[/,/]
  semicolon = data[/;/]
  colon = data[/:/]
  
  seplist = [semicolon, comma, colon].compact # in order of hi to lo
  nsep = seplist.size
  if nsep > dim
    raise DataError, "too many dimensions in the data"
  end
  
  case dim
  when 0
    numeric(data)
  
  when 1
    data.split(comma || semicolon || colon || " ").map {|s| numeric(s)}
  
  when 2
    case nsep
    when 0
      [[numeric(data)]]
    
    when 1
      if comma
        raise DataError, "ambiguous data: #{data.inspect}"
      elsif colon # matrix with one row
        [data.split(colon).
          map{|s|numeric(s)}]
      elsif semicolon # matrix with several rows, one column each
        data.split(semicolon).
          map{|s|[numeric(s)]}
      else raise
      end
    
    when 2
      data.split(seplist[0]).
        map{|s|
          s.split(seplist[1]).
            map{|s|numeric(s)}}
    end
  
  when 3
    data.split(/;/).
      map{|s|
        s.split(/,/).
          map{|s|
            s.split(/:/).
              map{|s|numeric(s)}}}
  end
end

def test_failed actual, expected=nil
  puts "-"*20, "Failed:"
  p actual
  puts "Expected:"
  p expected if expected
end

def test_equal a, s, dim
  r = parse(s, dim)
  unless r == a
    test_failed r, a
  end
rescue DataError => e
  test_failed s, a
  puts e
end

def test_error s, dim
  begin
    parse(s, dim)
  rescue DataError
  else
    test_failed s
  end
end

# dim 0
test_equal 4, " 4 ", 0
test_error " 4, 5 ", 0

# dim 1
test_equal [1.23], " 1.23 ", 1
test_equal [1,2,3], " 1,2,3 ", 1
test_equal [1,2,3], " 1:2:3 ", 1
test_equal [1,2,3], " 1;2;3 ", 1
test_error " 1,2:3 ", 1

# dim 2
test_equal [[1]], "1", 2

test_equal [[1,2]], "1:2", 2
#test_error "1,2", 2 ## we don't know if this is a row or col vector
test_equal [[1],[2]], "1;2", 2

test_equal [[1,2],[3,4]], "1,2;3,4", 2
test_equal [[1,2],[3,4]], "1:2,3:4", 2
test_equal [[1,2],[3,4]], "1:2;3:4", 2
test_error " 1,2:3;4 ", 2

#dim 3
test_equal [ [ [1,2,3], [4,5,6] ],
             [ [7,8,9], [10,11,12] ] ],
          "1:2:3,4:5:6;7:8:9,10:11:12", 3
test_equal [[[1]]], "1", 3
test_equal [[[1,2]]], "1:2", 3
test_equal [[[1],[2]]], "1,2", 3
test_equal [[[1]],[[2]]], "1;2", 3
test_equal [ [ [1], [2] ],
             [ [3], [4] ] ],
           "1,2;3,4", 3

puts "done"

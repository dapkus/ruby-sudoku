require 'set'

class SudokuSquare
  def initialize(x, y, value=nil, x_constraint=[], y_constraint=[], g_constraint=[])
    raise "woah! #{x}, #{y}, #{x_constraint}, #{y_constraint}, #{g_constraint}" if x_constraint.nil? || y_constraint.nil? || g_constraint.nil?
    @x=x;@y=y;@value=value
    @x_constraint = x_constraint
    @y_constraint = y_constraint
    @g_constraint = g_constraint
  end

  def x()
    return  @x
  end
  def y()
    return @y
  end
  
  def value()
    @value
  end

  def equal(square)
    return square.y == @y && square.x == @x
  end  
  
  def try_available_values(&action) 
    available.each do |value|
      fillin(value)
      action.call()
      erase()
    end
  end

  def fillin(value)
    raise "constraint violation" if !(@y_constraint.delete(value) && @x_constraint.delete(value) && @g_constraint.delete(value))
    @value=value
  end 

  def erase()
    @y_constraint.add(value) 
    @x_constraint.add(value)
    @g_constraint.add(value)
    val = @value
    @value = nil
    return    val
  end 

  def available() 
    @y_constraint.intersection(@x_constraint.intersection(@g_constraint))
  end
end

class SudokuGame  
  def initialize(starting_board=[])
    vertical=[];horizontal=[];subgrid=[]
    @open = [] ; @filled = []
    #setup constraints
    (1..9).each  do |x| 
      vertical << Set.new(1..9)
      horizontal << Set.new(1..9)
      subgrid << Set.new(1..9)
    end
    # initialize board with squares
    (0..8).each  do |x| 
      (0..8).each  do |y| 
        @open << square = SudokuSquare.new(x,y,nil,horizontal[x], vertical[y] ,subgrid[x/3 + (y/3)*3])
      end    
    end
    # prepopulate board if provided
    starting_board.each do |square|
      sq = @open.find {|sq| square.equal(sq)} 
      sq.fillin(square.value)
      @filled << @open.delete(sq)
    end
  end

  def select_square(&action)
    square = @open.pop() 
    @filled.push(square)
    puts @open.inspect if square.nil?
    action.call(square)
    @open.push(@filled.pop())
  end  

  def solve()
    if @open.empty?
      # we're done, return solution
      return self
    else
      select_square do |square|
        square.try_available_values { return self if solve() }
      end
      # no result
      return nil
    end 
  end
  
  def get_squares() 
    (@open.collect {|s| [s.x, s.y, "."]} + @filled.collect {|s| [s.x, s.y, s.value]}).sort
  end

  def to_s() 
    result = ""
    get_squares().each { |s| result = "#{result}#{s[2]}#{s[1]==8 ? "\n" : "" }" }
    return result
  end
  
  def self.parse_board(string)
    input = string.gsub(/[^1-9\.]/,"").split("")
    filled = []
    input.each_with_index do |p,i|
      filled << SudokuSquare.new(i/9,i.modulo(9),p.to_i) if p != "."
    end
    return new(filled)
  end
end


if ARGV.empty?
  s=".9.8.5...42..........9....42.3....69.8..5..3.61....5.87....6..........17...4.9.5."
else 
  s=ARGV[0]
end

game=SudokuGame.parse_board(s)
puts "Trying to solve:"
puts game
if (game.solve())
  puts "\nFound Solution:"
  puts game
else 
  puts "\nNo Solution Found"
end
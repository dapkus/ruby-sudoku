require 'set'

class SudokuGame  
  @@MASK=[0x000, 0x001,0x002,0x004,0x008,0x010,0x020,0x040,0x080,0x100]
  @@MEMOIZE = [];  
  @@BOARD_ID=0

  def possible_values(coords)
    x,y=coords
    mask = ~(@horizontal[x] | @vertical[y] | @subgrid[subgrid(x,y)])
    @@MEMOIZE[512+mask] || (
      if (mask != 0)
        result = []
        @@MASK.each_with_index { |x,i| result << i if (mask & x) > 0 }
        @@MEMOIZE[512+mask] = result;
        result
      else 
        []
      end
    )
  end
 
   
  def fillin (coords, value)
    x,y=coords 
    @horizontal[x]=mark_used(@horizontal[x],value) 
    @vertical[y]=mark_used(@vertical[y],value) 
    @subgrid[subgrid(x,y)]=mark_used(@subgrid[subgrid(x,y)],value)
    @board[x][y]=value     
    return self     
  end
  
  def complete? () 
    @open.empty?
  end
   
  def to_s() 
    result = "<board #"+@boardid.to_s + ">\n"
    (0..8).each do |x|
      (0..8).each do |y|
        result = "#{result}#{@board[x][y] ? @board[x][y] : "."}"
      end
      result = "#{result}\n"
    end
    return result
  end

  def successors()
    square = @open[-1]
    remaining = @open[0..-2]
    return possible_values(square).collect {|value| clone(remaining).fillin(square, value)}
  end
  
  def self.parse_board(string)
    input = string.gsub(/[^1-9\.]/,"").split("")
    filled = []
    input.each_with_index do |p,i|
      filled << [[i/9,i.modulo(9)],p.to_i] if p != "."
    end
    return new(:starting_board => filled)
  end

  private

  def clone(open)
    return SudokuGame.new(
         :vertical => @vertical.clone,
         :horizontal => @horizontal.clone,
         :subgrid => @subgrid.clone,
         :board => @board.collect{|a| a.clone},
         :open => open    )
  end

  def mark_used (vector,val)
    mask = @@MASK[val]
    raise "constraint violation" if mask & vector > 0
    return mask | vector
  end 
  
  def initialize(params)
    @boardid = @@BOARD_ID
    @@BOARD_ID = @@BOARD_ID + 1
    @vertical = params[:vertical] || Array.new(9){0x000}
    @horizontal = params[:horizontal] || Array.new(9){0x000}    
    @subgrid = params[:subgrid] || Array.new(9){0x000}    
    @board = params[:board] || Array.new(9){Array.new(9)}
    @open = params[:open] 
    if @open.nil?
      @open = []
      (0..8).each{|x| (0..8).each {|y| @open << [x,y]}}
    end
    # prepopulate board if provided
    starting_board = params[:starting_board] 
    if starting_board
      starting_board.each do |square|
        coords = square[0]
        @open.delete_if{|sq| coords[0]==sq[0] && coords[1]==sq[1]}
        fillin(coords, square[1])
      end
    end
  end

  def subgrid(x,y)
    x/3 + (y/3)*3
  end
  
end

def search(game, merge_fn=lambda{|old, fresh| old + fresh}) # depth first
  queue=[game]
  while !queue.empty? 
    g=queue.pop
    return g if g.complete?
    queue = merge_fn.call(queue, g.successors())
  end    
  g.complete? ? g : nil
end

file = nil
if ARGV.empty?
  file = STDIN
else 
  file = open(ARGV[0])
end

file.each_line do |line|
  game=SudokuGame.parse_board(line)
  puts "Trying to solve:"
  puts game
  result = search(game)
  if (result)
    puts "\nFound Solution:"
    puts result
  else 
    puts "\nNo Solution Found"
  end
end

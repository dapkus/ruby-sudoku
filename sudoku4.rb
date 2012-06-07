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
        @@MEMOIZE[512+mask] = result.freeze
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
    @board = cons(cons(coords, value), @board)
    return self     
  end
  
  def complete? () 
    return @open == nil
  end
   
  def to_s() 
    result = "<board #"+@boardid.to_s + ">\n"
    grid = Array.new(81){"."};
    head = @board
    while head != nil
      coords, value = car(car(head)), cdr(car(head))
      grid[bindex(coords[0],coords[1])] = value
      head  = cdr(head)
    end

    (0..8).each do |x|
      (0..8).each do |y|
        result = "#{result}#{grid[bindex(x,y)]}"
      end
      result = "#{result}\n"
    end
    return result
  end

  def successors()
    square = car(@open)
    remaining = cdr(@open)
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
  def bindex(x,y)
    return 9*x+y
  end

  def clone(open)
    return SudokuGame.new(
         :vertical => @vertical.clone,
         :horizontal => @horizontal.clone,
         :subgrid => @subgrid.clone,
         :board => @board,
         :open => open)
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
    @board = params[:board]
    @open = params[:open]
    # prepopulate board if provided
    starting_board = params[:starting_board] 
    if starting_board
      filled = []
      starting_board.each do |square|
        coords = square[0]
        fillin(coords, square[1])
        filled << coords
      end
      res = nil
      (0..8).each{|x| (0..8).each {|y| res=cons([x,y], res) if not filled.include?([x,y])}}
      @open = res
    end
  end

  def subgrid(x,y)
    x/3 + (y/3)*3
  end
  
end

def cons(car, cdr)
  return [car,cdr]
end

def car(cons)
  cons[0]
end

def cdr(cons)
  return cons[1]
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


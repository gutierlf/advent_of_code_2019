require_relative "blocking_intcode_processor"

class Game
  attr_reader :score

  def initialize(program)
    @processor = BlockingIntcodeProcessor.new(program, [])
  end

  def test
    processor.process_all
    compute_tiles
  end

  def start(&block)
    processor.input_source = block
    processor.program[0] = 2
    processor.process_all
  end

  def step
    compute_tiles
  end

  def board
    compute_tiles
    grid.map do |row|
      row.map do |type|
        tile_chars.fetch(type)
      end.join("")
    end
  end

  def board_size
    @board_size || compute_board_size
  end

  def empties
    tiles_by_type.fetch(:empty, [])
  end

  def walls
    tiles_by_type.fetch(:wall, [])
  end

  def blocks
    tiles_by_type.fetch(:block, [])
  end

  def paddles
    tiles_by_type.fetch(:paddle, [])
  end

  def balls
    tiles_by_type.fetch(:ball, [])
  end

  private

  attr_reader :processor,:tiles, :grid
  attr_writer :score

  def compute_board_size
    positions = tiles.map(&:position)
    rows = positions.map(&:row).max + 1
    cols = positions.map(&:col).max + 1
    @board_size = [cols, rows]
  end

  def compute_tiles
    @tiles = outputs.each_slice(3).reduce([]) do |tiles, (col, row, id)|
      if [col, row] == [-1, 0]
        self.score = id
        tiles
      else
        tiles << Tile.new(Point.new(col, row), TILE_TYPES.fetch(id))
      end
    end
    cols, rows = board_size
    @grid = tiles.reduce(Array.new(rows) { Array.new(cols) }) do |grid, tile|
      grid[tile.position.row][tile.position.col] = tile.type
      grid
    end
  end

  def outputs
    processor.output
  end

  def tiles_by_type
    tiles_by_position.reduce({}) do |tiles_by_type, (position, type)|
      tiles_by_type[type] = tiles_by_type.fetch(type, []) << position
      tiles_by_type
    end
  end

  def tiles_by_position
    tiles.reduce({}) do |tiles_by_position, tile|
      tiles_by_position[tile.position] = tile.type
      tiles_by_position
    end
  end

  TILE_TYPES = {
    0 => :empty,
    1 => :wall,
    2 => :block,
    3 => :paddle,
    4 => :ball,
  }

  def tile_chars
    {
      :empty => " ",
      :wall => "█",
      :block => "▢",
      :paddle => "_",
      :ball => ".",
    }
  end
end

Tile = Struct.new(:position, :type)
Point = Struct.new(:col, :row)

class AI
  def initialize(game)
    @game = game
    @preamble = [0, 0, 0]
  end

  def next_move
    track_ball
    if preamble.empty?
      main_strategy
    else
      preamble.pop
    end
  end

  private

  attr_reader :game, :preamble
  attr_accessor :previous_ball, :current_ball, :ball_direction

  def track_ball
    self.previous_ball = current_ball
    balls = game.balls
    self.current_ball = balls.last.col
    return if previous_ball.nil?
    self.ball_direction = current_ball - previous_ball
  end

  def main_strategy
    # paddle = game.paddles.last.col

    ball_direction
  end
end

if __FILE__ == $0
  program = File.read("day13_input.txt").chomp.split(",").map(&:to_i)
  game = Game.new(program)
  game.test
  answer1 = game.blocks.length # => 341
  puts answer1

  def draw(g)
    g.board.join("\n")
  end

  game = Game.new(program)
  ai = AI.new(game)
  game.start do
    game.step
    ai.next_move
  end
  game.step
  answer2 = game.score # => 17138
  puts answer2
end

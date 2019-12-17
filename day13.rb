require_relative "blocking_intcode_processor"

class Game
  attr_reader :score

  def initialize(program)
    input_source = yield self
    @processor = BlockingIntcodeProcessor.new(program, [], input_source)
  end

  def start(&block)
    processor.program[0] = 2
    processor.process_all
    parse_program_output
  end

  def tiles
    parse_program_output
  end

  def ball
    col, row, _ = output_instructions
                    .select { |_, _, id| id == TILE_TYPES.key(:ball) }
                    .last
    Point.new(col, row)
  end

  private

  attr_reader :processor, :grid
  attr_writer :score

  def parse_program_output
    output_instructions.reduce([]) do |tiles, (col, row, id)|
      if [col, row] == [-1, 0]
        self.score = id
        tiles
      else
        tiles << Tile.new(Point.new(col, row), TILE_TYPES.fetch(id))
      end
    end
  end

  def output_instructions
    outputs.each_slice(3)
  end

  def outputs
    processor.output
  end

  TILE_TYPES = {
    0 => :empty,
    1 => :wall,
    2 => :block,
    3 => :paddle,
    4 => :ball,
  }
end

class GameWithoutQuarters < Game
  def initialize(program)
    @processor = IntcodeProcessor.new(program, [])
  end

  def start
    processor.process_all
    parse_program_output
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
end

class GamePresenter
  def initialize(game)
    @game = game
  end

  def present
    puts board
  end

  private

  attr_reader :game

  def board
    grid.map do |row|
      row.map do |type|
        tile_chars.fetch(type)
      end.join("")
    end.join("\n")
  end

  def grid
    game.tiles.reduce(empty_grid) do |grid, tile|
      grid[tile.position.row][tile.position.col] = tile.type
      grid
    end
  end

  def empty_grid
    cols, rows = board_size
    Array.new(rows) { Array.new(cols) }
  end

  def board_size
    @board_size ||= compute_board_size
  end

  def compute_board_size
    positions = game.tiles.map(&:position)
    rows = positions.map(&:row).max + 1
    cols = positions.map(&:col).max + 1
    [cols, rows]
  end

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

class AIInputSource
  def initialize(game)
    @game = game
    @preamble = [0, 0, 0]
  end

  def call
    track_ball
    preamble.pop || main_strategy
  end

  private

  attr_reader :game, :preamble
  attr_accessor :previous_ball, :current_ball, :ball_direction

  def track_ball
    self.previous_ball = current_ball
    self.current_ball = game.ball.col
    return if previous_ball.nil?
    self.ball_direction = current_ball - previous_ball
  end

  def main_strategy
    ball_direction
  end
end

if __FILE__ == $0
  program = File.read("day13_input.txt").chomp.split(",").map(&:to_i)
  game = GameWithoutQuarters.new(program)
  game.start
  answer1 = game.blocks.length # => 341
  puts answer1

  game = Game.new(program) { |g| AIInputSource.new(g) }
  game.start
  answer2 = game.score # => 17138
  puts answer2
end

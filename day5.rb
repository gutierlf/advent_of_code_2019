require 'rspec'
require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::WARN

def arguments_by_mode(args, modes, intcode)
  args.zip(modes).map do |arg, mode|
    mode == :position ? intcode[arg] : arg
  end
end

def advance_pointer(pointer, args_length)
  pointer + 1 + args_length
end

Op = Struct.new(:arg_length, :callable) do
  def call(*args)
    callable.call(*args)
  end
end

OPS = {
  1 =>
    Op.new(
      3,
      ->(intcode, args, modes, _, pointer) do
        input1, input2, _ = arguments_by_mode(args, modes, intcode)
        intcode[args[2]] = input1 + input2
        advance_pointer(pointer, args.length)
      end
    ),
  2 =>
    Op.new(
      3,
      ->(intcode, args, modes, _, pointer) do
        input1, input2, _ = arguments_by_mode(args, modes, intcode)
        intcode[args[2]] = input1 * input2
        advance_pointer(pointer, args.length)
      end
    ),
  3 =>
    Op.new(
      1,
      ->(intcode, args, _, input, pointer) do
        intcode[args[0]] = input
        advance_pointer(pointer, args.length)
      end
    ),
  4 =>
    Op.new(
      1,
      ->(intcode, args, modes, _, pointer) do
        output = arguments_by_mode(args, modes, intcode)
        puts output
        advance_pointer(pointer, args.length)
      end
    ),
  5 =>
    Op.new(
      2,
      ->(intcode, args, modes, _, pointer) do
        args = arguments_by_mode(args, modes, intcode)
        if args[0] != 0
          args[1]
        else
          advance_pointer(pointer, args.length)
        end
      end
    ),
  6 =>
    Op.new(
      2,
      ->(intcode, args, modes, _, pointer) do
        args = arguments_by_mode(args, modes, intcode)
        if args[0] == 0
          args[1]
        else
          advance_pointer(pointer, args.length)
        end
      end
    ),
  7 =>
    Op.new(
      3,
      ->(intcode, args, modes, _, pointer) do
        input1, input2, _ = arguments_by_mode(args, modes, intcode)
        intcode[args[2]] = input1 < input2 ? 1 : 0
        advance_pointer(pointer, args.length)
      end
    ),
  8 =>
    Op.new(
      3,
      ->(intcode, args, modes, _, pointer) do
        input1, input2, _ = arguments_by_mode(args, modes, intcode)
        intcode[args[2]] = input1 == input2 ? 1 : 0
        advance_pointer(pointer, args.length)
      end
    ),
}

def process_intcode(intcode, input, pointer=0)
  opcode_data = parse_opcode(intcode[pointer])
  return intcode if opcode_data.opcode == 99

  op = OPS.fetch(opcode_data.opcode)
  args = intcode[pointer + 1, op.arg_length]
  LOGGER.debug "args: #{args}"
  pointer = op.call(intcode, args, opcode_data.parameter_modes, input, pointer)
  process_intcode(intcode, input, pointer)
end

OpCodeData = Struct.new(:opcode, :parameter_modes)

def parse_opcode(value)
  LOGGER.debug "parsing opcode #{value}"
  value = value.to_s.rjust(5, "0")
  opcode = value[-2..-1].to_i
  modes =
    if opcode == 99
      nil
    else
      value[0...-2]
        .split("")
        .reverse
        .map { |ch| ch == "0" ? :position : :immediate}
    end
  OpCodeData.new(opcode, modes)
end

RSpec.describe "day 5" do
  describe "parse opcode" do
    it "example" do
      expect(parse_opcode(1002).opcode).to eq 2
      expect(parse_opcode(1002).parameter_modes).to eq [:position, :immediate, :position]
    end
  end
end

if __FILE__ == $0
  intcode = File.read("day5_input.txt").split(",").map(&:to_i)
  process_intcode(intcode.dup, 1)
  process_intcode(intcode.dup, 5)
end
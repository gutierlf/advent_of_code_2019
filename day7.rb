require "rspec"
require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::WARN

def maximize_thrust(phase_settings, &block)
  result = [0, phase_settings]
  phase_settings.permutation do |phases|
    thrust = block.call(phases)
    if thrust > result[0]
      result = [thrust, phases]
    end
  end
  result
end

def measure_thrust(program, phases)
  phases.reduce(0) do |input, phase|
    IntcodeProcessor.new(program, [input, phase]).process
  end
end

def measure_thrust_with_feedback(program, phases)
  processors = phases.map { |phase| IntcodeProcessor.new(program, [phase]) }
  thrust = i = 0
  while processors.any?(&:running?)
    processor = processors[i % phases.length]
    if processor.running?
      processor.add_input(thrust)
      thrust = processor.process
    end
    i += 1
  end
  thrust
end

class IntcodeProcessor
  attr_reader :program, :inputs
  attr_accessor :pointer, :output

  def initialize(program, inputs)
    @program = program.dup
    @inputs = inputs
    @pointer = 0
    @halted = false
    @operations = {
      1 => Add.new(self),
      2 => Multiply.new(self),
      3 => Input.new(self),
      4 => Output.new(self),
      5 => JumpIfTrue.new(self),
      6 => JumpIfFalse.new(self),
      7 => LessThan.new(self),
      8 => Equals.new(self),
    }
  end

  def process
    LOGGER.debug self.program
    opcode_data = OpcodeParser.new.parse(program[pointer])
    return halt if opcode_data.opcode == 99

    op = operations.fetch(opcode_data.opcode)
    args = program[pointer + 1, op.arg_length]
    LOGGER.debug "args: #{args}"
    op.call(args, opcode_data.parameter_modes)
    op.is_a?(Output) ? output : process
  end

  def running?
    !halted?
  end

  def add_input(input)
    @inputs.unshift(input)
  end

  private

  attr_reader :operations, :halted
  alias :halted? :halted

  def halt
    @halted = true
    output
  end
end

class Operation
  def initialize(processor)
    @processor = processor
  end

  private

  attr_reader :processor

  def arguments_by_mode(args, modes)
    args.zip(modes).map do |arg, mode|
      mode == :position ? processor.program[arg] : arg
    end
  end

  def advance_pointer(args_length)
    processor.pointer += 1 + args_length
  end

  def jump_pointer(addr)
    processor.pointer = addr
  end
end

class Add < Operation
  def arg_length
    3
  end

  def call(args, modes)
    input1, input2, _ = arguments_by_mode(args, modes)
    processor.program[args[2]] = input1 + input2
    advance_pointer(args.length)
  end
end

class Multiply < Operation
  def arg_length
    3
  end

  def call(args, modes)
    input1, input2, _ = arguments_by_mode(args, modes)
    processor.program[args[2]] = input1 * input2
    advance_pointer(args.length)
  end
end

class Input < Operation
  def arg_length
    1
  end

  def call(args, _)
    processor.program[args[0]] = processor.inputs.pop
    advance_pointer(args.length)
  end
end

class Output < Operation
  def arg_length
    1
  end

  def call(args, modes)
    processor.output = arguments_by_mode(args, modes)[0]
    LOGGER.debug processor.output
    advance_pointer(args.length)
  end
end

class JumpIfTrue < Operation
  def arg_length
    2
  end

  def call(args, modes)
    args = arguments_by_mode(args, modes)
    (args[0] != 0) ? jump_pointer(args[1]) : advance_pointer(args.length)
  end
end

class JumpIfFalse < Operation
  def arg_length
    2
  end

  def call(args, modes)
    args = arguments_by_mode(args, modes)
    (args[0] == 0) ? jump_pointer(args[1]) : advance_pointer(args.length)
  end
end

class LessThan < Operation
  def arg_length
    3
  end

  def call(args, modes)
    input1, input2, _ = arguments_by_mode(args, modes)
    processor.program[args[2]] = input1 < input2 ? 1 : 0
    advance_pointer(args.length)
  end
end

class Equals < Operation
  def arg_length
    3
  end

  def call(args, modes)
    input1, input2, _ = arguments_by_mode(args, modes)
    processor.program[args[2]] = input1 == input2 ? 1 : 0
    advance_pointer(args.length)
  end
end

class OpcodeParser
  OpCodeData = Struct.new(:opcode, :parameter_modes)

  def parse(value)
    LOGGER.debug "parsing opcode #{value}"
    value = value.to_s.rjust(5, "0")
    opcode = value[-2..-1].to_i
    modes = (opcode == 99) ? [] : parse_modes(value[0...-2])
    OpCodeData.new(opcode, modes)
  end

  private

  def parse_modes(value)
    value
      .split("")
      .reverse
      .map { |ch| ch == "0" ? :position : :immediate }
  end
end

RSpec.describe "day 7" do
  describe "step 1" do
    it "examples" do
      program = "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0".split(",").map(&:to_i)
      result = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
      expect(result).to eq [43210, [4,3,2,1,0]]

      program = "3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0".split(",").map(&:to_i)
      result = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
      expect(result).to eq [54321, [0,1,2,3,4]]

      program = "3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0".split(",").map(&:to_i)
      result = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
      expect(result).to eq [65210, [1,0,4,3,2]]
    end
  end

  describe "step 2" do
    it "examples" do
      program = "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5".split(",").map(&:to_i)
      result = maximize_thrust((5..9).to_a) { |phases| measure_thrust_with_feedback(program, phases)}
      expect(result).to eq [139629729, [9,8,7,6,5]]

      program = "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10".split(",").map(&:to_i)
      result = maximize_thrust((5..9).to_a) { |phases| measure_thrust_with_feedback(program, phases)}
      expect(result).to eq [18216, [9,7,8,5,6]]
    end
  end
end

if __FILE__ == $0
  program = File.read("day7_input.txt").split(",").map(&:to_i)
  answer1, _ = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
  puts answer1

  answer2, _ = maximize_thrust((5..9).to_a) { |phases| measure_thrust_with_feedback(program, phases)}
  puts answer2
end

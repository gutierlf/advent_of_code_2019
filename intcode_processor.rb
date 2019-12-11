require "logger"

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::WARN

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

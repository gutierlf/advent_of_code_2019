require "logger"

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::WARN

class IntcodeProcessor
  attr_reader :program, :inputs
  attr_accessor :pointer, :output, :relative_base

  def initialize(program, inputs)
    @program = ExtendingArray.new(program)
    @inputs = inputs
    @output = []
    @pointer = @relative_base = 0
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
      9 => AdjustRelativeBase.new(self),
    }
  end

  def process_to_output
    op = Operation.new(nil)
    until op.halt? || op.output?
      op = process_one_instruction
    end
    output.last
  end

  def process_all
    op = Operation.new(nil)
    until op.halt?
      op = process_one_instruction
    end
    output
  end

  def running?
    !halted?
  end

  def get_input
    inputs.pop
  end

  def add_input(input)
    @inputs.unshift(input)
  end

  private

  attr_reader :operations, :halted
  alias :halted? :halted

  def process_one_instruction
    LOGGER.debug self.program
    opcode_data = OpcodeParser.new.parse(program[pointer])
    if opcode_data.opcode == 99
      @halted = true
      Halt.new
    else
      process_one_op(opcode_data)
    end
  end

  def process_one_op(opcode_data)
    op = operations.fetch(opcode_data.opcode)
    args = program[pointer + 1, op.arg_length]
    LOGGER.debug "args: #{args}"
    op.call(args, opcode_data.parameter_modes)
    op
  end
end

class ExtendingArray
  def initialize(array)
    @array = array.dup
  end

  def [](*args)
    case args.length
    when 1
      index = args[0]
      read(index)
    when 2
      start = args[0]
      length = args[1]
      (start..(start + length - 1)).map { |i| read(i) }
    end
  end

  def []=(index, value)
    pad_to(index)
    array[index] = value
  end

  def to_s
    array.to_s
  end

  def inspect
    array.inspect
  end

  private

  def read(index)
    pad_to(index)
    array[index]
  end

  def pad_to(index)
    if index >= array.length
      array.insert(-1, *([0] * (index - array.length + 1)))
    end
  end

  attr_reader :array
end

class Halt
  def halt?
    true
  end
end

class Operation
  def initialize(processor)
    @processor = processor
    @address_modes = {
      position: ->(addr) { addr },
      relative: ->(addr) { addr + processor.relative_base}
    }
  end

  def halt?
    false
  end

  def output?
    false
  end

  private

  attr_reader :processor, :address_modes

  def arguments_by_mode(args, modes)
    args.zip(modes).map do |arg, mode|
      case mode
      when :position, :relative
        processor.program[address_by_mode(arg, mode)]
      else # :immediate
        arg
      end
    end
  end

  def address_by_mode(addr, mode)
    address_modes.fetch(mode).call(addr)
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
    input1, input2 = arguments_by_mode(args[0..1], modes[0..1])
    addr = address_by_mode(args[2], modes[2])
    processor.program[addr] = input1 + input2
    advance_pointer(args.length)
  end
end

class Multiply < Operation
  def arg_length
    3
  end

  def call(args, modes)
    input1, input2 = arguments_by_mode(args[0..1], modes[0..1])
    addr = address_by_mode(args[2], modes[2])
    processor.program[addr] = input1 * input2
    advance_pointer(args.length)
  end
end

class Input < Operation
  def arg_length
    1
  end

  def call(args, modes)
    addr = address_by_mode(args[0], modes[0])
    processor.program[addr] = processor.get_input
    advance_pointer(args.length)
  end
end

class Output < Operation
  def output?
    true
  end

  def arg_length
    1
  end

  def call(args, modes)
    output = arguments_by_mode(args, modes)[0]
    processor.output << output
    LOGGER.info output
    advance_pointer(args.length)
  end
end

class JumpIfTrue < Operation
  def arg_length
    2
  end

  def call(args, modes)
    value, addr = arguments_by_mode(args, modes)
    (value != 0) ? jump_pointer(addr) : advance_pointer(args.length)
  end
end

class JumpIfFalse < Operation
  def arg_length
    2
  end

  def call(args, modes)
    value, addr = arguments_by_mode(args, modes)
    (value == 0) ? jump_pointer(addr) : advance_pointer(args.length)
  end
end

class LessThan < Operation
  def arg_length
    3
  end

  def call(args, modes)
    input1, input2 = arguments_by_mode(args[0..1], modes[0..1])
    addr = address_by_mode(args[2], modes[2])
    processor.program[addr] = input1 < input2 ? 1 : 0
    advance_pointer(args.length)
  end
end

class Equals < Operation
  def arg_length
    3
  end

  def call(args, modes)
    input1, input2 = arguments_by_mode(args[0..1], modes[0..1])
    addr = address_by_mode(args[2], modes[2])
    processor.program[addr] = input1 == input2 ? 1 : 0
    advance_pointer(args.length)
  end
end

class AdjustRelativeBase < Operation
  def arg_length
    1
  end

  def call(args, modes)
    offset = arguments_by_mode(args, modes)[0]
    processor.relative_base += offset
    advance_pointer(args.length)
  end
end

class OpcodeParser
  OpCodeData = Struct.new(:opcode, :parameter_modes)

  PARAMETER_MODES = {
    "0" => :position,
    "1" => :immediate,
    "2" => :relative,
  }

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
      .map { |ch| PARAMETER_MODES.fetch(ch) }
  end
end

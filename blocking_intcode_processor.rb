require_relative "intcode_processor"

class BlockingIntcodeProcessor < IntcodeProcessor
  def initialize(program, inputs, input_source)
    super(program, inputs)
    @input_source = input_source
  end

  def get_input
    add_input(input_source.call) if inputs.empty?
    super
  end

  private

  attr_reader :input_source
end
require_relative "intcode_processor"

class BlockingIntcodeProcessor < IntcodeProcessor
  attr_accessor :input_source

  def get_input
    if inputs.empty? && !input_source.nil?
      input = input_source.call
      add_input(input)
    end
    super
  end
end
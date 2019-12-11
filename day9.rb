require "rspec"
require_relative "intcode_processor"

RSpec.describe "day 9" do
  describe "step 1" do
    it "examples" do
      program = "109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99".split(",").map(&:to_i)
      expect(IntcodeProcessor.new(program, nil).process_all).to eq program

      program = "1102,34915192,34915192,7,4,7,99,0".split(",").map(&:to_i)
      expect(IntcodeProcessor.new(program, nil).process_to_output.to_s.length).to eq 16

      program = "104,1125899906842624,99".split(",").map(&:to_i)
      expect(IntcodeProcessor.new(program, nil).process_to_output).to eq 1125899906842624
    end
  end
end

if __FILE__ == $0
  program = File.read("day9_input.txt").chomp.split(",").map(&:to_i)
  processor = IntcodeProcessor.new(program, [1])
  processor.process_all
  answer1 = processor.output.last
  puts answer1
end

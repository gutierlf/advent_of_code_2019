require 'rspec'

def process_intcode(intcode_in)
  intcode = intcode_in.dup
  instruction_length = 4
  instruction_start = 0
  loop do
    opcode, *inputs, output =
      intcode[instruction_start...(instruction_start + instruction_length)]
    break if opcode == 99
    op =
      case opcode
      when 1 then :+
      when 2 then :*
      end
    intcode[output] = inputs.map { |i| intcode[i] }.reduce(op)
    instruction_start += instruction_length
  end
  intcode
end

RSpec.describe "day 2" do
  describe "step 1" do
    describe "process_intcode" do
      it "calculates" do
        # 1,0,0,0,99 becomes 2,0,0,0,99 (1 + 1 = 2).
        # 2,3,0,3,99 becomes 2,3,0,6,99 (3 * 2 = 6).
        # 2,4,4,5,99,0 becomes 2,4,4,5,99,9801 (99 * 99 = 9801).
        # 1,1,1,4,99,5,6,0,99 becomes 30,1,1,4,2,5,6,0,99.
        expect(process_intcode([1, 0, 0, 0, 99])).to eq [2, 0, 0, 0, 99]
        expect(process_intcode([2,3,0,3,99])).to eq [2, 3, 0, 6, 99]
        expect(process_intcode([2,4,4,5,99,0])).to eq [2, 4, 4, 5, 99, 9801]
        expect(process_intcode([1,1,1,4,99,5,6,0,99])).to eq [30, 1, 1, 4, 2, 5, 6, 0, 99]
      end
    end
  end
end

def restore(intcode_in, noun, verb)
  intcode = intcode_in.dup
  intcode[1] = noun
  intcode[2] = verb
  intcode
end

def restore_1202(intcode_in)
  restore(intcode_in, 12, 2)
end

step1_input_intcode = File.read("day2_input.txt").split(",").map(&:to_i)
step1_restored_1202_intcode = restore_1202(step1_input_intcode)
step1_processed_1202 = process_intcode(step1_restored_1202_intcode)
answer1 = step1_processed_1202[0]
puts answer1

(0..99).each do |noun|
  (0..99).each do |verb|
    step2_restored_intcode = restore(step1_input_intcode, noun, verb)
    step2_processed = process_intcode(step2_restored_intcode)
    if step2_processed[0] == 19690720
      answer2 = 100 * noun + verb
      puts answer2
      break
    end
  end
end


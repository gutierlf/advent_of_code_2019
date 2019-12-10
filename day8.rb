require "rspec"

def step1(img)
  layer = fewest_zeros(img.layers)
  count(layer, 1) * count(layer, 2)
end

def fewest_zeros(layers)
  zeros = layers.map { |layer| count(layer, 0) }
  layer, _ = layers.zip(zeros).min { |a, b| a[1] <=> b[1] }
  layer
end

def count(layer, value)
  layer.flatten.select { |i| i == value }.length
end

class SpaceImage
  attr_reader :layers

  def initialize(data, rows, cols)
    @data, @rows, @cols = data, rows, cols
    parse
    flatten
  end

  def to_a
    flattened
  end

  def to_s
    to_a.map { |row| row.join("") }.join("\n")
  end

  def show
    puts to_s.gsub("1", ".").gsub("0", " ")
  end

  private

  attr_reader :data, :rows, :cols, :flattened

  def parse
    @layers = data
                .each_slice(rows * cols)
                .to_a
                .map { |line| to_layer(line) }
  end

  def flatten
    @flattened = to_layer(layers
                   .map { |layer| layer.flatten }
                   .transpose
                   .map { |pixels| pixels.find { |p| p != 2 } })
  end

  def to_layer(line)
    line.each_slice(cols).to_a
  end
end

RSpec.describe "day 8" do
  describe "step 1" do
    it "examples" do
      data = "123456789012".split("").map(&:to_i)
      dims = [2, 3]
      image = SpaceImage.new(data, *dims)
      expect(image.layers.length).to eq 2
      expect(image.layers[0]).to eq [[1,2,3],[4,5,6]]
      expect(image.layers[1]).to eq [[7,8,9],[0,1,2]]
    end
  end

  describe "step 2" do
    it "examples" do
      data = "0222112222120000".split("").map(&:to_i)
      dims = [2, 2]
      image = SpaceImage.new(data, *dims)
      expect(image.to_a).to eq [[0, 1], [1, 0]]
      expect(image.to_s).to eq "01\n10"
    end
  end
end

if __FILE__ == $0
  data = File.read("day8_input.txt").chomp.split("").map(&:to_i)
  dims = [6, 25]
  image = SpaceImage.new(data, *dims)
  answer1 = step1(image)
  puts answer1
  image.show
end
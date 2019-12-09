require "rspec"
require "set"

def orbital_transfers(root, from, to)
  path_from = root.path(from)
  path_to = root.path(to)
  (Set.new(path_from) ^ Set.new(path_to)).length - 2
end

def orbit_count_checksums(nodes_by_name)
  nodes_by_name.reduce(0) { |acc, (_, node)| acc + node.level }
end

def map_to_hash(map)
  map.reduce({}) do |h, cur|
    center, satellite = cur.split(")")
    h[center] = h.fetch(center, []) << satellite
    h
  end
end

def hash_to_tree(hash)
  root = node = Node.new("COM", nil, nil, 0)
  nodes_by_name = {
    "COM" => root
  }
  q = [node]
  until q.empty?
    node = q.pop
    satellites = hash.fetch(node.name, [])
    node.satellites = satellites.map { |s| Node.new(s, node, nil, node.level + 1) }
    nodes_by_name.merge!(node.satellites.map { |n| [n.name, n] }.to_h)
    q += node.satellites
  end
  [root, nodes_by_name]
end

Node = Struct.new(:name, :central_object, :satellites, :level) do
  def path(name, so_far=[])
    candidate = so_far + [self.name]
    return candidate if name == self.name
    satellites.flat_map do |s|
      s.path(name, candidate)
    end
  end
end

RSpec.describe "day 6" do
  describe "step 1" do
    let(:map) do
      map = <<~MAP
        COM)B
        B)C
        C)D
        D)E
        E)F
        B)G
        G)H
        D)I
        E)J
        J)K
        K)L
      MAP
      map.split("\n")
    end
    it "converts map to hash" do
      expect(map_to_hash(map)).to eq({
        "COM" => ["B"],
        "B" => ["C", "G"],
        "C" => ["D"],
        "D" => ["E", "I"],
        "E" => ["F", "J"],
        "G" => ["H"],
        "J" => ["K"],
        "K" => ["L"],
      })
    end
    it "converts hash to tree" do
      hash = {
        "B" => ["C", "G"],
        "COM" => ["B"],
        "G" => ["H"]
      }
      root, nodes_by_name = hash_to_tree(hash)
      expect(root.name).to eq "COM"
      expect(root.satellites.length).to eq 1
      expect(root.central_object).to eq nil
      expect(root.level).to eq 0

      g = nodes_by_name["G"]
      expect(g.satellites.length).to eq 1
      expect(g.central_object.name).to eq "B"
      expect(g.level).to eq 2
    end
    it "examples" do
      expect(orbit_count_checksums(map)).to eq 42
    end
  end
  describe "step 2" do
    let(:map) do
      map = <<~MAP
        COM)B
        B)C
        C)D
        D)E
        E)F
        B)G
        G)H
        D)I
        E)J
        J)K
        K)L
        K)YOU
        I)SAN
      MAP
      map.split("\n")
    end
    it "computes paths" do
      root, _ = hash_to_tree(map_to_hash(map))
      expect(root.path("SAN")).to eq ["COM", "B", "C", "D", "I", "SAN"]
      expect(root.path("YOU")).to eq ["COM", "B", "C", "D", "E", "J", "K", "YOU"]
    end
  end
end

if __FILE__ == $0
  map = File.read("day6_input.txt").split("\n")
  root, nodes_by_name = hash_to_tree(map_to_hash(map))
  answer1 = orbit_count_checksums(nodes_by_name)
  puts answer1
  answer2 = orbital_transfers(root, "YOU", "SAN")
  puts answer2
end

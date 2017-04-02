# TT.......SS
# TT.......SS
# TT....C..SS
# TT.......SS
# TT.......SS

# T => Tree
# C => Character, woodcutter here
# S => Storage zone

require_relative "./game_world"

class WorldBuilder
  def initialize(template)
    @template_data = template.split("\n").keep_if{|line| line.length > 0}.map{|line| line.split("") }
  end

  def build
    map   = Map.new(width: @template_data.first.length, height: @template_data.length)
    chars = []
    @template_data.each_with_index do |line, y|
      line.each_with_index do |symbol, x|
        case symbol
        when "T"
          map[x, y] = Tree.new(x, y)
        when "B"
          map[x, y] = BerryBush.new(x, y, 1000000) # really, really big berry bush to keep them fed
        when "W"
          chars << Character.new(x: x, y: y, name: "Char ##{chars.length + 1}", type: :woodcutter)
        end
      end
    end

    game_world = GameWorld.new(chars, map)

    @template_data.each_with_index do |line, y|
      line.each_with_index do |symbol, x|
        case symbol
        when "S"
          SetStorageGameMode.new.perform(x, y)
        end
      end
    end

    game_world
  end
end

template = """
TT.......SS
TT...B...SS
TT....W..SS
TT.......SS
TT.......SS
"""
world = WorldBuilder.new(template).build

cut_game_mode = CutGameMode.new
$map.each do |elem|
  if elem.is_a? Tree 
    cut_game_mode.perform(elem.x, elem.y)
  end
end

def no_more_trees?
  $map.count{|thing| thing.is_a? Tree } == 0
end

def unstored_logs
  $map.find_all{|thing| thing.is_a? LogsPile }.count do |logs_pile|
    x = logs_pile.x 
    y = logs_pile.y
    !$zones.find{|zone| zone.x == x and zone.y == y}
  end
end

def all_logs_in_stores?
  unstored_logs == 0
end

def done?
  no_more_trees? && all_logs_in_stores?
end

iterations = 0
while !done?
  iterations += 1
  trees_count   = $map.count{|thing| thing.is_a? Tree }
  world.update
end

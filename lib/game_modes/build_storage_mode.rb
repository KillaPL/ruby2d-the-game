class StorageZone
  attr_reader :x, :y 
  
  def initialize(x, y)
    @x = x 
    @y = y

    x_coord = x * PIXELS_PER_SQUARE
    y_coord = y * PIXELS_PER_SQUARE

    @image = Square.new(x_coord, y_coord, PIXELS_PER_SQUARE, [1, 1, 1, 0.2])
    @image.remove
    @image.add
  end

  def has_place_for?(object_class)
    map_object = $map[@x, @y]

    if map_object.nil?
      true
    elsif map_object.is_a? object_class
      map_object.can_carry_more?
    end
  end

  def remove
    @image.remove
  end
end

class ZonesList
  include Enumerable

  def initialize
    @grid = Grid.new
  end

  def [](x, y)
    @grid[x, y]
  end

  def []=(x, y, value)
    @grid[x, y] = value
  end

  def each(&block)
    @grid.each(&block)
  end
end


# TODO: Have people carry stuff to storage if the storage was build earlier and tree cut later
# and also if the tree was cut earlier and storage was build later

$zones = ZonesList.new

class BuildStorageMode
  def click(x, y)
    in_game_x = x / PIXELS_PER_SQUARE
    in_game_y = y / PIXELS_PER_SQUARE


    if $zones[in_game_x, in_game_y].nil?
    # $zones[x, y] && $zones[x, y].remove
      $zones[in_game_x, in_game_y] = StorageZone.new(in_game_x, in_game_y)
      if $map[in_game_x, in_game_y]
        $map[in_game_x, in_game_y].rerender
      end
    end
  end
end

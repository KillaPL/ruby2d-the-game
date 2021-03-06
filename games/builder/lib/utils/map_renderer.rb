module MapRenderer
  class MapRenderable
    def initialize(x, y)
      @x = x
      @y = y
      @x_offset = $map_position.offset_x
      @y_offset = $map_position.offset_y
      $map_position.add_observer(self, :update_offset)
    end

    def add
      @x_offset = $map_position.offset_x
      @y_offset = $map_position.offset_y
      $map_position.add_observer(self, :update_offset)
      @content.x = @x * PIXELS_PER_SQUARE + @x_offset
      @content.y = @y * PIXELS_PER_SQUARE + @y_offset
      @content.add
    end

    def remove
      @content.remove
      $map_position.delete_observer(self)
    end

    def x=(x)
      @x = x
      @content.x = @x * PIXELS_PER_SQUARE + @x_offset
    end

    def y=(y)
      @y = y
      @content.y = @y * PIXELS_PER_SQUARE + @y_offset
    end

    def color=(color)
      @content.color = color
    end

    def color
      @content.color
    end

    def update_offset(x_offset, y_offset)
      @x_offset = x_offset
      @y_offset = y_offset

      @content.x = @x * PIXELS_PER_SQUARE + @x_offset
      @content.y = @y * PIXELS_PER_SQUARE + @y_offset
    end
  end

  class MapImage < MapRenderable
    def initialize(x, y, path, z)
      super(x, y)
      @content = Image.new(
        x: x * PIXELS_PER_SQUARE + @x_offset,
        y: y * PIXELS_PER_SQUARE + @y_offset,
        path: path,
        z: z
      )
    end
  end

  class MapSquare < MapRenderable
    def initialize(x, y, size, color, z)
      super(x, y)
      @content = Square.new(
        x: x * PIXELS_PER_SQUARE + @x_offset,
        y: y * PIXELS_PER_SQUARE + @y_offset,
        size: size * PIXELS_PER_SQUARE,
        color: color,
        z: z
      )
    end
  end

  class MapRectangle < MapRenderable
    def initialize(x, y, width, height, color, z)
      super(x, y)
      @content = Rectangle.new(
        x: x * PIXELS_PER_SQUARE + @x_offset,
        y: y * PIXELS_PER_SQUARE + @y_offset,
        width: width * PIXELS_PER_SQUARE,
        height: height * PIXELS_PER_SQUARE,
        color: color,
        z: z
      )
    end
  end

  class MapText < MapRenderable
    def initialize(x, y, text, font_size, font, z)
      super(x, y)
      @content = Text.new(
        x: x + @x_offset,
        y: y + @y_offset,
        text: text,
        size: font_size,
        font: font,
        z: z
      )
    end

    def update_offset(x_offset, y_offset)
      @x_offset = x_offset
      @y_offset = y_offset

      @content.x = @x + @x_offset
      @content.y = @y + @y_offset
    end
  end

  def self.image(x, y, path, z = 0, color = nil)
    image = MapImage.new(x, y, path, z)
    image.color = color unless color.nil?
    image
  end

  def self.square(x, y, size, color = "black", z = 0)
    MapSquare.new(x, y, size, color, z)
  end

  def self.rectangle(x, y, width, height, color = "black", z = 0)
    MapRectangle.new(x, y, width, height, color, z)
  end

  def self.text(x, y, text, font_size, font, z = 0)
    MapText.new(x, y, text, font_size, font, z)
  end
end

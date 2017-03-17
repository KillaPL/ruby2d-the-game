require 'ruby2d'
require_relative "./utils/pathfinder"
require_relative "./utils/map"
require_relative "./utils/character"
require_relative "./utils/path"
require_relative "./utils/tree"
require_relative "./utils/background"



# http://www.ruby2d.com/learn/reference/
PIXELS_PER_SQUARE = 16
SQUARES_WIDTH     = 60
SQUARES_HEIGHT    = 40
WIDTH  = PIXELS_PER_SQUARE * SQUARES_WIDTH
HEIGHT = PIXELS_PER_SQUARE * SQUARES_HEIGHT

# PROFIDE DEFAULT FONT?
# SHOW A NICE ERROR MESSAGE IF THERE IS NO FILE IN IMAGE
# YIELD TICK NUMBER TO AN UPDATE?
# USE SPRITE? OR BIGGER PICTURE?
# ADD EXITING ON ESCAPE
# CREATE AN ISSUE ABOUT IMAGES NOT WORKING IN WEB VERSION
# LAY DOWN TREES AND BUSHES (OF LOVE)

# http://karpathy.github.io/2015/05/21/rnn-effectiveness/
# ANDREJ KARPATHY LSTM

# LOOK CAREFULLY AT TENSORFLOW

# Look into neural networks to implement AI, what person wants to do ans so on

# LET THE SYSTEM USE SYSTEMS ARIAL BY DEFAULT?
# LET THE SYSTEM SHOW WHAT FONTS ARE AVAILABLE?

# RENDER WHAT PERSON HAS IN RIGHT AND LEFT HAND?
# ANIMATION WHEN THOSE TOOLS ARE USED? LIKE CHOPPING WOOD?
# ONLY ALLOW HAVING LEFT HAND AND RIGHT HAND FOR NOW

# ONLY RENDERING METHODS SHOULD BE CONCERNED WITH PIXELS PER SQUARE
# REST SHOULD ONLY HANDLE ABOUT IN-GAME POSITION

# SET GLOBAL VARIABLES WITH $!
# BUG, CHARACTER SHOULD NOT BE ABLE TO FINISH ON TREE
# BUG, IF STEP IS TRIED INTO IMPOSSIBLE PLACE, GAME HANGS

set({
  title: "The Game Continues",
  width: WIDTH,
  height: HEIGHT,
  diagnostics: true
})

class Position
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end
end

$background = Background.new
$character = Character.new(30, 20)


@fps_text = Text.new(15, 15, "fps: 0", 40, "fonts/arial.ttf")
def draw_fps
  fps = get(:fps).to_i
  @fps_text.remove
  @fps_text.text = "fps: #{fps}"
  @fps_text.add
end

@old_mouse_background_x = 0
@old_mouse_background_y = 0
@mouse_background_image = Square.new(100, 100, PIXELS_PER_SQUARE, [1, 1, 1, 0.2])

def draw_mouse_background
  x = (get(:mouse_x) / PIXELS_PER_SQUARE)
  y = (get(:mouse_y) / PIXELS_PER_SQUARE)

  @mouse_background_image.remove
  @mouse_background_image.x = x * PIXELS_PER_SQUARE
  @mouse_background_image.y = y * PIXELS_PER_SQUARE
  @mouse_background_image.add
end

@map = Map.new(width: SQUARES_WIDTH, height: SQUARES_HEIGHT)
@path = Path.new

def draw_map_things
  @map.rerender
end

def move_character
  if @path.any?
    next_step = @path.shift_node
    $character.update(next_step.x, next_step.y)
  end
end

def calculate_path_to(x, y)
  # puts "Looking path from (#{@character_position.x}, #{@character_position.y}) to  (#{x}, #{y})"
  start       = { 'x' => $character.x, 'y' => $character.y }
  destination = { 'x' => x, 'y' => y }
  result      = PathFinder.new(start, destination, @map).search
  @path.update(result)
end


class ActionPoint
  def initialize
    @x = 0
    @y = 0
    @rendered = Square.new(0, 0, PIXELS_PER_SQUARE, [56.0 / 255, 25.0 / 255, 4.0 / 255, 0.6])
  end

  def update_position(x, y)
    @rendered.remove
    @x = x
    @y = y
    @rendered.x = x
    @rendered.y = y
    @rendered.add
  end
end

@action_point = ActionPoint.new

@tick = 0
def update_with_tick(&block)
  update do
    block.call(@tick)
    @tick = (@tick + 1) % 60
  end
end

update_with_tick do |tick|
  draw_fps if tick % 30 == 0
  draw_mouse_background
  move_character if tick % 4 == 0
end

def mouse_clicked_on(x, y)
  x_position = PIXELS_PER_SQUARE * (x / PIXELS_PER_SQUARE)
  y_position = PIXELS_PER_SQUARE * (y / PIXELS_PER_SQUARE)

  @action_point.update_position(x_position, y_position)
  calculate_path_to(x / PIXELS_PER_SQUARE, y / PIXELS_PER_SQUARE)
end

on(mouse: 'any') do |x, y|
  mouse_clicked_on(x, y)
end

on_key do |key|
  if key == "escape"
    close
  end

  puts "pressed key: #{key}"
end



$background.rerender
$character.rerender
draw_map_things

show

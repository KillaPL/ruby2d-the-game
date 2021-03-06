require "pathname"

engine_path = Pathname.new("./../../").realpath.to_s
$LOAD_PATH.unshift(engine_path)

require_relative "./game_world"
require_relative "./controls"
require_relative "./update"

set({
  title: "The Game Continues",
  width: WIDTH,
  height: WORLD_HEIGHT + MENU_HEIGHT,
  # diagnostics: true
})


# GAME SETUP

def start_game!
  $map_position = MapPosition.new
  $idlers_count = IdlersCount.new

  characters_list = [
    Character.new(x: 30, y: 20, name: "Johann", type: :woodcutter),
    Character.new(x: 31, y: 20, name: "Franz", type: :fisherman),
    Character.new(x: 32, y: 20, name: "Karl", type: :gatherer),
    Character.new(x: 33, y: 20, name: "Joseph", type: :craftsman),
  ]
  creatures_list = [
    Goat.new(34, 20)
  ]
  map = MapGenerator.new(WORLD_SQUARES_WIDTH, WORLD_SQUARES_HEIGHT).generate

  characters_list.each do |character|
    map[character.x, character.y].clear_content
  end

  $game_world = GameWorld.new(
    characters_list: characters_list,
    creatures_list: creatures_list,
    map: map
  )

  $structures << Fireplace.new
  $background = Background.new

  $fps_drawer = FpsDrawer.new
  $menu = Menu.new
  $inspection_menu = InspectionMenu.new(INSPECTION_MENU_WIDTH, INSPECTION_MENU_HEIGHT, WORLD_WIDTH)

  fps = get(:fps)
  $fps_drawer.rerender(fps)
end

start_game!

#
# Autoplayer!
#

class Autoplayer
  def initialize
    @done  = false
    @phase = 1
  end

  def build_phase_one
    cut_trees(15)
    gather_plants(10)
    set_zone(StorageZone)
    set_zone(PastureZone)
    set(Workshop)
    set(Kitchen)
    set(Fishery)

    @phase = 2
  end

  def perform!
    if @phase == 2
      if $structures.any?{|s| s.is_a? Workshop }
        workshop = $structures.find{|s| s.is_a? Workshop }
        3.times do
          workshop.request(Table)
        end
        3.times do
          workshop.request(Barrel)
        end
        3.times do
          workshop.request(Crate)
        end
        2.times do
          workshop.request(Door)
        end
        @phase += 1
      end
    end
  end

  private

  # TODO Make sure structure is at least 1 spot from any other structures and zones
  # Looks nicer :3
  # TODO: And at least 4 spots away from fireplace, or more
  def set(structure)
    fireplace = $structures.find{|s| s.is_a? Fireplace }

    build_workshop_game_mode = BuildGameMode.new(structure)
    spot = $map.spots_near(fireplace).find do |free_spot|
      structure_template = Structure::Base.new(free_spot.x, free_spot.y, structure.size)
      structure_template.distance_to(fireplace) > 4 and build_workshop_game_mode.terrain_clear?(free_spot.x, free_spot.y)
    end

    build_workshop_game_mode.perform(spot.x, spot.y)
  end

  def set_zone(zone_type)
    size = 6
    fireplace = $structures.find{|s| s.is_a? Fireplace }

    spot = $map.spots_near(fireplace).find do |free_spot|
      x = free_spot.x
      y = free_spot.y
      (x..(x + size - 1)).to_a.product((y..(y + size - 1)).to_a).all? do |arr|
        !$map[arr[0], arr[1]].nil? and GameWorld.things_at(arr[0], arr[1]).empty?
      end
    end

    x_range = (spot.x..(spot.x + size - 1))
    y_range = (spot.y..(spot.y + size - 1))

    SetZoneGameMode.new(zone_type).perform(x_range, y_range)
  end

  def cut_trees(count)
    fireplace = $structures.find{|s| s.is_a? Fireplace }
    cut_game_mode = CutGameMode.new

    trees_spots = $map.spots_near(fireplace).find_all do |spot|
      spot.content.is_a? Tree
    end.take(count)

    trees_spots.each do |tree_spot|
      x = tree_spot.x
      y = tree_spot.y
      cut_game_mode.perform_point(x, y)
    end
  end

  def gather_plants(count)
    fireplace = $structures.find{|s| s.is_a? Fireplace }
    gather_game_mode = GatherGameMode.new

    bushes_spots = $map.spots_near(fireplace).find_all do |spot|
      spot.content.is_a? BerryBush
    end.take(count)

    bushes_spots.each do |bush_spot|
      x = bush_spot.x
      y = bush_spot.y
      gather_game_mode.perform_point(x, y)
    end
  end
end

# @autoplay = true
if @autoplay
  $autoplayer = Autoplayer.new
  $autoplayer.build_phase_one
end


# START!
show

# TODO:
# Think about having someting like n.+(other, modulo) functions. This will perform modulo adding.
# This should be really fast, because no checking is needed for overflow if module is small enough

# 2d top view rune clone? In which you walk and control your character from the top and fight other people?
# Warhammer game?


# http://gameprogrammingpatterns.com/game-loop.html

# Should jobs or actions be implemented as enumerator?


# Having a simulation where you can watch city being build is one idea
# Other is: build the city yourself, like a designer
# Fill it with actors that do their own job, each one has their role to fill
#   their own needs etc

# - Introduce some sort of adventure, reality to it
# - and allow player inside, let him do things

# - Kontrakt oldenhallera?
# - Kreutzhoffen !!!!!!
#   - Oh I love that place

# Implement some nice system to find out where and when no path error happens

# Prepare presentation about ruby2d and the game
  # - write simple space invader?

# I need this to provide nice menu for structures

# Try creating initial version of warhammer?

# Observable based visual things? Sort of based on ember ?
# This could help having menu reorganised only when needed


# Next things:
#   - change implementation of workshop inspection to remove events
#   - some sort of autorequire that will work in all platforms!
#   - drinking mechanism?
#   - new menu with dropdown selects

# fix that fucking annoying infinite walking loop


# instead of producing actions, we should only have jobs and update jobs
# this way we can, for example, add something to the beginning of queue if something happens
# And we avoid doing all of the action chaining

# Maybe have some cave crawling game? Labirynth crawler with fight?
# https://gamedevelopment.tutsplus.com/tutorials/generate-random-cave-levels-using-cellular-automata--gamedev-9664
# http://www.roguebasin.com/index.php?title=Main_Page
# http://www.roguebasin.com/index.php?title=Random_Walk_Cave_Generation
# http://www.roguebasin.com/index.php?title=Dynamically_Sized_Maze
# http://www.roguebasin.com/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels

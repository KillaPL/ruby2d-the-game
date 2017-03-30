require 'ruby2d'
require 'perlin_noise'

require_relative "./items/log"
require_relative "./items/berries"

require_relative "./map_elements/tree"
require_relative "./map_elements/logs_pile"
require_relative "./map_elements/berry_bush"

require_relative "./core_ext/time"
require_relative "./core_ext/integer"
require_relative "./core_ext/float"

require_relative "./actions/action_base"
require_relative "./actions/move_action"
require_relative "./actions/cut_tree_action"
require_relative "./actions/cut_berry_bush_action"
require_relative "./actions/pick_action"
require_relative "./actions/put_action"
require_relative "./actions/sleep_action"
require_relative "./actions/gather_berries_action"
require_relative "./actions/eat_action"

require_relative "./jobs/cut_tree_job"
require_relative "./jobs/cut_berry_bush_job"
require_relative "./jobs/carry_log_job"

require_relative "./utils/pathfinder"
require_relative "./utils/grid"
require_relative "./utils/random_noise_generator"
require_relative "./utils/map"
require_relative "./utils/character"
require_relative "./utils/background"
require_relative "./utils/mouse_background_drawer"
require_relative "./utils/day_and_night_cycle"
require_relative "./utils/fireplace"
require_relative "./utils/job_list"
require_relative "./utils/menu"
require_relative "./utils/zones_list"

require_relative "./zones/storage_zone"

require_relative "./game_modes/cut_game_mode"
require_relative "./game_modes/do_nothing_game_mode"
require_relative "./game_modes/build_storage_mode"

require_relative "./gui/fps_drawer"
require_relative "./gui/game_speed"
require_relative "./gui/inspection_menu"


# http://www.ruby2d.com/learn/reference/
PIXELS_PER_SQUARE = 16
SQUARES_WIDTH     = 60
SQUARES_HEIGHT    = 40

INSPECTION_MENU_WIDTH = 200

WORLD_WIDTH = PIXELS_PER_SQUARE * SQUARES_WIDTH
WIDTH  = WORLD_WIDTH + INSPECTION_MENU_WIDTH
WORLD_HEIGHT = PIXELS_PER_SQUARE * SQUARES_HEIGHT
MENU_HEIGHT = 5 * PIXELS_PER_SQUARE

INSPECTION_MENU_HEIGHT = WORLD_HEIGHT + MENU_HEIGHT

def rendered_objects
  (get :window).objects
end

set({
  title: "The Game Continues",
  width: WIDTH,
  height: WORLD_HEIGHT + MENU_HEIGHT,
  # diagnostics: true
})


$characters_list = [
  Character.new(x: 30, y: 20, name: "Johann"),
  Character.new(x: 31, y: 20, name: "Franz")
]
$map = Map.new(width: SQUARES_WIDTH, height: SQUARES_HEIGHT)
$background = Background.new

$fps_drawer = FpsDrawer.new
$mouse_background_drawer = MouseBackgroundDrawer.new
$menu = Menu.new
$day_and_night_cycle = DayAndNightCycle.new(WORLD_HEIGHT, WORLD_WIDTH)
$game_speed = GameSpeed.new
$fireplace = Fireplace.new
$job_list = JobList.new
$zones = ZonesList.new

$inspection_menu = InspectionMenu.new(INSPECTION_MENU_WIDTH, INSPECTION_MENU_HEIGHT, WORLD_WIDTH)
$inspection_menu.characters = $characters_list

$previous_mouse_over = :game_window
$seconds_per_tick = 1 #0.25 Ideally I would like it to be 0.25, but that makes the game rather boring

update do 
  # Only show mouse button if it's on map
  # don't show anything if it's on menu
  # $mouse_background_drawer.remove
  if $menu.contains?(get(:mouse_x), get(:mouse_y))
    if $previous_mouse_over == :menu
      $menu.unhover
    elsif $previous_mouse_over == :game_window
      $mouse_background_drawer.remove
      $previous_mouse_over = :menu
    end
    $menu.hover(get(:mouse_x), get(:mouse_y))
  else
    if $previous_mouse_over == :menu
      $menu.unhover
      $previous_mouse_over = :game_window
    elsif $previous_mouse_over == :game_window
      $mouse_background_drawer.remove
    end
    mouse_x = (get(:mouse_x) / PIXELS_PER_SQUARE)
    mouse_y = (get(:mouse_y) / PIXELS_PER_SQUARE)
    $mouse_background_drawer.render(mouse_x, mouse_y)
  end

  # APPROXIMATELY 2 times per second
  if rand < 0.03
    fps = get(:fps)
    $fps_drawer.rerender(fps)
  end

  $game_speed.value.times do
    $characters_list.each do |character|
      unless character.has_action?
        if character.needs_own_action?
          character.set_own_action
        else

          # TODO: Character should refuse to take action
          # TODO: If his mood is too bad, for example too sleepy and too hungry to work

          job = $job_list.get_job
          if job
            action = job.action_for(character)
            character.action = action
            job.taken = true
          end
        end
      end
      character.update($seconds_per_tick)
    end

    $day_and_night_cycle.update
  end

  $inspection_menu.rerender_progress_bars

  $fireplace.update($day_and_night_cycle.time)
end

on(mouse: 'any') do |x, y, thing|
  # puts "#{x} #{y} #{thing}"
  # Only take consider user action if it clicks on map
  # not if it clicks on menu
  if $menu.contains?(x, y)
    $menu.click(x, y)
  else
    $menu.game_mode.click(x, y)
  end
end

on key_down: "space" do
  if @paused
    $game_speed.set(@previous_game_speed)
    @previous_game_speed = nil
    @paused = nil
  else
    @previous_game_speed = $game_speed.value
    $game_speed.set(0)
    @paused = true
  end
end

on_key do |key|
  if key == "escape"
    puts "pressed key: #{key}"
    close
  end

  if key == "1"
    $game_speed.set(1)
  end

  if key == "2"
    $game_speed.set(5)
  end

  if key == "3"
    $game_speed.set(100)
  end

  if key == "4"
    $game_speed.set(250)
  end

  if key == "5"
    $game_speed.set(1000)
  end

  if key == "q"
    p $job_list
  end

  if key == "p"
    if @profiling
      result = RubyProf.stop
      printer = RubyProf::GraphHtmlPrinter.new(result)

      Pathname.new(FileUtils.pwd).join("./profiles/in-game.html").open("w+") do |file|
        printer.print(file, {})
      end
      close
    else
      Text.new(200, 15, "PROFILING CPU", 40, "fonts/arial.ttf")

      require "ruby-prof"
      require "pathname"

      RubyProf.start
      @profiling = true
    end
  end

  if key == "o"
    if @profiling
      result = RubyProf.stop
      printer = RubyProf::GraphHtmlPrinter.new(result)

      Pathname.new(FileUtils.pwd).join("./profiles/in-game-allocations.html").open("w+") do |file|
        printer.print(file, {})
      end
      close
    else
      Text.new(200, 15, "PROFILING MEMORY", 40, "fonts/arial.ttf")
      require "ruby-prof"
      require "pathname"

      RubyProf.measure_mode = RubyProf::ALLOCATIONS
      RubyProf.start
      @profiling = true
    end
  end
end

$background.rerender
$characters_list.each(&:rerender)
$map.rerender
$fireplace.rerender
$menu.rerender

fps = get(:fps)
$fps_drawer.rerender(fps)

$day_and_night_cycle.rerender
$inspection_menu.rerender

# 
# Autoplayer!
#

# Designate storage place, 5x5 in size, above and to the right of fireplace
build_storage_mode = BuildStorageMode.new
storage_top_left_x = $fireplace.x + 2
storage_top_left_y = $fireplace.y - 7

(storage_top_left_x..(storage_top_left_x+5)).each do |x|
  (storage_top_left_y..(storage_top_left_y+5)).each do |y|
    build_storage_mode.perform(x, y)
  end
end

# Cut whatever is in place of that storage mode

cut_game_mode = CutGameMode.new
designated_trees = []

$zones.each do |zone|
  if $map[zone.x, zone.y].is_a?(Tree)
    designated_trees.push($map[zone.x, zone.y])
  end
  cut_game_mode.perform(zone.x, zone.y)
end

# Cut 10 trees exactly, closest to the fireplace

if designated_trees.count < 10
  puts "need #{10 - designated_trees.count} more trees"

  need_more_trees_count = 10 - designated_trees.count

  $map.find_all_closest_to($fireplace) do |map_element|
    map_element.is_a?(Tree) and !designated_trees.include?(map_element)
  end.take(need_more_trees_count).each do |tree|
    cut_game_mode.perform(tree.x, tree.y)
  end
end



show



# SHOW A NICE ERROR MESSAGE IF THERE IS NO FILE IN IMAGE
# CREATE AN ISSUE ABOUT IMAGES NOT WORKING IN WEB VERSION

# http://karpathy.github.io/2015/05/21/rnn-effectiveness/
# ANDREJ KARPATHY LSTM

# LOOK CAREFULLY AT TENSORFLOW

# Look into neural networks to implement AI, what person wants to do ans so on

# LET THE SYSTEM USE SYSTEMS ARIAL BY DEFAULT?
# LET THE SYSTEM SHOW WHAT FONTS ARE AVAILABLE?

# RENDER WHAT PERSON HAS IN RIGHT AND LEFT HAND?
# ANIMATION WHEN THOSE TOOLS ARE USED? LIKE CHOPPING WOOD?
# ONLY ALLOW HAVING LEFT HAND AND RIGHT HAND FOR NOW

# Have menu options to choose between
  #   - dormitory 

# pre-calculate where passable areas are with flooding the map from characters position
# Use that information to help with maps passable information

# Then figure out logistics of building a house

# Maybe have queue of actions per person? Like: My main goal for now is to build a house
# But from time to time I have to stop it to sleep and eat
# But when I wake up, I want to get back to it

# With that introduce config file with all the informations that need to be setup
# like how long does it take to move, how fast do people get hungry and so on

# When creating buildings is ready, look into feeding people.
# When that is done, look into having a settlement that is sentient
# And gives jobs to make itself functional

# Introduce drinking
# Introduce cooking
# Introduce people types, accepting various jobs, or prioritising varous jobs
# Introduce berry bush gathering
# Maybe have the settlement require a stockpile, and in that stockpile a specific amount of food and wood?
# With that stockpile have barrels, boxes and saxes for things?

# have workbench for making wood things

# Have items like axes, fishing rods, waterskins and so on
# Organised crafting?
# Logging of various decisions people made/settlement requires?

# REMOVABLE MODULE TO UNIFY MAP BEHAVIOR? ADDING AND REMOVING TO RENDER BEHAVIOR?
# RENDERABLE MODULE?

# TALK ABOUT INTRODUCING EXPLICIT Z-INDEX TO RENDERED THINGS?

# Start writing tests for those corner cases we are starting to pile up

# **********************************
# You have many things now!
# Start working on giving back to community!
# You stared issues on github, help solving them!
# ***********************************

# Prepare srug presentation?
# About all of this?

# FONT IN WEB VERSION DOES NOT RENDER IN PROPER SIZE

# GET WIDTH FROM TEXT?
# To build something around it?

# INTRODUCE N CHARACTERS

# Introduce roads
# when person goes to road it's noted
# and when there is enough of those 
# road (in steps) is created
# it should be easier to walk on road 
# (smaller cost)
# thus reinforcing roads creation

# Random visitors should visit city 
# and want to eat something and stay for a night 
# and want to leave money
# later this should be only near trade routes
# or on crossing of trade routes

# later there should be various kind of cities with various
# interesting things

# Check The Sims on statistics for how peoples needs change in time
# Like sleeping, eating and so on
# Aw man, there is a lot of good stuff in sims wiki pages

# Write documentation? For myself and others, to inform what various concepts are?
# Add right menu with tabs:
  # - show jobs list 
  # - show characters

# BUG WHEN JOB IS GIVEN TO CUT TREE TO WHICH THERE IS NO PATH
# THE PATH IS ABANDONED, BUT TREE IS STILL CUT

# TODO: This is a problem
# ensure that once rendered elements are in proper Z-INDEX
# and that they dont need to be rerendered in order
# to be seen at all

# think of better system to work with this


# IMPLEMENT WRAPPER OVER RENDERING WITH Z-INDEX FEATURE
# THAN SUGGEST IT TO THE GUY


# INTRODUCE SET OF UNIFIED SCENARIOS FOR PERFORMANCE BENCHMARKING
# INTRODUCE SOME TESTS?

# Introduce Game class, to be able to run tests without visual parts, and faster

# Write Autoplayer class to play the game for mey 9xx3


# MAke tree cutting more complex
# Let it return from 3 to 6 pieces at random 
# let it return also some firewood
# maybe have it be scattered on map instead on single piece 
# have it last for 4 hours


# TT.......SS
# TT.......SS
# TT....C..SS
# TT.......SS
# TT.......SS
# UNIFIED BENCHMARK!
# HAVE A MAP LIKE THIS
# AND BENCHMARK TO CUT AND MOVE ALL THE TREES TO STORAGES

# TODO: DOING HARD WORK USES MORE ENERGY
# TODO: FOR EXAMPLE, PUTS YOU TO SLEEP FASTER

# TODO: Build a system of passing informations around 
# Instead of having all the informations in the system 
# People will use the informations they have themselves
# For example if there is food in the storage 
# or basically anything
# People go look for informations themselves
# Or can ask questions and get informations 
# Or people can exchange informations while just randomly talking

# TODO: 
# Implement a system of growing crops in a garden
# like tomatos, cucumbers and others
# Make it realistic
# Check how fast tomatos grow, how often do you need to water and so on 

# TODO: MIGRATE EVERYTHING FROM THE GAME V1
# TODO: Then replace the game v1 with current implementation 
# TODO: And have the new version accessible in github.io as web version

# TODO: HAVE GARDEN AND GROW BASIC GARDEN CROPS, 
#       FIGURE OUT WATERING DOWN AND HOW LONG DOES IT GROW

# TODO: HAVE CHICKENS, FIGURE OUT FEEDING THEM AND GETTING EGGS

# TODO: Have people have a base of knowledge
#       about their own belongings
#       for example: I have this-and-that in my own drawer


# TODO: CREATE CLI TO ADD THINGS LIKE 
#       - the_game create_action
#       - the_hame create_job
#       - etc


# TODO: INSPECTION MENU
# TODO: ALLOW SEEING HOW MANY THINGS ARE IN STORES


# TODO: ADD GATHERER 
# TODO: ADD FISHERMAN
# TODO: ADD FARMER AND HIS CHICKENS

# TODO: Create map generator
# allow choosing of map before game


# TODO: MAKE THE MAP BIGGER
# TODO: ADD RIVER

# http://www.newhealthguide.org/How-Many-Calories-In-Salmon.html
# ŁOSOŚ: (atlantic salmon)
#   - 100g raw: 183 calories 
#   - 100g cooked: 206 calories

# TODO: Bushed gathering!


# TODO: JOB PRIORITISING
# TODO: Add progress bar as progressing circle when cutting trees and gathering bushes




# http://sosweetcreative.com/2613/font-face-and-base64-data-uri



# TODO: Bigger map 
# TODO: Buildable fireplace


# Create structures, assign people to them, and setup expectancies
#   - for example woodcutter workshop, assign woodcutter and set up to ensure n logs in storages 
#   - for example gatherer workshop, assign gatherer and assign n kilograms of berries in storages

# fuck gathering berries, create shop for autogatherying and 

# create autoplayer!

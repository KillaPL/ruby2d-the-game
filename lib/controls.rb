on(mouse: 'any') do |x, y|
  # puts "#{x} #{y} #{thing}"
  # Only take consider user action if it clicks on map
  # not if it clicks on menu
  if $menu.contains?(x, y)
    $menu.click(x, y)
  elsif $inspection_menu.contains?(x, y)
    $inspection_menu.click(x, y)
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

on key_down: "z" do
  $flood_map && $flood_map.toggle
end

# on key_down: ""

# on key_down: "x" do
#   $start_flood_map_progressing = true
#   $flood_map && $flood_map.progress
# end


on key_down: "escape" do
  close
end

# TODO: Figure out proper user interface for this!!
on key_down: "m" do
  kitchen = $structures.find{|s| s.is_a? Kitchen }

  if kitchen
    kitchen.ensure_more_berries
    $inspection_menu.rerender_content
  end
end

on key_down: "n" do
  kitchen = $structures.find{|s| s.is_a? Kitchen }
  if kitchen
    kitchen.ensure_less_berries
    $inspection_menu.rerender_content
  end
end

on key_down: "1" do
  $game_speed.set(1)
end

on key_down: "2" do
  $game_speed.set(5)
end

on key_down: "3" do
  $game_speed.set(100)
end

on key_down: "4" do
  $game_speed.set(250)
end

on key_down: "5" do
  $game_speed.set(1000)
end

on key_down: "p" do
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

on key_down: "f5" do
  get(:window).clear
  start_game!
end

# on_key do |key|
#   if key == "o"
#     if @profiling
#       result = RubyProf.stop
#       printer = RubyProf::GraphHtmlPrinter.new(result)

#       Pathname.new(FileUtils.pwd).join("./profiles/in-game-allocations.html").open("w+") do |file|
#         printer.print(file, {})
#       end
#       close
#     else
#       Text.new(200, 15, "PROFILING MEMORY", 40, "fonts/arial.ttf")
#       require "ruby-prof"
#       require "pathname"

#       RubyProf.measure_mode = RubyProf::ALLOCATIONS
#       RubyProf.start
#       @profiling = true
#     end
#   end
# end

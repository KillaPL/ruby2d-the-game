# TODO: Introduce some sort of tools to help gather
# TODO: Gather based not on time, but on how much a character can carry
class GatherAction < Action::Base
  def initialize(character, target)
    @character = character
    @target    = target
    if @target.respond_to? :gathering_time
      @time_left = @target.gathering_time
    else
      abandon_action
    end
  end

  def update(seconds)
    @time_left -= seconds

    if @time_left <= 0
      @target.gather_all.each do |item|
        spot = $map.free_spots_near(@target).first
        $map[spot.x, spot.y].content =  item
      end

      @target.was_picked!
      end_action
    end
  end
end

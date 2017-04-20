class FishAction < Action::Base
  def initialize(character)
    @character = character
    @time_left = 2.hour
  end

  def update(seconds)
    @time_left -= seconds

    if @time_left <= 0
      empty_spot = $map.find_empty_spot_near(@character)
      fish = RawFish.new(empty_spot.x, empty_spot.y)
      $map.put_item(empty_spot.x, empty_spot.y, fish)

      end_action
    end
  end
end
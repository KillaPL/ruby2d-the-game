class Fishery < Structure::Base
  class Inspection
    def initialize(kitchen, opts = {})
      x = opts[:x]
      y = opts[:y]
      @texts = []
      @texts << Text.new(x: x, y: y,      text: "Fishery",                               size: 16, font: "fonts/arial.ttf")
      @texts << Text.new(x: x, y: y + 20, text: "Continuous fishing:  on",               size: 16, font: "fonts/arial.ttf")
      @texts << Text.new(x: x, y: y + 40, text: "Continuous cleaning: on",               size: 16, font: "fonts/arial.ttf")
      @texts << Text.new(x: x, y: y + 60, text: "Raw fishes: #{kitchen.supplies.count}", size: 16, font: "fonts/arial.ttf")
    end

    def remove
      @texts.each(&:remove)
    end
  end

  attr_reader :x, :y, :supplies, :jobs

  def self.structure_requirements
    [Table]
  end

  def self.building_time
    20.minutes
  end

  def self.size
    3
  end

  def self.buildable_items
    []
  end

  def initialize(x, y)
    @x, @y = x, y
    @size  = self.class.size

    @mask = MapRenderer.square(x, y, @size, "purple", ZIndex::STRUCTURE)
    @mask.color.opacity = 0.6

    @supplies = []
    @jobs     = []
  end

  def get_job(type)
    if type == :fish_cleaning
      if supplies.any?
        ProduceJob.new(CleanedFish, at: self, type: :fish_cleaning)
      end
    elsif type == :fishing
      FishingJob.new
    elsif type == :haul
      unless supplies.count >= 10
        supply_job = SupplyJob.new(RawFish, to: self)
        supply_job if supply_job.available?
      end
    end
  end

  def has_stuff_required_for(item_class)
    item_class.required_supplies.each do |requirement|
      @supplies.any?{|s| s.is_a? requirement }
    end
  end

  # TODO: Always use classes like Table, Barrel to pass around instead of hashes.
  def produce(item_class)
    item_class.required_supplies.each do |requirement|
      supply = @supplies.find{|el| el.is_a? requirement}
      @supplies.delete(supply)
    end
    spot = $map.free_spots_near(self).first
    $map[spot.x, spot.y].content = item_class.new(spot.x, spot.y)
    nil
  end

  def supply(item)
    @supplies << item
  end
end

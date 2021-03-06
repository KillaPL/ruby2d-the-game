require_relative "./base"

class PastureZone < Zone::Base
  class Inspection
    def initialize(kitchen, opts = {})
      x = opts[:x]
      y = opts[:y]
      @texts = []
      @texts << Text.new(x: x, y: y,      text: "Pasture",                size: 16, font: "fonts/arial.ttf")
      @texts << Text.new(x: x, y: y + 20, text: "Continuous milking: on", size: 16, font: "fonts/arial.ttf")
    end

    def remove
      @texts.each(&:remove)
    end
  end

  attr_reader :x, :y, :image

  def initialize(x_range, y_range)
    @x_range = x_range
    @y_range = y_range
    @x = x_range.to_a.first
    @y = y_range.to_a.first
    @width  = x_range.last - x_range.first + 1
    @height = y_range.last - y_range.first + 1

    @image = MapRenderer.rectangle(@x, @y, @width, @height, "yellow", ZIndex::ZONE)
    @image.color.opacity = 0.07

    # TODO: There should be a menu for assigning animals
    # TODO: To pastures

    @pastured_animals = $creatures_list

    $creatures_list.each do |creature|
      creature.pasture = self
    end
  end

  def get_job(job_type)
    if job_type == :milking
      milkable_animal = @pastured_animals.find(&:milkable?)
      MilkAnimalJob.new(milkable_animal) if milkable_animal
    end
  end
end

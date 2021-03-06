class CutBerryBushJob
  def initialize(berry_bush)
    @berry_bush = berry_bush
    @mask = MapRenderer.square(
      berry_bush.x,
      berry_bush.y,
      1,
      [1, 0, 0, 0.2],
      ZIndex::MAP_ELEMENT_OVERLAY
    )
  end

  def type
    :woodcutting
  end

  def available?
    $map[@berry_bush.x, @berry_bush.y].available
  end

  def target
    @berry_bush
  end

  def action_for(character)
    MoveAction.new(character: character, near: @berry_bush).then do
      CutBerryBushAction.new(@berry_bush, character)
    end
  end

  def remove
    @mask.remove
  end
end

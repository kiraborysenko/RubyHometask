class Ship
  attr_reader :size, :coordinates, :hits

  def initialize(size)
    @size = size
    @coordinates = []
    @hits = 0
  end

  def place(coords)
    @coordinates = coords
  end

  def hit!
    @hits += 1
  end

  def sunk?
    @hits >= @size
  end
end
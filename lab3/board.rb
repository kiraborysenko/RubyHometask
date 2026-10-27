require_relative 'ship'
require_relative 'custom_errors'

class Board
  SIZE = 10
  FLEET_CONFIG = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1].freeze

  attr_reader :grid, :ships, :shots

  def initialize
    @grid = Array.new(SIZE) { Array.new(SIZE, :empty) }
    @ships = []
    @shots = {}
    auto_place_ships
  end

  def auto_place_ships
    FLEET_CONFIG.each do |ship_size|
      placed = false
      until placed
        row = rand(SIZE)
        col = rand(SIZE)
        orientation = rand(2).zero? ? :horizontal : :vertical

        if can_place_ship?(row, col, ship_size, orientation)
          coords = place_ship(row, col, ship_size, orientation)
          ship = Ship.new(ship_size)
          ship.place(coords)
          @ships << ship
          placed = true
        end
      end
    end
  end

  def receive_shot(row, col)
    if @shots.key?([row, col])
      raise AlreadyTargetedError, "У клітинку #{format_coord(row, col)} вже стріляли!"
    end

    if @grid[row][col] == :ship
      @grid[row][col] = :hit
      @shots[[row, col]] = :hit
      ship = @ships.find { |s| s.coordinates.include?([row, col]) }
      ship&.hit!

      if ship&.sunk?
        auto_mark_surrounding_misses(ship)
        :sunk
      else
        :hit
      end
    else
      @grid[row][col] = :miss
      @shots[[row, col]] = :miss
      :miss
    end
  end

  def all_ships_sunk?
    @ships.all?(&:sunk?)
  end

  def render(hide_ships: false)
    header = "   " + ("A".."J").to_a.join(" ")
    lines = [header]

    SIZE.times do |r|
      row_str = sprintf("%2d ", r + 1)
      SIZE.times do |c|
        cell = @grid[r][c]
        symbol = case cell
                 when :empty then "~"
                 when :ship  then hide_ships ? "~" : "S"
                 when :hit   then "X"
                 when :miss  then "•"
                 end
        row_str << "#{symbol} "
      end
      lines << row_str
    end

    lines.join("\n")
  end

  def format_coord(r, c)
    "#{('A'.ord + c).chr}#{r + 1}"
  end

  private

  def can_place_ship?(row, col, size, orientation)
    size.times do |i|
      r = orientation == :vertical ? row + i : row
      c = orientation == :horizontal ? col + i : col

      return false if r >= SIZE || c >= SIZE

      (-1..1).each do |dr|
        (-1..1).each do |dc|
          nr = r + dr
          nc = c + dc
          if nr.between?(0, SIZE - 1) && nc.between?(0, SIZE - 1)
            return false if @grid[nr][nc] == :ship
          end
        end
      end
    end
    true
  end

  def place_ship(row, col, size, orientation)
    coords = []
    size.times do |i|
      r = orientation == :vertical ? row + i : row
      c = orientation == :horizontal ? col + i : col
      @grid[r][c] = :ship
      coords << [r, c]
    end
    coords
  end

  def auto_mark_surrounding_misses(ship)
    ship.coordinates.each do |r, c|
      (-1..1).each do |dr|
        (-1..1).each do |dc|
          nr = r + dr
          nc = c + dc
          if nr.between?(0, SIZE - 1) && nc.between?(0, SIZE - 1)
            if @grid[nr][nc] == :empty
              @grid[nr][nc] = :miss
              @shots[[nr, nc]] = :miss
            end
          end
        end
      end
    end
  end
end
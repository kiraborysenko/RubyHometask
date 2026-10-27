require_relative 'board'
require_relative 'custom_errors'

class Player
  attr_reader :name, :board

  def initialize(name)
    @name = name
    @board = Board.new
  end
end

class HumanPlayer < Player
  def parse_coordinate(input)
    cleaned = input.to_s.strip.upcase
    match = cleaned.match(/\A([A-J])\s*([1-9]|10)\z/)

    unless match
      raise InvalidCoordinateError, "Некоректні координати! Введіть літеру (A-J) та номер (1-10), наприклад: A5 або J10."
    end

    col = match[1].ord - 'A'.ord
    row = match[2].to_i - 1

    [row, col]
  end
end

class ComputerPlayer < Player
  def initialize(name = "Комп'ютер")
    super(name)
    @available_shots = []
    Board::SIZE.times do |r|
      Board::SIZE.times do |c|
        @available_shots << [r, c]
      end
    end
    @available_shots.shuffle!
    @hits_to_finish = []
  end

  def choose_target(opponent_board)
    loop do
      target = select_target(opponent_board)
      return nil unless target

      unless opponent_board.shots.key?(target)
        @available_shots.delete(target)
        return target
      end
    end
  end

  def register_result(coord, result)
    if result == :hit
      @hits_to_finish << coord
    elsif result == :sunk
      @hits_to_finish.clear
    end
  end

  private

  def select_target(opponent_board)
    if @hits_to_finish.any?
      last_r, last_c = @hits_to_finish.last
      neighbors = [[last_r - 1, last_c], [last_r + 1, last_c], [last_r, last_c - 1], [last_r, last_c + 1]]
      valid_neighbors = neighbors.select do |r, c|
        r.between?(0, Board::SIZE - 1) && c.between?(0, Board::SIZE - 1) && !opponent_board.shots.key?([r, c])
      end
      return valid_neighbors.sample unless valid_neighbors.empty?
    end

    @available_shots.pop
  end
end
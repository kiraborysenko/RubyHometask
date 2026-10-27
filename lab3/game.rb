require_relative 'player'
require_relative 'custom_errors'

class Game
  def initialize(stats)
    @stats = stats
    @human = HumanPlayer.new("Гравець")
    @computer = ComputerPlayer.new
  end

  def start
    puts "\n=========================================="
    puts "        НОВА ГРА: МОРСЬКИЙ БІЙ           "
    puts "=========================================="
    puts "Кораблі обох учасників розміщено автоматично!"

    loop do
      display_boards

      break if human_turn

      break if computer_turn
    end
  end

  private

  def display_boards
    puts "\n--- ПОЛЕ СУПРОТИВНИКА (ТУМАН ВІЙНИ) ---"
    puts @computer.board.render(hide_ships: true)
    puts "\n--- ВАШЕ ПОЛЕ ---"
    puts @human.board.render(hide_ships: false)
    puts "------------------------------------------"
  end

  def human_turn
    loop do
      print "\nВведіть координати для пострілу (наприклад, A5): "
      input = gets.chomp

      begin
        row, col = @human.parse_coordinate(input)
        result = @computer.board.receive_shot(row, col)
        coord_str = @human.board.format_coord(row, col)

        case result
        when :hit
          puts "🔥 ВЛУЧАННЯ по клітинці #{coord_str}! Ви робите ще один хід."
          display_boards
          return true if check_game_over
        when :sunk
          puts "💥 ЗНИЩЕНО корабель супротивника на #{coord_str}! Ви робите ще один хід."
          display_boards
          return true if check_game_over
        when :miss
          puts "🌊 ПРОМАХ по клітинці #{coord_str}."
          return false
        end

      rescue InvalidCoordinateError, AlreadyTargetedError => e
        puts "⚠️ Помилка: #{e.message}"
        puts "Спробуйте ще раз."
      end
    end
  end

  def computer_turn
    puts "\n🤖 Хід комп'ютера..."
    sleep(0.6)

    loop do
      coord = @computer.choose_target(@human.board)
      return false unless coord

      row, col = coord
      result = @human.board.receive_shot(row, col)
      @computer.register_result(coord, result)
      coord_str = @human.board.format_coord(row, col)

      case result
      when :hit
        puts "⚠️ Комп'ютер ВЛУЧИВ у ваш корабель на #{coord_str} і ходить знову!"
        display_boards
        return true if check_game_over
      when :sunk
        puts "💀 Комп'ютер ЗНИЩИВ ваш корабель на #{coord_str} і ходить знову!"
        display_boards
        return true if check_game_over
      when :miss
        puts "🛡️ Комп'ютер ПРОМАХНУВСЯ на #{coord_str}."
        return false
      end
    end
  end

  def check_game_over
    if @computer.board.all_ships_sunk?
      puts "\n🎉 ПЕРЕМОГА! Ви знищили всі кораблі комп'ютера!"
      @stats[:wins] += 1
      true
    elsif @human.board.all_ships_sunk?
      puts "\n☠️ ПОРАЗКА! Комп'ютер знищив усі ваші кораблі."
      @stats[:losses] += 1
      true
    else
      false
    end
  end
end
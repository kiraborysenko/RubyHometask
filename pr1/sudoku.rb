class Sudoku4x4
  def initialize
    @board = [
      [1, 0, 3, 0],
      [0, 0, 1, 2],
      [2, 1, 0, 0],
      [0, 3, 0, 1]
    ]
    @initial_board = @board.map(&:dup)
  end

  def play
    puts "=== Вітаємо у грі Судоку 4x4! ==="
    puts "Правила: числа від 1 до 4 не повинні повторюватись у рядках, стовпцях та блоках 2x2."
    puts "Введіть 'q', щоб вийти з гри.\n\n"

    loop do
      print_board

      if win?
        puts "🎉 Вітаємо! Ви успішно розв'язали Судоку!"
        break
      end

      puts "Введіть рядок (1-4), стовпець (1-4) та число (1-4) через пробіл."
      puts "Щоб очистити клітинку, введіть число 0 (наприклад: '1 2 0'):"
      print "> "

      input = gets.chomp.downcase

      if input == 'q' || input == 'quit'
        puts "Гру завершено. Дякуємо за гру!"
        break
      end

      row, col, num = parse_input(input)
      next unless row && col && num

      if @initial_board[row][col] != 0
        puts "\n❌ Помилка: Початкові числа змінювати заборонено!"
        next
      end

      if valid_move?(row, col, num)
        @board[row][col] = num
        if num == 0
          puts "\nКлітинку (#{row + 1}, #{col + 1}) очищено."
        else
          puts "\n✅ Число #{num} успішно додано у (#{row + 1}, #{col + 1})."
        end
      else
        puts "\n❌ Неприпустимий хід! Число #{num} вже є у цьому рядку, стовпці або блоці 2x2."
      end
    end
  end

  private

  def print_board
    puts "    1 2   3 4"
    puts "  +-----+-----+"

    @board.each_with_index do |row, r|
      print "#{r + 1} | "
      row.each_with_index do |cell, c|
        print cell == 0 ? "." : cell
        print c == 1 ? " | " : " "
      end
      puts "|"
      puts "  +-----+-----+" if r == 1 || r == 3
    end
    puts
  end

  def parse_input(input)
    parts = input.split

    unless parts.size == 3
      puts "\n❌ Некоректний формат. Введіть 3 числа через пробіл (наприклад: '2 3 4')."
      return nil
    end

    r = parts[0].to_i - 1
    c = parts[1].to_i - 1
    num = parts[2].to_i

    unless (0..3).include?(r) && (0..3).include?(c) && (0..4).include?(num)
      puts "\n❌ Помилка: Рядок і стовпець мають бути від 1 до 4. Число має бути від 1 до 4 (або 0 для очищення)."
      return nil
    end

    [r, c, num]
  end

  def valid_move?(row, col, num)
    return true if num == 0

    @board[row].each_with_index do |cell, c|
      return false if cell == num && c != col
    end

    @board.each_with_index do |r_array, r|
      return false if r_array[col] == num && r != row
    end

    start_row = (row / 2) * 2
    start_col = (col / 2) * 2

    (start_row...start_row + 2).each do |r|
      (start_col...start_col + 2).each do |c|
        return false if @board[r][c] == num && (r != row || c != col)
      end
    end

    true
  end

  def win?
    @board.flatten.none?(0)
  end
end

Sudoku4x4.new.play
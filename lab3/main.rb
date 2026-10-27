require_relative 'game'

class Application
  def initialize
    @stats = { wins: 0, losses: 0 }
  end

  def run
    loop do
      show_main_menu
      print "Оберіть пункт меню (1-4): "
      choice = gets.to_s.strip

      case choice
      when "1"
        game = Game.new(@stats)
        game.start
      when "2"
        show_rules
      when "3"
        show_stats
      when "4"
        puts "\nДякуємо за гру! До зустрічі!"
        break
      else
        puts "⚠️ Некоректний вибір. Будь ласка, введіть число від 1 до 4."
      end
    end
  end

  private

  def show_main_menu
    puts "\n=========================================="
    puts "        МОРСЬКИЙ БІЙ — ГОЛОВНЕ МЕНЮ      "
    puts "=========================================="
    puts "1. Почати нову гру"
    puts "2. Переглянути правила"
    puts "3. Статистика ігор"
    puts "4. Вихід"
    puts "=========================================="
  end

  def show_rules
    puts "\n================ ПРАВИЛА ГРИ ================"
    puts "1. Поле розміром 10x10. Координати: буква (A-J) та номер (1-10)."
    puts "2. Склад флоту (автоматична розстановка):"
    puts "   - 1 линкор (4 клітинки)"
    puts "   - 2 крейсери (3 клітинки)"
    puts "   - 3 есмінці (2 клітинки)"
    puts "   - 4 катери (1 клітинка)"
    puts "3. Кораблі не можуть доторкатися один до одного (зокрема по діагоналі)."
    puts "4. У разі влучання гравець/комп'ютер робить додатковий хід."
    puts "5. Позначення:"
    puts "   ~  — Невідома клітинка / вода"
    puts "   S  — Ваш корабель"
    puts "   •  — Промах"
    puts "   X  — Влучання / Знищено"
    puts "============================================="
  end

  def show_stats
    puts "\n================ СТАТИСТИКА ================"
    puts "Перемог:  #{@stats[:wins]}"
    puts "Поразок:  #{@stats[:losses]}"
    total = @stats[:wins] + @stats[:losses]
    win_rate = total.zero? ? 0 : (@stats[:wins].to_f / total * 100).round(1)
    puts "Всього ігор: #{total}"
    puts "Відсоток перемог: #{win_rate}%"
    puts "============================================"
  end
end

Application.new.run
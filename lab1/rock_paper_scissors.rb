def rock_paper_scissors
  choices = ["Камінь", "Ножиці", "Папір"]

  user_wins = 0
  comp_wins = 0
  draws = 0
  total_rounds = 0

  puts "Гра 'Камінь, ножиці, папір'. Введіть '0' для виходу."

  loop do
    print "\nВаш вибір (1 - Камінь, 2 - Ножиці, 3 - Папір, 0 - Вихід): "
    input = gets.strip

    break if input == "0"

    user_choice = case input
                  when "1" then "Камінь"
                  when "2" then "Ножиці"
                  when "3" then "Папір"
                  else nil
                  end

    unless user_choice
      puts "Неправильний ввід. Будь ласка, введіть цифру 1, 2, 3 або 0."
      next
    end

    comp_choice = choices.sample
    puts "Ви обрали: #{user_choice}"
    puts "Вибір комп'ютера: #{comp_choice}"
    total_rounds += 1

    if user_choice == comp_choice
      puts "Нічия!"
      draws += 1
    elsif (user_choice == "Камінь" && comp_choice == "Ножиці") ||
          (user_choice == "Ножиці" && comp_choice == "Папір") ||
          (user_choice == "Папір" && comp_choice == "Камінь")
      puts "Ви перемогли!"
      user_wins += 1
    else
      puts "Комп'ютер переміг!"
      comp_wins += 1
    end

    puts "--- Статистика ---"
    puts "Зіграно раундів: #{total_rounds}"
    puts "Ваші перемоги: #{user_wins}"
    puts "Перемоги комп'ютера: #{comp_wins}"
    puts "Нічиї: #{draws}"
    puts "------------------"
  end
end

rock_paper_scissors
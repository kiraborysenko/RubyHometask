def play_game
  secret_number = rand(1..100)
  attempts = 0

  puts "Комп'ютер загадав число від 1 до 100. Спробуйте вгадати!"

  loop do
    print "Ваш варіант: "
    guess = gets.chomp.to_i
    attempts += 1

    if guess == secret_number
      puts "Вгадано! Кількість спроб: #{attempts}"
      break
    elsif guess < secret_number
      puts "більше"
    else
      puts "менше"
    end
  end
end

play_game
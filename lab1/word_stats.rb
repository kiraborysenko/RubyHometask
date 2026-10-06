def word_stats(text)
  words = text.gsub(/[[:punct:]]/, '').split

  return puts "Текст порожній" if words.empty?

  total_words = words.length
  longest_word = words.max_by(&:length)
  unique_words = words.map(&:downcase).uniq.length

  puts "Всього слів: #{total_words}"
  puts "Найдовше слово: #{longest_word}"
  puts "Унікальних слів: #{unique_words}"
end

text = "Kharkiv is the best city on planet Earth."
word_stats(text)
require 'csv'

LOG_PATH = File.join(__dir__, 'data', 'app.log')
OUTPUT_DIR = File.join(__dir__, 'output')
OUTPUT_PATH = File.join(OUTPUT_DIR, 'stats.csv')

counts = {
  'INFO' => 0,
  'WARN' => 0,
  'ERROR' => 0
}

invalid_count = 0
total_count = 0
error_messages = Hash.new(0)

LOG_REGEX = /\A(?<date>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(?<level>INFO|WARN|ERROR)\s+(?<message>.+?)\s*\z/

begin
  File.foreach(LOG_PATH) do |line|
    total_count += 1

    match = LOG_REGEX.match(line)
    if match
      level = match[:level]
      counts[level] += 1

      if level == 'ERROR'
        error_messages[match[:message]] += 1
      end
    else
      invalid_count += 1
    end
  end

  calculated_total = counts['INFO'] + counts['WARN'] + counts['ERROR'] + invalid_count
  unless calculated_total == total_count
    raise "Помилка інваріанту: сума рівнів та невалідних рядків (#{calculated_total}) не дорівнює загальній кількості (#{total_count})!"
  end

  top_errors = error_messages.sort_by { |_msg, count| -count }.first(3)

  Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

  CSV.open(OUTPUT_PATH, 'w') do |csv|
    csv << ['metric', 'count']
    csv << ['INFO', counts['INFO']]
    csv << ['WARN', counts['WARN']]
    csv << ['ERROR', counts['ERROR']]
    csv << ['INVALID', invalid_count]
    csv << ['TOTAL', total_count]

    top_errors.each do |message, freq|
      csv << ["top_error: #{message}", freq]
    end
  end

  puts "Аналіз успішно завершено! Результати збережено у файл '#{OUTPUT_PATH}'."

rescue Errno::ENOENT
  abort("Помилка: Файл журналу не знайдено за шляхом '#{LOG_PATH}'.")
rescue StandardError => e
  abort("Сталася помилка під час виконання програми: #{e.message}")
end
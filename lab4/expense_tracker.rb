require 'json'
require 'date'

FILENAME = 'expenses.json'.freeze
CATEGORIES = %w[food transport study entertainment other].freeze

class ExpenseTracker
  def initialize(filename = FILENAME)
    @filename = filename
    @expenses = []
    load_data
  end

  def load_data
    unless File.exist?(@filename)
      @expenses = []
      return
    end

    begin
      content = File.read(@filename, encoding: 'utf-8').strip
      if content.empty?
        warn "Помилка: файл '#{@filename}' порожній. Робота завершена без перезаписування файла."
        exit(1)
      end

      data = JSON.parse(content)
      unless data.is_a?(Array)
        warn "Помилка: некоректна структура у файлі '#{@filename}' (очікувався масив). Робота завершена без перезаписування файла."
        exit(1)
      end

      seen_ids = {}
      validated = []

      data.each_with_index do |item, idx|
        unless valid_expense_hash?(item)
          warn "Помилка: некоректний запис у файлі '#{@filename}' (позиція #{idx + 1}). Робота завершена без перезаписування файла."
          exit(1)
        end

        id_val = item['id']
        if seen_ids[id_val]
          warn "Помилка: дублікат ідентифікатора id=#{id_val} у файлі '#{@filename}'. Робота завершена без перезаписування файла."
          exit(1)
        end
        seen_ids[id_val] = true

        validated << normalize_expense(item)
      end

      @expenses = validated
    rescue JSON::ParserError => e
      warn "Помилка: файл '#{@filename}' пошкоджений або містить невалідний JSON (#{e.message}). Робота завершена без перезаписування файла."
      exit(1)
    rescue SystemCallError, IOError => e
      warn "Помилка читання файлу '#{@filename}': #{e.message}. Робота завершена без перезаписування файла."
      exit(1)
    end
  end

  def save_data
    temp_file = "#{@filename}.tmp"
    json_output = JSON.pretty_generate(@expenses)

    File.write(temp_file, json_output, encoding: 'utf-8')
    File.rename(temp_file, @filename)
    true
  rescue SystemCallError, IOError => e
    warn "Помилка збереження даних у '#{@filename}': #{e.message}"
    begin
      File.delete(temp_file) if File.exist?(temp_file)
    rescue StandardError
      # ігноруємо помилку видалення тимчасового файла
    end
    false
  end

  def add_expense_interactive
    puts "\n--- Додавання витрати ---"
    date_str = prompt_non_empty('Введіть дату (YYYY-MM-DD): ')
    parsed_date = parse_real_date(date_str)
    unless parsed_date
      puts 'Помилка: дата має бути реальною календарною датою у форматі YYYY-MM-DD.'
      return
    end

    amount_str = prompt_non_empty('Введіть суму в копійках (додатне ціле число, наприклад 12550): ')
    amount_kopecks = parse_positive_int(amount_str)
    unless amount_kopecks
      puts 'Помилка: сума має бути додатним цілим числом копійок.'
      return
    end

    puts "Доступні категорії: #{CATEGORIES.join(', ')}"
    category = prompt_non_empty('Введіть категорію: ').downcase
    unless CATEGORIES.include?(category)
      puts "Помилка: невідома категорія. Дозволені значення: #{CATEGORIES.join(', ')}."
      return
    end

    raw_desc = prompt('Введіть опис (до 200 символів): ')
    description = raw_desc.strip
    if description.empty? || description.length > 200
      puts 'Помилка: опис не може бути порожнім і має містити не більше 200 символів після видалення крайніх пробілів.'
      return
    end

    new_expense = {
      'id' => next_id,
      'date' => parsed_date.strftime('%Y-%m-%d'),
      'amount_in_kopecks' => amount_kopecks,
      'category' => category,
      'description' => description
    }

    previous_expenses = deep_copy_expenses(@expenses)
    @expenses << new_expense

    if save_data
      puts "Витрату успішно додано (ID: #{new_expense['id']}, #{format_uah(amount_kopecks)})."
    else
      @expenses = previous_expenses
      warn 'Зміни НЕ збережено у файл. Стан у пам’яті повернуто до попереднього.'
    end
  end

  def list_expenses(records = @expenses)
    if records.empty?
      puts "\nСписок витрат порожній."
      return
    end

    sorted = records.sort_by { |e| [e['date'], e['id']] }

    puts "\n" + '=' * 92
    printf "%-5s | %-10s | %-14s | %-13s | %s\n", 'ID', 'Дата', 'Сума (грн)', 'Категорія', 'Опис'
    puts '-' * 92
    sorted.each do |e|
      printf "%-5d | %-10s | %14s | %-13s | %s\n",
             e['id'],
             e['date'],
             format_uah(e['amount_in_kopecks']),
             e['category'],
             e['description']
    end
    puts '=' * 92
  end

  def filter_expenses_interactive
    puts "\n--- Фільтрація витрат ---"
    puts "Категорії: #{CATEGORIES.join(', ')} (або Enter — усі)"
    cat_input = prompt('Категорія: ').strip.downcase
    unless cat_input.empty? || CATEGORIES.include?(cat_input)
      puts "Помилка: невідома категорія. Дозволені: #{CATEGORIES.join(', ')}."
      return
    end

    start_input = prompt('Початкова дата (YYYY-MM-DD або Enter): ').strip
    end_input = prompt('Кінцева дата (YYYY-MM-DD або Enter): ').strip

    start_date = nil
    unless start_input.empty?
      start_date = parse_real_date(start_input)
      unless start_date
        puts 'Помилка: некоректна початкова дата (очікується YYYY-MM-DD).'
        return
      end
    end

    end_date = nil
    unless end_input.empty?
      end_date = parse_real_date(end_input)
      unless end_date
        puts 'Помилка: некоректна кінцева дата (очікується YYYY-MM-DD).'
        return
      end
    end

    if start_date && end_date && start_date > end_date
      puts 'Помилка: початкова дата не може бути пізнішою за кінцеву.'
      return
    end

    filtered = @expenses.select do |e|
      next false if !cat_input.empty? && e['category'] != cat_input

      d = Date.strptime(e['date'], '%Y-%m-%d')
      next false if start_date && d < start_date
      next false if end_date && d > end_date

      true
    end

    if filtered.empty?
      puts "\nЗа заданими критеріями витрат не знайдено."
    else
      puts "\nЗнайдено записів: #{filtered.size}"
      list_expenses(filtered)
    end
  end

  def delete_expense_interactive
    puts "\n--- Видалення витрати ---"
    id_str = prompt_non_empty('Введіть ID витрати для видалення: ')
    target_id = parse_positive_int(id_str)
    unless target_id
      puts 'Помилка: ID має бути додатним цілим числом.'
      return
    end

    target = @expenses.find { |e| e['id'] == target_id }
    unless target
      puts "Витрату з ID #{target_id} не знайдено."
      return
    end

    puts "\nЗнайдено запис:"
    puts "  ID:        #{target['id']}"
    puts "  Дата:      #{target['date']}"
    puts "  Сума:      #{format_uah(target['amount_in_kopecks'])}"
    puts "  Категорія: #{target['category']}"
    puts "  Опис:      #{target['description']}"

    confirm = prompt('Підтвердьте видалення (y/n): ').strip.downcase
    unless %w[y yes так т].include?(confirm)
      puts 'Видалення скасовано.'
      return
    end

    previous_expenses = deep_copy_expenses(@expenses)
    @expenses.reject! { |e| e['id'] == target_id }

    if save_data
      puts "Витрату з ID #{target_id} успішно видалено."
    else
      @expenses = previous_expenses
      warn 'Зміни НЕ збережено у файл. Стан у пам’яті повернуто до попереднього.'
    end
  end

  def show_statistics_interactive
    puts "\n--- Статистика витрат ---"
    if @expenses.empty?
      puts 'Записів немає. Загальна сума: 0.00 грн.'
      return
    end

    total_kopecks = @expenses.sum { |e| e['amount_in_kopecks'] }
    puts "Загальна сума витрат: #{format_uah(total_kopecks)}"

    puts "\nСума за категоріями:"
    CATEGORIES.each do |cat|
      cat_sum = @expenses.select { |e| e['category'] == cat }.sum { |e| e['amount_in_kopecks'] }
      puts "  - #{cat.ljust(15)}: #{format_uah(cat_sum)}"
    end

    max_kopecks = @expenses.map { |e| e['amount_in_kopecks'] }.max
    largest = @expenses.select { |e| e['amount_in_kopecks'] == max_kopecks }.sort_by { |e| [e['date'], e['id']] }
    puts "\nНайбільша витрата (#{format_uah(max_kopecks)}):"
    largest.each do |e|
      puts "  - [ID: #{e['id']}] #{e['date']} | #{e['category']} | #{e['description']}"
    end

    puts "\nСума за заданий період (включно з обома датами):"
    start_str = prompt_non_empty('Початкова дата (YYYY-MM-DD): ')
    end_str = prompt_non_empty('Кінцева дата (YYYY-MM-DD): ')

    start_date = parse_real_date(start_str)
    end_date = parse_real_date(end_str)

    unless start_date && end_date
      puts 'Помилка: обидві дати мають бути реальними календарними датами у форматі YYYY-MM-DD.'
      return
    end

    if start_date > end_date
      puts 'Помилка: початкова дата не може бути пізнішою за кінцеву.'
      return
    end

    period_records = @expenses.select do |e|
      d = Date.strptime(e['date'], '%Y-%m-%d')
      d >= start_date && d <= end_date
    end

    period_kopecks = period_records.sum { |e| e['amount_in_kopecks'] }
    if period_records.empty?
      puts "За період з #{start_str} по #{end_str} витрат не знайдено. Сума: 0.00 грн."
    else
      puts "Сума за період з #{start_str} по #{end_str} (записів: #{period_records.size}): #{format_uah(period_kopecks)}."
    end
  end

  def import_from_json_interactive
    puts "\n--- Імпорт витрат з JSON-файлу ---"
    path = prompt_non_empty('Введіть шлях до JSON-файлу: ')

    unless File.exist?(path)
      puts "Помилка: файл '#{path}' не знайдено."
      return
    end

    begin
      raw = File.read(path, encoding: 'utf-8')
      data = JSON.parse(raw)

      unless data.is_a?(Array)
        puts 'Помилка: JSON-файл для імпорту має містити масив записів.'
        return
      end

      prepared = []
      current_max_id = @expenses.map { |e| e['id'] }.max || 0
      used_ids = @expenses.each_with_object({}) { |e, acc| acc[e['id']] = true }

      data.each_with_index do |item, idx|
        unless valid_expense_hash?(item)
          puts "Помилка: некоректний запис у файлі імпорту (позиція #{idx + 1}). Імпорт скасовано, наявні дані не змінено."
          return
        end

        normalized = normalize_expense(item)
        if used_ids[normalized['id']]
          current_max_id += 1
          normalized['id'] = current_max_id
        elsif normalized['id'] > current_max_id
          current_max_id = normalized['id']
        end

        used_ids[normalized['id']] = true
        prepared << normalized
      end

      if prepared.empty?
        puts 'Файл імпорту містить порожній масив []. Нових записів не додано.'
        return
      end

      previous_expenses = deep_copy_expenses(@expenses)
      @expenses.concat(prepared)

      if save_data
        puts "Успішно імпортовано записів: #{prepared.size}."
      else
        @expenses = previous_expenses
        warn 'Зміни НЕ збережено у файл. Стан у пам’яті повернуто до попереднього.'
      end
    rescue JSON::ParserError => e
      puts "Помилка: не вдалося розпарсити JSON у файлі '#{path}' (#{e.message})."
    rescue SystemCallError, IOError => e
      puts "Помилка читання файлу '#{path}': #{e.message}."
    end
  end

  def run
    loop do
      print_menu
      choice = prompt('Оберіть дію (1-7): ').strip

      case choice
      when '1' then add_expense_interactive
      when '2' then list_expenses
      when '3' then filter_expenses_interactive
      when '4' then delete_expense_interactive
      when '5' then show_statistics_interactive
      when '6' then import_from_json_interactive
      when '7'
        puts 'Роботу завершено. До побачення!'
        break
      else
        puts 'Помилка: невідома команда. Введіть число від 1 до 7.'
      end
    end
  end

  private

  def print_menu
    puts "\n================ ExpenseTracker ================"
    puts '1. Додати витрату'
    puts '2. Переглянути всі витрати'
    puts '3. Фільтрувати витрати (за категорією та періодом)'
    puts '4. Видалити витрату за ідентифікатором'
    puts '5. Переглянути статистику'
    puts '6. Імпортувати витрати з JSON-файла'
    puts '7. Завершити роботу'
    puts '================================================'
  end

  def prompt(message)
    print message
    line = gets
    return '' if line.nil?

    line.chomp
  end

  def prompt_non_empty(message)
    prompt(message).strip
  end

  def next_id
    (@expenses.map { |e| e['id'] }.max || 0) + 1
  end

  def parse_positive_int(str)
    return nil unless str.is_a?(String)
    return nil unless /\A\d+\z/.match?(str.strip)

    val = str.strip.to_i
    val.positive? ? val : nil
  end

  def parse_real_date(str)
    return nil unless str.is_a?(String)

    trimmed = str.strip
    return nil unless /\A\d{4}-\d{2}-\d{2}\z/.match?(trimmed)

    year, month, day = trimmed.split('-').map(&:to_i)
    Date.valid_date?(year, month, day) ? Date.new(year, month, day) : nil
  end

  def valid_expense_hash?(item)
    return false unless item.is_a?(Hash)

    required_keys = %w[id date amount_in_kopecks category description]
    return false unless (required_keys - item.keys).empty?

    id_val = item['id']
    return false unless id_val.is_a?(Integer) && id_val.positive?

    date_val = item['date']
    return false unless date_val.is_a?(String) && !parse_real_date(date_val).nil?

    amount_val = item['amount_in_kopecks']
    return false unless amount_val.is_a?(Integer) && amount_val.positive?

    category_val = item['category']
    return false unless category_val.is_a?(String) && CATEGORIES.include?(category_val)

    desc_val = item['description']
    return false unless desc_val.is_a?(String)

    stripped_desc = desc_val.strip
    return false if stripped_desc.empty? || stripped_desc.length > 200

    true
  end

  def normalize_expense(item)
    parsed = parse_real_date(item['date'])
    {
      'id' => item['id'],
      'date' => parsed.strftime('%Y-%m-%d'),
      'amount_in_kopecks' => item['amount_in_kopecks'],
      'category' => item['category'],
      'description' => item['description'].strip
    }
  end

  def format_uah(kopecks)
    format('%.2f грн', kopecks / 100.0)
  end

  def deep_copy_expenses(list)
    list.map(&:dup)
  end
end

ExpenseTracker.new.run if __FILE__ == $PROGRAM_NAME
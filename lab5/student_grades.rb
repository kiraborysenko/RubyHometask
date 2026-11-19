require 'csv'

DEFAULT_CSV_FILE = File.expand_path('students.csv', __dir__).freeze
DEFAULT_REPORT_FILE = File.expand_path('report.txt', __dir__).freeze
HEADERS = %w[name subject grade].freeze

class StudentGradeAnalyzer
  def initialize(csv_file = DEFAULT_CSV_FILE)
    @csv_file = csv_file
    @records = []
    load_records
  end

  def load_records
    unless File.exist?(@csv_file)
      warn "Увага: файл '#{@csv_file}' не знайдено. Створюємо новий порожній набір даних."
      @records = []
      save_records
      return
    end

    begin
      raw_content = File.read(@csv_file, encoding: 'utf-8')
      if raw_content.strip.empty?
        warn "Увага: файл '#{@csv_file}' порожній. Завантажено порожній список записів."
        @records = []
        return
      end

      table = CSV.parse(raw_content, headers: true)
      unless valid_headers?(table.headers)
        warn "Помилка: некоректні заголовки CSV у файлі '#{@csv_file}' (очікується: #{HEADERS.join(',')}). Дані не завантажено."
        @records = []
        return
      end

      loaded = []
      table.each_with_index do |row, idx|
        line_num = idx + 2
        parsed = parse_and_validate_row(row)
        if parsed
          loaded << parsed
        else
          warn "Попередження: рядок #{line_num} у '#{@csv_file}' містить некоректні дані та пропущений."
        end
      end

      @records = loaded
      puts "Завантажено валідних записів: #{@records.size} із '#{@csv_file}'."
    rescue CSV::MalformedCSVError => e
      warn "Помилка формату CSV у файлі '#{@csv_file}': #{e.message}. Дані не завантажено."
      @records = []
    rescue SystemCallError, IOError => e
      warn "Помилка читання файлу '#{@csv_file}': #{e.message}. Дані не завантажено."
      @records = []
    end
  end

  def save_records
    temp_file = "#{@csv_file}.tmp"
    begin
      csv_string = CSV.generate(headers: true) do |csv|
        csv << HEADERS
        @records.each do |rec|
          csv << [rec[:name], rec[:subject], rec[:grade]]
        end
      end

      File.write(temp_file, csv_string, encoding: 'utf-8')
      File.rename(temp_file, @csv_file)
      true
    rescue SystemCallError, IOError => e
      warn "Помилка збереження у файл '#{@csv_file}': #{e.message}"
      begin
        File.delete(temp_file) if File.exist?(temp_file)
      rescue StandardError
        # ігноруємо помилку очищення тимчасового файла
      end
      false
    end
  end

  def display_all_records
    puts "\n=== Список усіх записів про оцінки ==="
    if @records.empty?
      puts 'Записів немає.'
      return
    end

    printf "%-4s | %-18s | %-18s | %-6s\n", '№', 'Студент', 'Предмет', 'Оцінка'
    puts '-' * 55
    @records.each_with_index do |rec, index|
      printf "%-4d | %-18s | %-18s | %6d\n", index + 1, rec[:name], rec[:subject], rec[:grade]
    end
  end

  def student_averages
    grouped = @records.group_by { |r| r[:name] }
    averages = {}
    grouped.each do |name, items|
      avg = items.sum { |i| i[:grade] }.to_f / items.size
      averages[name] = avg.round(2)
    end
    averages
  end

  def display_student_averages
    puts "\n=== Середній бал кожного студента ==="
    avgs = student_averages
    if avgs.empty?
      puts 'Немає даних для розрахунку.'
      return
    end

    avgs.sort_by { |name, _| name.downcase }.each do |name, avg|
      count = @records.count { |r| r[:name] == name }
      printf "  %-20s : %6.2f (оцінок: %d)\n", name, avg, count
    end
  end

  def extreme_students
    avgs = student_averages
    return [[], nil, [], nil] if avgs.empty?

    max_avg = avgs.values.max
    min_avg = avgs.values.min

    top_students = avgs.select { |_, val| val == max_avg }.keys.sort
    low_students = avgs.select { |_, val| val == min_avg }.keys.sort

    [top_students, max_avg, low_students, min_avg]
  end

  def display_extreme_students
    puts "\n=== Студенти з найвищим та найнижчим середнім балом ==="
    top_students, max_avg, low_students, min_avg = extreme_students
    if top_students.empty?
      puts 'Немає даних для аналізу.'
      return
    end

    puts "Найвищий середній бал (#{format('%.2f', max_avg)}): #{top_students.join(', ')}"
    puts "Найнижчий середній бал (#{format('%.2f', min_avg)}): #{low_students.join(', ')}"
  end

  def subject_averages
    grouped = @records.group_by { |r| r[:subject] }
    averages = {}
    grouped.each do |subject, items|
      avg = items.sum { |i| i[:grade] }.to_f / items.size
      averages[subject] = avg.round(2)
    end
    averages
  end

  def display_subject_averages
    puts "\n=== Середній бал за предметами ==="
    avgs = subject_averages
    if avgs.empty?
      puts 'Немає даних для аналізу.'
      return
    end

    avgs.sort_by { |subj, _| subj.downcase }.each do |subject, avg|
      count = @records.count { |r| r[:subject] == subject }
      printf "  %-20s : %6.2f (оцінок: %d)\n", subject, avg, count
    end
  end

  def search_student_interactive
    puts "\n=== Пошук студента за іменем ==="
    query = prompt_non_empty("Введіть ім'я студента для пошуку: ")
    unless query
      puts "Помилка: ім'я не може бути порожнім."
      return
    end

    matches = @records.select { |r| r[:name].downcase == query.downcase }
    if matches.empty?
      puts "Студента з іменем '#{query}' не знайдено."
      return
    end

    student_name = matches.first[:name]
    avg = (matches.sum { |m| m[:grade] }.to_f / matches.size).round(2)
    puts "\nСтудент: #{student_name}"
    puts "Середній бал: #{format('%.2f', avg)}"
    puts 'Оцінки:'
    matches.each do |m|
      puts "  - #{m[:subject]}: #{m[:grade]}"
    end
  end

  def add_grade_interactive
    puts "\n=== Додавання оцінки ==="
    name = prompt_non_empty("Введіть ім'я студента: ")
    unless name
      puts "Помилка: ім'я студента не може бути порожнім."
      return
    end

    subject = prompt_non_empty('Введіть назву предмета: ')
    unless subject
      puts 'Помилка: назва предмета не може бути порожньою.'
      return
    end

    grade = prompt_grade('Введіть оцінку (0-100): ')
    return unless grade

    new_record = { name: name, subject: subject, grade: grade }
    previous = clone_records(@records)
    @records << new_record

    if save_records
      puts "Оцінку додано та збережено у '#{@csv_file}'."
    else
      @records = previous
      warn 'Зміни не збережено через помилку запису. Стан відновлено.'
    end
  end

  def edit_grade_interactive
    puts "\n=== Редагування оцінки ==="
    if @records.empty?
      puts 'Список записів порожній. Немає оцінок для редагування.'
      return
    end

    display_all_records
    index = prompt_record_index('Введіть номер запису для редагування: ')
    return unless index

    target = @records[index]
    puts "Обрано запис: #{target[:name]} | #{target[:subject]} | поточна оцінка: #{target[:grade]}"

    new_name = prompt("Нове ім'я студента (Enter — залишити '#{target[:name]}'): ").strip
    new_subject = prompt("Новий предмет (Enter — залишити '#{target[:subject]}'): ").strip
    new_grade_raw = prompt("Нова оцінка 0-100 (Enter — залишити '#{target[:grade]}'): ").strip

    updated_name = new_name.empty? ? target[:name] : new_name
    updated_subject = new_subject.empty? ? target[:subject] : new_subject

    updated_grade = if new_grade_raw.empty?
                      target[:grade]
                    else
                      parsed = parse_grade(new_grade_raw)
                      unless parsed
                        puts 'Помилка: оцінка має бути цілим числом від 0 до 100.'
                        return
                      end
                      parsed
                    end

    previous = clone_records(@records)
    @records[index] = {
      name: updated_name,
      subject: updated_subject,
      grade: updated_grade
    }

    if save_records
      puts "Запис №#{index + 1} оновлено та збережено у '#{@csv_file}'."
    else
      @records = previous
      warn 'Зміни не збережено через помилку запису. Стан відновлено.'
    end
  end

  def delete_grade_interactive
    puts "\n=== Видалення оцінки ==="
    if @records.empty?
      puts 'Список записів порожній. Немає оцінок для видалення.'
      return
    end

    display_all_records
    index = prompt_record_index('Введіть номер запису для видалення: ')
    return unless index

    target = @records[index]
    confirm = prompt("Видалити запис '#{target[:name]} - #{target[:subject]} (#{target[:grade]})'? (y/n): ").strip.downcase
    unless %w[y yes так т].include?(confirm)
      puts 'Видалення скасовано.'
      return
    end

    previous = clone_records(@records)
    @records.delete_at(index)

    if save_records
      puts "Запис видалено та зміни збережено у '#{@csv_file}'."
    else
      @records = previous
      warn 'Зміни не збережено через помилку запису. Стан відновлено.'
    end
  end

  def generate_report(report_file = DEFAULT_REPORT_FILE)
    puts "\n=== Формування статистичного звіту ==="
    lines = []
    lines << '===================================================='
    lines << '        СТАТИСТИЧНИЙ ЗВІТ ПРО УСПІШНІСТЬ СТУДЕНТІВ'
    lines << '===================================================='
    lines << "Дата формування: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    lines << "Джерело даних:  #{@csv_file}"
    lines << "Загальна кількість записів: #{@records.size}"
    lines << ''

    if @records.empty?
      lines << 'Дані про оцінки відсутні.'
    else
      lines << '--- Усі записи ---'
      @records.each_with_index do |r, idx|
        lines << format('%3d. %-18s | %-18s | %3d', idx + 1, r[:name], r[:subject], r[:grade])
      end
      lines << ''

      lines << '--- Середній бал за студентами ---'
      student_averages.sort_by { |name, _| name.downcase }.each do |name, avg|
        lines << format('  %-20s : %6.2f', name, avg)
      end
      lines << ''

      top_students, max_avg, low_students, min_avg = extreme_students
      lines << '--- Лідери та відстаючі за середнім балом ---'
      lines << format('  Найвищий середній бал (%.2f): %s', max_avg, top_students.join(', '))
      lines << format('  Найнижчий середній бал (%.2f): %s', min_avg, low_students.join(', '))
      lines << ''

      lines << '--- Середній бал за предметами ---'
      subject_averages.sort_by { |subj, _| subj.downcase }.each do |subject, avg|
        lines << format('  %-20s : %6.2f', subject, avg)
      end
    end
    lines << '===================================================='

    begin
      File.write(report_file, lines.join("\n") + "\n", encoding: 'utf-8')
      puts "Звіт успішно збережено у файл '#{report_file}'."
    rescue SystemCallError, IOError => e
      warn "Помилка запису звіту у файл '#{report_file}': #{e.message}"
    end
  end

  def run
    loop do
      print_menu
      choice = prompt('Оберіть пункт меню (1-10): ').strip

      case choice
      when '1' then display_all_records
      when '2' then display_student_averages
      when '3' then display_extreme_students
      when '4' then display_subject_averages
      when '5' then search_student_interactive
      when '6' then add_grade_interactive
      when '7' then edit_grade_interactive
      when '8' then delete_grade_interactive
      when '9' then generate_report
      when '10'
        puts 'Роботу завершено.'
        break
      else
        puts 'Помилка: невідомий пункт меню. Введіть число від 1 до 10.'
      end
    end
  end

  private

  def print_menu
    puts "\n==================== МЕНЮ АНАЛІЗУ УСПІШНОСТІ ===================="
    puts ' 1. Вивести список усіх студентів та їхніх оцінок'
    puts ' 2. Розрахувати середній бал кожного студента'
    puts ' 3. Визначити студентів з найвищим та найнижчим середнім балом'
    puts ' 4. Розрахувати середній бал за кожним предметом'
    puts ' 5. Пошук студента за іменем'
    puts ' 6. Додати оцінку'
    puts ' 7. Редагувати оцінку'
    puts ' 8. Видалити оцінку'
    puts ' 9. Сформувати та зберегти звіт у report.txt'
    puts '10. Вихід'
    puts '=================================================================='
  end

  def prompt(message)
    print message
    line = gets
    return '' if line.nil?

    line.chomp
  end

  def prompt_non_empty(message)
    val = prompt(message).strip
    val.empty? ? nil : val
  end

  def parse_grade(str)
    return nil unless str.is_a?(String)
    return nil unless /\A\d+\z/.match?(str.strip)

    val = str.strip.to_i
    (0..100).include?(val) ? val : nil
  end

  def prompt_grade(message)
    raw = prompt_non_empty(message)
    grade = parse_grade(raw)
    unless grade
      puts 'Помилка: оцінка має бути цілим числом у діапазоні від 0 до 100.'
      return nil
    end
    grade
  end

  def prompt_record_index(message)
    raw = prompt_non_empty(message)
    unless raw && /\A\d+\z/.match?(raw)
      puts 'Помилка: номер запису має бути додатним цілим числом.'
      return nil
    end

    num = raw.to_i
    if num < 1 || num > @records.size
      puts "Помилка: запису з номером #{num} не існує (доступно 1..#{@records.size})."
      return nil
    end
    num - 1
  end

  def valid_headers?(headers)
    return false unless headers.is_a?(Array)

    normalized = headers.compact.map { |h| h.strip.downcase }
    normalized == HEADERS
  end

  def parse_and_validate_row(row)
    return nil unless row

    name = row['name']&.strip
    subject = row['subject']&.strip
    grade_str = row['grade']&.strip

    return nil if name.nil? || name.empty?
    return nil if subject.nil? || subject.empty?

    grade = parse_grade(grade_str)
    return nil unless grade

    { name: name, subject: subject, grade: grade }
  end

  def clone_records(list)
    list.map(&:dup)
  end
end

if __FILE__ == $PROGRAM_NAME
  csv_path = ARGV.first || DEFAULT_CSV_FILE
  StudentGradeAnalyzer.new(csv_path).run
end
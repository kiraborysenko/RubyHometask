def cut_cake(cake_str)
  grid = cake_str.strip.split("\n").map(&:chars)
  return [] if grid.empty?

  h = grid.length
  w = grid[0].length

  raisins = 0
  (0...h).each do |r|
    (0...w).each do |c|
      if ['o', 'O', 'о', 'О'].include?(grid[r][c])
        grid[r][c] = 'o'
        raisins += 1
      end
    end
  end

  return [] if raisins == 0

  total_area = h * w
  return [] if total_area % raisins != 0

  area_per_piece = total_area / raisins
  used = Array.new(h) { Array.new(w, false) }

  valid_dims = []
  [w, area_per_piece].min.downto(1) do |width|
    if area_per_piece % width == 0
      height = area_per_piece / width
      valid_dims << [width, height] if height <= h
    end
  end

  dfs = lambda do
    start_r = nil
    start_c = nil

    (0...h).each do |r|
      (0...w).each do |c|
        unless used[r][c]
          start_r = r
          start_c = c
          break
        end
      end
      break if start_r
    end

    return [] unless start_r

    valid_dims.each do |width, height|
      next if start_r + height > h || start_c + width > w

      overlap = false
      raisin_count = 0

      (start_r...start_r + height).each do |i|
        (start_c...start_c + width).each do |j|
          if used[i][j]
            overlap = true
            break
          end
          raisin_count += 1 if grid[i][j] == 'o'
        end
        break if overlap || raisin_count > 1
      end

      if !overlap && raisin_count == 1

        (start_r...start_r + height).each do |i|
          (start_c...start_c + width).each do |j|
            used[i][j] = true
          end
        end

        res = dfs.call
        return [[start_r, start_c, height, width]] + res if res

        (start_r...start_r + height).each do |i|
          (start_c...start_c + width).each do |j|
            used[i][j] = false
          end
        end
      end
    end

    nil
  end

  pieces_coords = dfs.call
  return [] unless pieces_coords

  result = pieces_coords.map do |r, c, height, width|
    (r...r + height).map { |i| grid[i][c...c + width].join }.join("\n")
  end

  result
end

cake1 = <<~CAKE
  .o......
  ......o.
  ....o...
  ..o.....
CAKE

cake2 = <<~CAKE
  .o.o....
  ........
  ....o...
  ........
  .....o..
  ........
CAKE

puts "Рішення 1:"
result1 = cut_cake(cake1)
puts result1.join("\n,\n")
puts "---"

puts "Рішення 2:"
result2 = cut_cake(cake2)
puts result2.join("\n,\n")
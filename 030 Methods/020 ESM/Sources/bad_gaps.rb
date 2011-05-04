
# discarding schedules where beeps are too close
File.open('/Users/George/Downloads/beeps.csv', 'w') do |csv|
	periods = [0, 240, 480]
	100000.times do
	  begin
	    beeps = periods.each_cons(2).map do |start, stop|
	      start + rand * (stop - start)
	    end
	    too_close = beeps.each_cons(2).any? { |b1, b2| b2 - b1 < 120 }
	  end while too_close
	  beeps.each { |b| csv.puts b }
	end
end

# moving each beep that's too close
File.open('/Users/George/Downloads/beeps2.csv', 'w') do |csv|
	periods = [0, 280, 560, 840]
	100000.times do
	  beeps = periods.each_cons(2).map do |start, stop|
	    start + rand * (stop - start)
	  end
	  (beeps.length - 1).times do |i|
      diff = beeps[i + 1] - beeps[i]
	    if diff < 120
	      push_apart = 120 - diff
	      beeps[i] -= push_apart / 2
	      beeps[i + 1] += push_apart / 2
	    end
	  end
	  beeps.each { |b| csv.puts b }
	end
end

# discarding schedules where beeps are too close AND picking within blocks non-uniformly (not managed yet)
class Rand
  def self.left
    begin
      r1 = rand
    end while (r1 <= 0.5 && rand > 0.5) || (r1 > 0.5 && rand > r1)  # probs for keeping
    r1
  end
  def self.right
    1 - self.left
  end
end
File.open('/Users/George/Downloads/beeps3.csv', 'w') do |csv|
	periods = [0, 240, 480]
	100000.times do
	  begin
	    beeps = periods.each_cons(2).map do |start, stop|
	      r = case start
        when 0 then Rand.left
        when 240 then Rand.right
        end
	      start + r * (stop - start)
	    end
	    too_close = beeps.each_cons(2).any? { |b1, b2| b2 - b1 < 120 }
	  end while too_close
	  beeps.each { |b| csv.puts b }
	end
end



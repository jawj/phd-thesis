
stems = %w{MaxTemp MeanTemp MeanWindSpeed MinTemp RainDays1 RainDays10 Rainfall RelativeHumidity SnowLying Sunshine}
y1, y2 = 2001, 2006
stems.each do |stem|
  (y1..y2).each do |year|
    infile_opts = (1..12).map { |month| "-#{(64 + month).chr} #{stem}_#{y1}-#{y2}/#{stem}_#{year}-#{"%02d" % month}_Actual.txt" }.join(' ')
    calc_opt = "--calc='(#{(1..12).map { |month| (64 + month).chr }.join('+')})/12.0'"
    puts "gdal_calc.py #{infile_opts} #{calc_opt} --outfile=#{stem}_#{year}_Mean.gtiff"
  end
  infile_opts = (y1..y2).map { |year| "-#{(year - y1 + 65).chr} #{stem}_#{year}_Mean.gtiff" }.join(' ')
  calc_opt = "--calc='1000.0*(#{(y1..y2).map { |year| (year - y1 + 65).chr }.join('+')})/#{y2 - y1 + 1}.0'"
  puts "gdal_calc.py #{infile_opts} #{calc_opt} --outfile=#{stem}_MeanK.gtiff"
  puts
end

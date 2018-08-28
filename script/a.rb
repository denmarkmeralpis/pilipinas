require 'pathname'
require 'csv'


regions = {}
cities = []
provinces = []
barangays = []
CSV.foreach('brgys.csv',{ col_sep: ';', header_converters: :symbol, headers: true}) do |row|
   
   region[row[:region].to_sym] = [] if region[:row[:region].to_sym].blank?
   region[row[:region].to_sym] << row[:region]

end













# Dir["cities/*.yml"].each do |file|
   # puts "=============================================\n"
   # puts "PROCESSING #{file} Please wait...\n"
   # puts "=============================================\n"
   # city = Pathname.new(file).basename.to_s.split('.yml').first.downcase
   
   # File.open(file, 'w') do |f|
      # CSV.foreach('brgys.csv',{ header_converters: :symbol, headers: true}) do |row|
      #    if row[:city].downcase == city
      #       f.write("- #{row[:barangay]}\n")
      #    end
      # end
   # end
# end

# prev_region = nil
# prev_province = nil
# prev_city = nil
# prev_brgy = nil

# CSV.foreach('brgys.csv',{ col_sep: ';', header_converters: :symbol, headers: true}) do |row|

#    # if row[:province] == 'METRO MANILA' || row[:province] == 'ABRA'


#       if prev_region != row[:region]
#          File.open("regions/#{row[:region]}.yml", 'w') do |f|
#             f.write("- #{row[:province]}\n")
#          end  
#          puts "=============================================\n"
#          puts "PROCESSING #{row[:region]} Please wait...\n"
#          puts "=============================================\n"
#       else
#          if prev_province != row[:province]
#             File.open("regions/#{row[:region]}.yml", 'a') do |f|
#                f.write("- #{row[:province]}\n")
#             end
#          end
#       end
      
#       # if File.exist?("provinces/#{row[:province]}.yml")
#       #    if prev_city != row[:city]
#       #       File.open("provinces/#{row[:province]}.yml", 'a') do |pr|
#       #          pr.write("- #{row[:city]}\n")
#       #          # pr.write('')
#       #       end
#       #    end
#       # else
#       #    File.open("provinces/#{row[:province]}.yml", 'w') do |pr|
#       #       pr.write("#{row[:city]}\n")
#       #    end   
#       # end

#       if prev_province != row[:province]
#          File.open("provinces/#{row[:province]}.yml", 'a') do |pr|
#             # pr.write("#{row[:province]}:\n - #{row[:city]}\n")
#             pr.write("- #{row[:city]}\n")
#          end
#       else
#          if prev_city != row[:city]
#             File.open("provinces/#{row[:province]}.yml", 'a') do |pr|
#                pr.write("- #{row[:city]}\n")
#             end
#          end
#       end      

#       if prev_city != row[:city]
#          File.open("cities/#{row[:city]}.yml", 'w') do |br|
#             # br.write("#{row[:city]}:\n - #{row[:barangay]}\n")
#             br.write("- #{row[:barangay]}\n")
#          end         
#       else
#          File.open("cities/#{row[:city]}.yml", 'a') do |br|
#             br.write("- #{row[:barangay]}\n")
#          end
#       end

#       prev_region = row[:region]
#       prev_province = row[:province]
#       prev_city = row[:city]

#    # end
   
# end
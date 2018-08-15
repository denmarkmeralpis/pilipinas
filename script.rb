require 'yaml'

dir = Dir['*.yml']


dir.each do |file|
   # File.write('/path/to/file', 'Some glorious content')
   thing = YAML.load_file(file)
   
   thing.each { |t| File.write("aaaa/#{t}.yml", '') }
   
end

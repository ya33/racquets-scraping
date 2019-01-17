require 'byebug'
require 'open-uri'
require 'nokogiri'
require 'json'

racquets_parameters = {
  manufacturers: ['Babolat', 'Head', 'Prince', 'Tecnifibre', 'Wilson', 'Yonex'],
  hsMin: 95,
  hsMax: 100,
  wMin: 10.5,
  wMax: 11.9,
  lMin: '',
  lMax: '',
  swMin: '',
  swMax: '',
  current: ['Y', 'N']
}

racquets = { racquets: [] }
url_finder = 'http://www.racquetfinder.com/'
total_count = 0
racquets_parameters[:manufacturers].each do |manufacturer|
  count_by_brand = 0
  query = "?manufacturer=#{manufacturer}&"\
          "hsMin=#{racquets_parameters[:hsMin]}&hsMax=#{racquets_parameters[:hsMax]}&"\
          "wMin=#{racquets_parameters[:wMin]}&wMax=#{racquets_parameters[:wMax]}&"\
          "lMin=#{racquets_parameters[:lMin]}&lMax=#{racquets_parameters[:lMax]}&"\
          "swMin=#{racquets_parameters[:swMin]}&swMax=#{racquets_parameters[:swMax]}&"\
          "current=#{racquets_parameters[:current][1]}"
  url_query = url_finder + query
  # url_query_test = url_finder + '?manufacturer=Babolat&current=Y'
  html_file = open(url_query).read
  html_doc = Nokogiri::HTML(html_file)
  info = { brand: manufacturer }
  html_doc.search('.rac_info').each do |element|
    info[:name] = element.search('.rac_name').text.strip
    element.search('.rac_specs tr').each do |sub_element|
      info[sub_element.search('th').text.strip.chomp(':').sub(' ', '_').downcase] = sub_element.search('td').text.strip
    end
    racquets[:racquets] << info
    count_by_brand += 1
  end
  puts "#{manufacturer} : #{count_by_brand} racquets"
  total_count += count_by_brand
end
puts "total : #{total_count} racquets"

filepath = 'racquets.json'
File.open(filepath, 'wb') do |file|
  file.write(JSON.generate(racquets))
end

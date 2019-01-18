require 'byebug'
require 'open-uri'
require 'nokogiri'
require 'json'

RACQUETS_PARAMS = {
  manufacturers: ['Babolat', 'Head', 'Pacific', 'Prince', 'ProKennex', 'Tecnifibre', 'Volkl', 'Wilson', 'Yonex'],
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

BALANCE_VALUES = {
  '1 HL' => 33.97,
  '2 HL' => 33.66,
  '3 HL' => 33.34,
  '4 HL' => 33.02,
  '5 HL' => 32.7,
  '6 HL' => 32.39,
  '7 HL' => 32.07,
  '8 HL' => 31.75,
  '9 HL' => 31.43,
  '10 HL' => 31.12,
  '11 HL' => 30.8,
  '12 HL' => 30.48,
  '1 HH' => 34.61,
  '2 HH' => 34.93,
  '3 HH' => 35.24,
  '4 HH' => 35.56,
  '5 HH' => 35.88,
  '6 HH' => 36.2,
  '7 HH' => 36.51,
  '8 HH' => 36.83,
  '9 HH' => 37.15,
  '10 HH' => 37.47,
  '11 HH' => 37.79,
  '12 HH' => 38.1
}

def prepare_to_json(racquets)
  racquets[:racquets].map! do |racquet|
    {
      brand: racquet[:brand],
      model_name: racquet[:name],
      reference_weight: racquet['strung_weight'].split(' / ')[1].delete(' g').to_i,
      reference_balance: BALANCE_VALUES[racquet['balance'].delete('pts')],
      reference_swingweight: racquet['swing_weight'].to_i,
      length: racquet['length'].split(' / ')[1].delete(' cm').to_f,
      stiffness: racquet['stiffness'].to_i,
      string_pattern_mains: racquet['string_pattern'][0..1].to_i,
      string_pattern_crosses: racquet['string_pattern'].split('/')[1][0..1].to_i,
      head_size_cm2: racquet['head_size'].split(' / ')[1].delete(' sq. cm.').to_i,
      head_size_in2: racquet['head_size'].split(' / ')[0].delete(' sq. cm.').to_i,
      composition: racquet['composition']
    }
  end
  racquets
end

def write_to_json(racquets)
  filepath = 'racquets.json'
  File.open(filepath, 'wb') do |file|
    file.write(JSON.generate(racquets))
  end
end

def scrap_TW(params)
  racquets = { racquets: [] }
  url_finder = 'http://www.racquetfinder.com/'
  total_count = 0
  params[:manufacturers].each do |manufacturer|
    count_by_brand = 0
    query = "?manufacturer=#{manufacturer}&"\
            "hsMin=#{params[:hsMin]}&hsMax=#{params[:hsMax]}&"\
            "wMin=#{params[:wMin]}&wMax=#{params[:wMax]}&"\
            "lMin=#{params[:lMin]}&lMax=#{params[:lMax]}&"\
            "swMin=#{params[:swMin]}&swMax=#{params[:swMax]}&"\
            "current=#{params[:current][1]}"
    url_query = url_finder + query
    # url_query_test = url_finder + '?manufacturer=Babolat&current=Y'
    html_file = open(url_query).read
    html_doc = Nokogiri::HTML(html_file)
    html_doc.search('.rac_info').each do |element|
      records = { brand: manufacturer }
      records[:name] = element.search('.rac_name').text.strip
      element.search('.rac_specs tr').each do |sub_element|
        value = sub_element.search('td').text.start_with?("\xA0") ? "" : sub_element.search('td').text.strip
        records[sub_element.search('th').text.strip.chomp(':').sub(' ', '_').downcase] = value
      end
      racquets[:racquets] << records
      count_by_brand += 1
    end
    puts "#{manufacturer} : #{count_by_brand} racquets"
    total_count += count_by_brand
  end
  puts "total : #{total_count} racquets"
  racquets_json = prepare_to_json(racquets)
  racquets_json[:total_racquets_number] = total_count
  write_to_json(racquets_json)
end

scrap_TW(RACQUETS_PARAMS)

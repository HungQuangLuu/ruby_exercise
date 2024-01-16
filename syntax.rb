require 'json'
require 'date'

CATEGORIES_HASH = {
  1 => :Restaurant,
  2 => :Retail,
  3 => :Hotel,
  4 => :Activity
}

class FileManager
  def initialize(file_name)
    @file_name = file_name
  end 
  
  def read_input_file
    begin
      json_data = File.read(@file_name)
      offers_hash = JSON.parse(json_data)
    rescue Errno::ENOENT
      puts "File not found: #{@file_name}"
    rescue JSON::ParserError
      puts "Error parsing JSON in the file: #{@file_name}"
    end

    offers_hash["offers"]
  end

  def write_output_file(orders_hash)
    file_path = "output.json"
    file_exists = File.file?(file_path)
    
    json_data = JSON.generate(orders_hash)
    puts orders_hash
    puts json_data
    
    File.open(file_path, 'w') { |file| file.write(json_data) }
  end
end

class OfferManager
  def filter_offers(offers, checkin_date)
    @valid_date = Date.parse(checkin_date) + 5

    #filter offers with valid date and valid category
    offers.select! do |offer|
      is_time_valid = Date.parse(offer["valid_to"]) > @valid_date
      is_category_valid = CATEGORIES_HASH.include? offer["category"]
      is_time_valid && is_category_valid
    end
    
    # pick only closest merchant
    offers.each do |offer|
      closest_merchant = nil
      offer["merchants"].each do |merchant|
        if closest_merchant.nil?
          closest_merchant = merchant
        else
          closest_merchant = merchant if merchant["distance"] < closest_merchant["distance"]
        end
      end 
      offer["merchants"] = closest_merchant
    end

    if offers.size == 0
      return []
    elsif offers.size == 1
      return offers[0]
    end

    #sort the offers by distance
    offers.sort_by { |offer| offer["merchants"]["distance"]}
    return Hash["offers" => [offers[0], offers[1]]]
  end
end

class InputManager 
  def initialize(offer_manager, file_manager)
    @offer_manager = offer_manager
    @file_manager = file_manager 
  end

  def handle_input
    date_input = nil
    while true do 
      date_regex = /\A\d{4}-\d{2}-\d{2}\z/
      puts "Input a check-in date: "
      date_input = gets.chomp
      is_valid_date = !!(date_input =~ date_regex)
      if is_valid_date 
        break
      else 
        puts "Invalid input!"
      end
    end
    offers = @file_manager.read_input_file
    filtered_offers = @offer_manager.filter_offers(offers, date_input)
    @file_manager.write_output_file(filtered_offers)
  end
end

file_manager = FileManager.new("input.json")
offer_manager = OfferManager.new
InputManager.new(offer_manager, file_manager).handle_input

# file_content = File.read('output.json')
# puts file_content

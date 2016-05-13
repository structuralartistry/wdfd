require 'csv'
require 'sequel'

class Wdfd
  attr_accessor :data

  def initialize
    @data = Sequel.sqlite

    @data.create_table :address do
      primary_key :id
      String :street
      String :apt
      String :city
      String :state
      String :zip
      String :precinct_identifier_raw
      String :precinct_identifier
    end

    @data.create_table :precinct do
      primary_key :id
      String :name
      String :number
      String :precinct_identifier_raw
      String :precinct_identifier
    end

    @data.create_table :polling_location do
      primary_key :id
      String :address_line1
      String :address_city
      String :address_state
      String :address_zip
    end

    @data.create_table :precinct_polling_location do
      primary_key :id
      Integer :precinct_id
      Integer :polling_location_id
    end

  end

  def parse_csv(file_path)
    csv_text = File.read('addresses.csv')
    csv = CSV.parse(csv_text, :headers => true)
  end

  def populate_addresses
    addressess = @data[:address]

    csv_text = File.read('addresses.csv')
    csv = CSV.parse(csv_text, :headers => true)

    csv.each do |row|

      # key fields, halt if not found... in long term handling non-conforming data
      # could be automated
      throw "No raw precinct identifier for row #{row}" unless row['Precinct ID']
      throw "No state for row #{row}" unless row['State']

      @data[:address].insert(
        street: row['Street'],
        apt: row['Apt'],
        city: row['City'],
        state: row['State'].upcase,
        zip: row['Zip'],
        precinct_identifier_raw: row['Precinct ID'],
        precinct_identifier: row['Precinct ID'].split(//).last(3).join
      )
    end
  end

  def populate_precinct_polling_locations
    precincts = @data[:precinct]
    polling_locations = @data[:polling_location]
    precinct_polling_locations = @data[:precinct_polling_location]

    csv_text = File.read('precinct_polling_list.csv')
    csv = CSV.parse(csv_text, :headers => true)

    csv.each do |row|

      # halt if precinct key not found... in future automate failure handling
      # for now notifies us to correct the data before processing
      throw "No raw precinct identifier for row #{row}" unless row['Precinct']

      # create precinct if does not exist
      precinct = precincts.first(precinct_identifier_raw: row['Precinct'])
      precinct_id = precinct.id if precinct
      unless precinct
        precinct_id = precincts.insert(number: row['Precinct'],
                                    precinct_identifier_raw: row['Precinct'],
                                    precinct_identifier: row['Precinct'].split(//).last(3).join)

      end

      state_zip = row['State/ZIP'].split(/ /)
      throw "Malformed State for State/ZIP #{row['State/ZIP']}, row #{row}" unless state_zip[0].length == 2
      polling_location = polling_locations.insert(
        address_line1: row['Street'],
        address_city: row['City'],
        address_state: state_zip[0],
        address_zip: state_zip[1]
      )

      precinct_polling_location = precinct_polling_locations.insert(
        precinct_id: precinct_id,
        polling_location_id: polling_location
      )

    end
  end

  def generate_addresses_with_polling_locations_csv
    sql = "SELECT * FROM address"

    result = @data.fetch(sql)

    CSV.open("addresses_with_polling_locations.csv", "wb") do |csv|

      csv << [ 'address_street', 'address_apt', 'address_city', 'address_state', 'address_zip', 'polling_address',
               'polling_city', 'polling_state', 'polling_zip' ]
      result.each do |row|
        polling_location = get_polling_location_for_address(row[:state],
                                                            row[:zip], row[:precinct_identifier])
        data = [ row[:street], row[:apt], row[:city], row[:state], row[:zip],
                polling_location[:address_line1], polling_location[:address_city], polling_location[:address_state],
                polling_location[:address_zip] ]
        csv << data
      end
    end
  end

  def get_polling_location_for_address(state_abbreviation, zipcode, precinct_identifier)
    result = nil

    # first try to match on state and precinct identifier
    sql = "SELECT polling_location.*
           FROM precinct
           JOIN precinct_polling_location on precinct_polling_location.precinct_id = precinct.id
           JOIN polling_location ON precinct_polling_location.polling_location_id = polling_location.id
           WHERE polling_location.address_state = '#{state_abbreviation}' AND precinct.precinct_identifier = '#{precinct_identifier}'"
    result = @data.fetch(sql)

    unless result.first
      # if no match, match on zip code
      sql = "SELECT polling_location.*
             FROM polling_location
             WHERE polling_location.address_zip = '#{zipcode}'"
      result = @data.fetch(sql)
    end

    unless result.first
      # if no match, match on zip code
      sql = "SELECT polling_location.*
             FROM precinct
             JOIN precinct_polling_location on precinct_polling_location.precinct_id = precinct.id
             JOIN polling_location ON precinct_polling_location.polling_location_id = polling_location.id
             WHERE polling_location.address_state = '#{state_abbreviation}'"
      result = @data.fetch(sql)
    end

    begin
      result = result.first
    rescue
      throw "Failed to find polling location for state, zipcode, precinct: #{state_abbreviation} #{zipcode} #{precinct_identifier}"
    end

    result
  end

  def generate_precinct_txt
    sql = "SELECT * FROM precinct"

    result = @data.fetch(sql)

    CSV.open("precinct.txt", "wb") do |csv|
      csv << [ 'name','number','locality_id','ward','mail_only','ballot_style_image_url','id' ]
      result.each do |row|
        data = [ row[:name], row[:number], row[:locality_id], row[:ward], row[:mail_only],
                row[:ballot_style_image_url], '100' + row[:id].to_s ]
        csv << data
      end
    end
  end

  def generate_polling_location_txt
    sql = "SELECT * FROM polling_location"

    result = @data.fetch(sql)

    CSV.open("polling_location.txt", "wb") do |csv|
      csv << [ 'address_location_name','address_line1','address_line2','address_line3','address_city','address_state','address_zip','directions','polling_hours','photo_url','id']
      result.each do |row|
        data = [ row[''], row[:address_line1], row[''], row[''], row[:address_city], row[:address_state], row[:address_zip], row[''], row[''], row[''], '200' + row[:id].to_s ]
        csv << data
      end
    end
  end

  def generate_precinct_polling_location_txt
    sql = "SELECT * FROM precinct_polling_location"

    result = @data.fetch(sql)

    CSV.open("precinct_polling_location.txt", "wb") do |csv|
      csv << ['precinct_id','polling_location_id']
      result.each do |row|
        data = [ '100' + row[:precinct_id].to_s, '200' + row[:polling_location_id].to_s ]
        csv << data
      end
    end
  end

end

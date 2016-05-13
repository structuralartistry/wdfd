require 'minitest/autorun'
require './wdfd'
require 'byebug'

describe Wdfd do

  before do
    @wdfd = Wdfd.new
  end

  describe '#data' do

    it 'creates the addresses table and can operate' do
      ds = @wdfd.data[:address]

      ds.insert(street: '123 EZ')
      ds.insert(street: '987 Hard')

      assert_equal ds.count, 2
      assert_equal ds.all[1][:id], 2
      assert_equal ds.find(street: '123 EZ').first[:id], 1
    end

  end

  describe '#parse_csv' do

    it 'returns expected data rows compensating for header' do
      expected_row_count = 41
      csv_data = @wdfd.parse_csv('addresses.csv')

      assert_equal expected_row_count, csv_data.length
    end

  end

  describe '#get_polling_location_for_address' do

    before(:each) do
      @wdfd.populate_addresses
      @wdfd.populate_precinct_polling_locations
    end

    it 'gets based on state and precinct id match' do
      result = @wdfd.get_polling_location_for_address('MA', nil, '090')

      assert_equal result[:address_line1], '139 Lynnfield Street'
    end

    it 'gets based on zipcode of initial match on state and precinct fails' do
      result = @wdfd.get_polling_location_for_address('bad zip', '01960', 'bad identifier')

      assert_equal result[:address_line1], '139 Lynnfield Street'
    end

    it 'gets based on state if all else fails' do
      result = @wdfd.get_polling_location_for_address('MA', 'bad zip', 'bad identifier')

      assert_equal result[:address_line1], '150-151 Tremont Street'
    end

  end

  describe '#populate_precinct_polling_locations' do

    it 'works' do
      @wdfd.populate_precinct_polling_locations
      assert_equal 33, @wdfd.data[:precinct_polling_location].count
    end

  end

  describe '#generate_addresses_with_polling_locations_csv' do

    it 'works' do
      @wdfd.populate_addresses
      @wdfd.populate_precinct_polling_locations
      @wdfd.generate_addresses_with_polling_locations_csv

      @wdfd.generate_precinct_txt
      @wdfd.generate_polling_location_txt
      @wdfd.generate_precinct_polling_location_txt
    end

  end

end


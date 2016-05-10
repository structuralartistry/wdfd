require 'minitest/autorun'
require './wdfd'
require 'byebug'

describe Wdfd do

  before do
    @wdfd = Wdfd.new
  end

  describe '#data' do

    it 'creates the addresses table and can operate' do
      ds = @wdfd.data[:addresses]

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

end

describe WdfdDb do

end

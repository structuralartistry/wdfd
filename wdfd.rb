require 'csv'
require 'sequel'

class Wdfd
  attr_accessor :data

  def initialize
    @data = Sequel.sqlite

    @data.create_table :addresses do
      primary_key :id
      String :street
      String :apt
      String :city
      String :state
      String :zip
      String :precinct_id
    end

  end

  def parse_csv(file_path)
    csv_text = File.read('addresses.csv')
    csv = CSV.parse(csv_text, :headers => true)
  end

end

class WdfdDb

end


## connect to an in-memory database
#DB = Sequel.sqlite
#
## create an items table
#DB.create_table :items do
#  primary_key :id
#  String :name
#  Float :price
#end
#
## create a dataset from the items table
#items = DB[:items]
#
## populate the table
#items.insert(:name => 'abc', :price => rand * 100)
#items.insert(:name => 'def', :price => rand * 100)
#items.insert(:name => 'ghi', :price => rand * 100)
#
## print out the number of records
#puts "Item count: #{items.count}"
#
## print out the average price
#puts "The average price is: #{items.avg(:price)}"
#
#

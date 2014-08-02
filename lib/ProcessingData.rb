# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  3/1/2013

require_relative 'LoadingVegData.rb'
require_relative 'DataFrame.rb'
require 'sqlite3'
require 'set'
#Import a given hash into a given table in a data_base
def add_to_data_base(data_frame, data_base, table_name, types=nil)
  #Assertion checks
  unless data_frame.is_a? DataFrame then raise(RuntimeError, "Can only add a DataFrame into a database") end
  temp = data_base.execute "SELECT name FROM sqlite_master WHERE type='table' AND name='#{table_name}';"
  unless temp[0] then raise RuntimeError, "Table #{table_name} does not exist in database" end
    
  #Assign column types
  unless types then types = ["TEXT"] * data_frame.ncol end
  
  #Add into database
  header = "INSERT INTO #{table_name} "
  elements = []
  data_frame.col_names.each{|column, value| elements << column.to_s}
  header = header + "(" + elements.join(", ") + ")"
  commands = []
  data_base.transaction do |trans|
    data_frame.each_row do |row|
      command = header + ' VALUES ("' + row.join('", "') + '")'
      trans.execute command
      commands << command
    end
  end
  return commands
end

#Clean breaking characters from input
def clean_strings(data_frame)
  #Assertion checks
  unless data_frame.is_a? DataFrame then raise(RuntimeError, "Can only clean a DataFrame") end
  
  #Remove quotes
  def remove_quotes(string)
    #Do nothing is string is nil, etc.
    if string.is_a? String
      string.gsub!("'", "")
      string.gsub!('"', "")
    end
    return string
  end
  data_frame.each_column do |column, value|
    data_frame.data[column] = value.map{|x| remove_quotes(x)}
  end
  
  return data_frame
end

#Build a common DataFrame of species names
def merge_names(data_array)
  #Assertions
  unless data_array.is_a? Array then raise(RuntimeError, "Need array of DataFrames") end
  unless data_array.map{|x| x.is_a? DataFrame}.uniq==[true] then raise(RuntimeError, "Need array of DataFrames") end
  
  #We don't want to alter in-place, so make a copy
  data_array = Marshal::load(Marshal.dump(data_array))
  
  #Make common list of sp_common
  species = [].to_set
  data_array.each do |data|
    data[:sp_binomial].each do |sp|
      if sp then species << sp.downcase end
    end
  end
  #Convert into an array, and make replacement sp_binomial entries
  species = species.to_a
  species.sort!
  data_array.each_with_index do |data, i|
    data_array[i].insert :sp_index
    data[:sp_binomial].each_with_index do |sp, j|
      if sp then data_array[i][:sp_index][j] = species.find_index sp.downcase end
    end
    data.delete :sp_binomial
  end
  #Make the summary species mapping DataFrame
  species_mapping = DataFrame.new({:sp_binomial=>species, :sp_index=>(0...species.length).to_a})
  return [data_array, species_mapping]
end

#Build a common DataFrame of city_parcel
def merge_cpp(data_array)
  #Assertions
  unless data_array.is_a? Array then raise(RuntimeError, "Need array of DataFrames") end
  unless data_array.map{|x| x.is_a? DataFrame}.uniq==[true] then raise(RuntimeError, "Need array of DataFrames") end
  
  #We don't want to alter in-place, so make a copy
  data_array = Marshal::load(Marshal.dump(data_array))
  
  #Make common list of cpp
  cpp = [].to_set
  data_array.each do |data|
    data[:city_parcel].each do |plot|
      if plot then cpp << plot end
    end
  end
  #Convert into an array, and make replacement cpp_index entries
  cpp = cpp.to_a
  cpp.sort!
  data_array.each_with_index do |data, i|
    data_array[i].insert :cpp_index
    data[:city_parcel].each_with_index do |plot, j|
      if plot then data_array[i][:cpp_index][j] = cpp.find_index plot end
    end
    data.delete :city_parcel
  end
  #Make the summary species mapping DataFrame
  cpp_mapping = DataFrame.new({:city_parcel=>cpp, :cpp_index=>(0...cpp.length).to_a})
  return [data_array, cpp_mapping]
end

def change_names!(mapping, data_frame, to_replace)
  #Assertions
  unless mapping.is_a? Hash then raise(RuntimeError, "Need hash for name mapping") end
  unless data_frame.is_a? DataFrame then raise(RuntimeError, "Need DataFrame to alter name mapping") end
  unless to_replace.is_a? Symbol then raise(RuntimeError, "Need symbol for name mapping") end
  unless data_frame.col_names.include? to_replace then raise(RuntimeError, "DataFrame must contain replacement column") end
  
  #We are altering in place, remember
  mapping.each do |name, replacement|
    data_frame[to_replace].map! {|each| if each == name then replacement else each end }
  end
end

def change_names_regex!(mapping, data_frame, to_replace)
    #Assertions
  unless mapping.is_a? Hash then raise(RuntimeError, "Need hash for name mapping") end
  unless data_frame.is_a? DataFrame then raise(RuntimeError, "Need DataFrame to alter name mapping") end
  unless to_replace.is_a? Symbol then raise(RuntimeError, "Need symbol for name mapping") end
  unless data_frame.col_names.include? to_replace then raise(RuntimeError, "DataFrame must contain replacement column") end
  #We are altering in place, remember
  mapping.each do |regex, replacement|
    data_frame[to_replace].map! {|each| each = each.gsub(regex, replacement)}
  end
end

#Run tests if we're running this from the command line
if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  
  describe proc {add_to_data_base} do
    it "Inserts data correctly" do
      db = SQLite3::Database.open "assertion_test.db"
      db.execute "CREATE TABLE VegSurvey (city_parcel TEXT, sp_common TEXT, sp_binomial TEXT, sp_native TEXT, location TEXT, cultivation TEXT, notes TEXT)"
      data = read_veg_survey("test_files/miami.xlsx", "miami")
      temp = add_to_data_base(data, db, "VegSurvey", nil)
      assert temp == ["INSERT INTO VegSurvey (city_parcel, sp_common, sp_binomial, sp_native, location, cultivation, notes) VALUES (\"FL_827\", \"\", \"Bidens_alba\", \"true\", \"frontLawn\", \"S-5\", \"\")", "INSERT INTO VegSurvey (city_parcel, sp_common, sp_binomial, sp_native, location, cultivation, notes) VALUES (\"FL_827\", \"\", \"Bidens_alba\", \"true\", \"backLawn\", \"S-5\", \"\")", "INSERT INTO VegSurvey (city_parcel, sp_common, sp_binomial, sp_native, location, cultivation, notes) VALUES (\"FL_827\", \"\", \"Youngia_japonica\", \"true\", \"frontLawn\", \"S-5\", \"\")", "INSERT INTO VegSurvey (city_parcel, sp_common, sp_binomial, sp_native, location, cultivation, notes) VALUES (\"FL_827\", \"\", \"Youngia_japonica\", \"true\", \"backLawn\", \"S-5\", \"\")", "INSERT INTO VegSurvey (city_parcel, sp_common, sp_binomial, sp_native, location, cultivation, notes) VALUES (\"FL_827\", \"\", \"Phyla_nodiflora\", \"true\", \"frontLawn\", \"S-5\", \"\")", "INSERT INTO VegSurvey (city_parcel, sp_common, sp_binomial, sp_native, location, cultivation, notes) VALUES (\"FL_827\", \"\", \"Stenotaphrum_secundatum\", \"true\", \"frontLawn\", \"S-5\", \"\")", "INSERT INTO VegSurvey (city_parcel, sp_common, sp_binomial, sp_native, location, cultivation, notes) VALUES (\"FL_827\", \"\", \"Stenotaphrum_secundatum\", \"true\", \"backLawn\", \"S-5\", \"\")"]
      File.delete "assertion_test.db"
    end
  end
  
  describe proc {merge_names} do
    it "Merges names correctly" do
      data = read_veg_survey("test_files/miami.xlsx", "miami")
      data2 = read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix")
      merger = merge_names([data, data2])
      assert merger[0][0].data == {:city_parcel=>["FL_827", "FL_827", "FL_827", "FL_827", "FL_827", "FL_827", "FL_827"], :sp_common=>["", "", "", "", "", "", ""], :sp_native=>[true, true, true, true, true, true, true], :location=>["frontLawn", "backLawn", "frontLawn", "backLawn", "frontLawn", "frontLawn", "backLawn"], :cultivation=>["S-5", "S-5", "S-5", "S-5", "S-5", "S-5", "S-5"], :notes=>["", "", "", "", "", "", ""], :sp_index=>[7, 7, 10, 10, 8, 9, 9]}
      assert merger[0][1].data == {:city_parcel=>["MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_2", "MN_StCroix_3", "MN_StCroix_4", "MN_StCroix_1", "MN_StCroix_2", "MN_StCroix_3", "MN_StCroix_4", "MN_StCroix_1", "MN_StCroix_2", "MN_StCroix_3", "MN_StCroix_4"], :transect=>[1, 1, 1, 1, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4], :sp_index=>[0, 1, 2, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6]}
      assert merger[1].data == {:sp_binomial=>["acer negundo", "achillea millefolium", "ageratina altissima", "amaranthus retroflexus", "ambrosia coronopifolia", "amorpha canescens", "amphicarpaea bracteata", "bidens_alba", "phyla_nodiflora", "stenotaphrum_secundatum", "youngia_japonica"], :sp_index=>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}
    end
    it "Creates copies" do
      data = read_veg_survey("test_files/miami.xlsx", "miami")
      data2 = read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix")
      merge_names([data, data2])
      assert data == read_veg_survey("test_files/miami.xlsx", "miami")
      assert data2 == read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix")
    end
  end
  
  describe proc {merge_cpp} do
    it "Merges city_parcel correctly" do
      data = read_veg_survey("test_files/miami.xlsx", "miami")
      data2 = read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix")
      merger = merge_cpp([data, data2])
      assert merger[0][0].nrow == 7
      assert merger[0][0].ncol ==7
      assert merger[0][0].data == {:sp_common=>["", "", "", "", "", "", ""], :sp_binomial=>["Bidens_alba", "Bidens_alba", "Youngia_japonica", "Youngia_japonica", "Phyla_nodiflora", "Stenotaphrum_secundatum", "Stenotaphrum_secundatum"], :sp_native=>[true, true, true, true, true, true, true], :location=>["frontLawn", "backLawn", "frontLawn", "backLawn", "frontLawn", "frontLawn", "backLawn"], :cultivation=>["S-5", "S-5", "S-5", "S-5", "S-5", "S-5", "S-5"], :notes=>["", "", "", "", "", "", ""], :cpp_index=>[0, 0, 0, 0, 0, 0, 0]}
      assert merger[0][1].nrow == 16
      assert merger[0][1].ncol == 3
      assert merger[0][1].data == {:sp_binomial=>["Acer negundo", "Achillea millefolium", "Ageratina altissima", "Amaranthus retroflexus", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Amorpha canescens", "Amorpha canescens", "Amorpha canescens", "Amorpha canescens", "Amphicarpaea bracteata", "Amphicarpaea bracteata", "Amphicarpaea bracteata", "Amphicarpaea bracteata"], :transect=>[1, 1, 1, 1, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4], :cpp_index=>[1, 1, 1, 1, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]}
      assert merger[1].data == {:city_parcel=>["FL_827", "MN_StCroix_1", "MN_StCroix_2", "MN_StCroix_3", "MN_StCroix_4"], :cpp_index=>[0, 1, 2, 3, 4]}
    end
    it "Creates copies" do
      data = read_veg_survey("test_files/miami.xlsx", "miami")
      data2 = read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix")
      merge_cpp([data, data2])
      assert data == read_veg_survey("test_files/miami.xlsx", "miami")
      assert data2 == read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix")
    end
  end
  
  describe proc {clean_strings} do
    it "Cleans DataFrames correctly" do
      data = DataFrame.new({:sp_binomial=>['Bob"s Dylan', "Bob's uncle"], :sp_common=>["Bob's Dylan", "Bobs uncle"]})
      assert clean_strings(data) == DataFrame.new({:sp_binomial=>["Bobs Dylan", "Bobs uncle"], :sp_common=>["Bobs Dylan", "Bobs uncle"]})
    end
  end

  describe proc {change_names} do
    it "Alters DataFrames correctly and in-place" do
      t_map = {"NA_NA"=>"Bristol_1"}
      t_data_frame = DataFrame.new({:city_parcel=>["Bristol_1", "Bristol_2", "NA_NA"], :cpp_index=>[1,2,3]})
      change_names!(t_map, t_data_frame, :city_parcel)
      assert t_data_frame.data == {:city_parcel=>["Bristol_1", "Bristol_2", "Bristol_1"], :cpp_index=>[1, 2, 3]}
    end
    it "Returns errors if passed incorrect information" do
      t_map = {"NA_NA"=>["Bristol_1"]}
      wrong_map = {"NA_something_NA"=>["Bristol_1"]}
      t_data_frame = DataFrame.new({:city_parcel=>["Bristol_1", "Bristol_2", "NA_NA"], :cpp_index=>[1,2,3]})
      assert_raises RuntimeError do 
        change_names!(t_map, t_data_frame, :wrong)
      end
    end
  end

  describe proc {change_names_regex} do
    it "Alters DataFrames correctly and in-place" do
      t_map = {"Bristol_"=>"BS_"}
      t_data_frame = DataFrame.new({:city_parcel=>["Bristol_1", "Bristol_2", "NA_NA"], :cpp_index=>[1,2,3]})
      change_names_regex!(t_map, t_data_frame, :city_parcel)
      assert t_data_frame.data == {:city_parcel=>["BS_1", "BS_2", "NA_NA"], :cpp_index=>[1, 2, 3]}
    end
    it "Returns errors if passed incorrect information" do
      t_map = {"NA_NA"=>["Bristol_1"]}
      wrong_map = {"NA_something_NA"=>["Bristol_1"]}
      t_data_frame = DataFrame.new({:city_parcel=>["Bristol_1", "Bristol_2", "NA_NA"], :cpp_index=>[1,2,3]})
      assert_raises RuntimeError do 
        change_names!(t_map, t_data_frame, :wrong)
      end
    end
  end
  
  if File.file? "assertion_test.db"
    File.delete "assertion_test.db"
  end
end

# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  3/1/2013

require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

#Load iTree data
def read_iTree(file_name)
  output={:city_parcel_plot=>[],:tree_no=>[],:sp_common=>[],:dbh=>[],:height=>[],:ground_area=>[],:condition=>[],:leaf_area=>[],:leaf_biomass=>[],:leaf_area_index=>[],:carbon_storage=>[],:gross_carbon_seq=>[],:money_value=>[],:street=>[],:native=>[]}
  curr_file = UniSheet.new file_name
  curr_file.each do |line|
    if line[0] and line[0] != "City ID"
      output[:city_parcel_plot] << [line[0], line[1], line[2]].join("_")
      output[:tree_no] << line[5]
      output[:sp_common] << line[6]
      output[:dbh] << line[7]
      output[:height] << line[8]
      output[:ground_area] << line[9]
      output[:condition] << line[10]
      output[:leaf_area] << line[11]
      output[:leaf_biomass] << line[12]
      output[:leaf_area_index] << line[13]
      output[:carbon_storage] << line[14]
      output[:gross_carbon_seq] << line[15]
      output[:money_value] << line[16]
      output[:street] << line[17]
      output[:native] << line[18]
    end
  end
  return output
end

#Vegetation surveys
# - Miami data distinguish between front and back 'PG'
def read_veg_survey(file_name, format, name=nil, verbose=true)
  #Helper function to write entries
  def make_entry(state, parcel, sp_common='', sp_binomial='', location_index='', cultivation='', notes='', sp_native='', perenial_garden_split=false)
    begin
      if perenial_garden_split
        location = ['frontLawn', 'backLawn', 'perennialGardenFront', 'perennialGardenBack', 'woodLot', 'annualPlanting'][location_index]
      else
        location = ['frontLawn', 'backLawn', 'perennialGarden', 'woodLot', 'annualPlanting'][location_index]
      end
    rescue Exception => e
      raise RuntimeError, "Bad columns in #{state} - #{parcel}"
    end
    city_parcel_plot = [state, parcel, location].join("_")
    return DataFrame.new({:city_parcel_plot=>[city_parcel_plot],:sp_common=>[sp_common],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>[location],:cultivation=>[cultivation], :notes=>[notes]})
  end
  
  curr_file = UniSheet.new file_name
  output = DataFrame.new({:city_parcel_plot=>[],:sp_common=>[],:sp_binomial=>[],:sp_native=>[],:location=>[],:cultivation=>[], :notes=>[]})
  case
  when format.downcase == "baltimore"
    curr_file.each do |line|
      if line[0] and line[1] and line[0] != "Common name"
        (4..8).each do |i|
          if line[i] then output << make_entry("BA", curr_file[1][5], line[0], line[1], i-4, line[i], line[3]) end
        end
      end
    end
  
  #Balitmore data have 'corrections' - the format of these files are strange and worth investigating
  #Ignores anything with no species name
  when format.downcase == "baltimore corrections"
    curr_file.each do |line|
      if line[0] and line[2] and line[0] != "BES Backyard Plant IDs - Last Set Status 1 January 2013" and line[0] != "CD_ID"
       entry = DataFrame.new({:city_parcel_plot=>[["Baltimore", line[2], "NA"].join("_")],:sp_common=>[''],:sp_binomial=>[''],:sp_native=>[''],:location=>[''],:cultivation=>[''], :notes=>['']})
        if line[4] then entry[:sp_binomial][0] = line[4] end
        if line[6] then entry[:notes][0] = line[6] end
        output << entry
      else
        if verbose
          warn "Skipping row #{line[0]} in #{file_name}; no useful information"
        end
      end
    end
  
  when format.downcase == "minnesota"
    curr_file.each do |line|
      if line[0] != "Site"
        (3..7).each do |i|
          if line[i] then output << make_entry("MN", line[0].to_i, line[1], line[2], i-3, line[i]) end
        end
      end
    end
  
  when format.downcase == "miami"
    curr_file.each do |line|
      if line[0] and line[0] != "ID"
        (8..13).each do |i|
          if line[i]!="" then output << make_entry("FL", line[1], "", [line[4], line[5]].join("_"), i-8, line[i], "", true) end
        end
      end
    end
  else
    raise RuntimeError, "Unknown file format #{format} for file #{file_name}"
  end
  return output
end

#Transect surveys (of non-urban areas)
def read_veg_transect(file_name, format, state, parcel)
  curr_file = UniSheet.new file_name
  output = DataFrame.new({:city_parcel_plot=>[], :sp_binomial=>[], :transect=>[]})
  case
  when format.downcase == "minnesota"
    curr_file.each do |line|
      if line[5]
        (1..4).each do |i|
          #Transect is simply i because we want transect 1 to be transect 1, not transect 0
          if line[i] then output << {:city_parcel_plot=>[[state, parcel, i.to_i].join("_")], :sp_binomial=>[line[0]], :transect=>[i.to_i]} end
        end
      end
    end
  else
    raise RuntimeError, "Unknown file format #{format} for file #{file_name}"
  end
  return output
end

#Lawn abundance surveys
def read_lawn_survey(file_name, format)
  curr_file = UniSheet.new file_name
  #Helper function - assumes particular ordering of front and back lawns
  def make_entry(state, parcel, sp_binomial='', sp_common='', location_index)
    begin
      location = ["F1", "F2", "F3", "B1", "B2", "B3"][location_index]
    rescue Exception => e
      raise RuntimeError, "Bad columns in #{state} - #{parcel}"
    end
    return DataFrame.new({:city_parcel_plot=>[[state, parcel, location].join("_")], :sp_binomial=>[sp_binomial], :sp_common=>[sp_common], :location=>[location]})
  end
  
  output = DataFrame.new({:city_parcel_plot=>[], :sp_binomial=>[], :sp_common=>[], :location=>[]})
  case
  when format.downcase == "minnesota"
    curr_file.each do |line|
      if line[0] and line[0]!= "Site" 
        (4..9).each do |i|
           if line[i] then output << make_entry("MN", line[0].to_i, line[3], line[2], i-4) end
         end
       end
     end
   else
     raise RuntimeError, "Unknown file format #{format} for file #{file_name}"
   end
   return output
 end

if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  
  #iTree tests
  describe proc {read_iTree} do
    it "loads iTree data correctly" do
      assert read_iTree("test_files/iTree.csv") == {:city_parcel_plot=>["MSP_Lost Valley Prairie_1", "MSP_Lost Valley Prairie_1", "MSP_Lost Valley Prairie_2", "MSP_Lost Valley Prairie_2", "MSP_Lost Valley Prairie_2"], :tree_no=>["1", "2", "1", "2", "3"], :sp_common=>["Eastern white pine", "Boxelder", "Eastern red cedar", "Boxelder", "Boxelder"], :dbh=>["7.5", "4.8", "19", "29.2", "29.8"], :height=>["12", "8", "8.5", "19.5", "17.5"], :ground_area=>["6.6", "8.6", "21.2", "75.4", "51.5"], :condition=>["Poor", "Fair", "Poor", "Good", "Fair"], :leaf_area=>["8.33", "14.64", "84.66", "373.98", "160.12"], :leaf_biomass=>["0.54", "1.34", "23.52", "34.21", "14.65"], :leaf_area_index=>["1.26", "1.71", "3.99", "4.96", "3.11"], :carbon_storage=>["3.4", "3.73", "42.72", "210.98", "214.2"], :gross_carbon_seq=>["0.5", "1.06", "1.81", "9.6", "9.62"], :money_value=>["84", "57", "210", "745", "662"], :street=>["NO", "NO", "NO", "NO", "NO"], :native=>["YES", "YES", "YES", "YES", "YES"]}
    end
  end
  
  #Vegetation Survey tests
  describe proc {read_veg_survey} do
    it "Loads Baltimore data correctly" do
      temp = read_veg_survey("test_files/baltimore.xlsx", "baltimore")
      assert temp.data == {:city_parcel_plot=>["BA_250_perennialGarden", "BA_250_frontLawn", "BA_250_perennialGarden"], :sp_common=>["chives", "lesser periwinkle", "chinese holly"], :sp_binomial=>["Allium schoenoprasum", "Vinca minor", "Ilex cornuta"], :sp_native=>["", "", ""], :location=>["perennialGarden", "frontLawn", "perennialGarden"], :cultivation=>["C-1 F", "C-1", "C-1 B"], :notes=>["Europe/Asia/North America", "Europe", "Asia"]}
      assert temp.nrow == 3
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel_plot, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Balitmore corrections data" do
      #Note: setting verbose to false, which also requires explicitly setting the name to nil
      temp = read_veg_survey("test_files/baltimore_corrections.xlsx", "baltimore corrections", nil, false)
      assert temp.data == {:city_parcel_plot=>["Baltimore_250_NA", "Baltimore_250_NA", "Baltimore_250_NA", "Baltimore_250_NA", "Baltimore_250_NA", "Baltimore_603_NA", "Baltimore_603_NA", "Baltimore_603_NA"], :sp_common=>["", "", "", "", "", "", "", ""], :sp_binomial=>["Solidago gigantea", "", "", "", "", "Leersia", "Festuca", "Danthonia spicata"], :sp_native=>["", "", "", "", "", "", "", ""], :location=>["", "", "", "", "", "", "", ""], :cultivation=>["", "", "", "", "", "", "", ""], :notes=>["", "fern pinnae", "1/2 fern frond", "woody seedling", "woody", "Hanover, MD", "", ""]}
      assert temp.nrow == 8
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel_plot, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Minnesota urban data correctly" do
      temp = read_veg_survey("test_files/minnesota_urban.xls", "minnesota")
      assert temp.data == {:city_parcel_plot=>["MN_7_frontLawn", "MN_7_perennialGarden", "MN_7_perennialGarden", "MN_7_frontLawn", "MN_7_backLawn", "MN_7_perennialGarden", "MN_7_frontLawn", "MN_7_perennialGarden"], :sp_common=>["Norway Maple", "Sugar Maple", "Goutweed", "Colonial Bentgrass", "Colonial Bentgrass", "Hollyhock", "Redroot Pigweed", "Redroot Pigweed"], :sp_binomial=>["Acer platanoides", "Acer saccharum", "Aegopodium podagraria", "Agrostis tenuis", "Agrostis tenuis", "Alcea rosea", "Amaranthus retroflexus", "Amaranthus retroflexus"], :sp_native=>["", "", "", "", "", "", "", ""], :location=>["frontLawn", "perennialGarden", "perennialGarden", "frontLawn", "backLawn", "perennialGarden", "frontLawn", "perennialGarden"], :cultivation=>["S5", "C1;S5", "C1", "S4", "S4", "C1", "S5", "S5"], :notes=>["", "", "", "", "", "", "", ""]}
      assert temp.nrow == 8
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel_plot, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Miami urban data correctly" do
      temp = read_veg_survey("test_files/miami.xlsx", "miami")
      assert temp.data == {:city_parcel_plot=>["FL_827_frontLawn", "FL_827_backLawn", "FL_827_frontLawn", "FL_827_backLawn", "FL_827_frontLawn", "FL_827_frontLawn", "FL_827_backLawn"], :sp_common=>["", "", "", "", "", "", ""], :sp_binomial=>["Bidens_alba", "Bidens_alba", "Youngia_japonica", "Youngia_japonica", "Phyla_nodiflora", "Stenotaphrum_secundatum", "Stenotaphrum_secundatum"], :sp_native=>[true, true, true, true, true, true, true], :location=>["frontLawn", "backLawn", "frontLawn", "backLawn", "frontLawn", "frontLawn", "backLawn"], :cultivation=>["S-5", "S-5", "S-5", "S-5", "S-5", "S-5", "S-5"], :notes=>["", "", "", "", "", "", ""]}
      assert temp.nrow == 7
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel_plot, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Doesn't care about case in file format" do
      assert read_veg_survey("test_files/baltimore.xlsx", "baltimore").data == read_veg_survey("test_files/baltimore.xlsx", "BaLtImOrE").data
    end
    it "Raises an error if it doesn't know what you've given it" do
      assert_raises(RuntimeError) {read_veg_survey("test_files/baltimore.xlsx", "sadfghj")}
    end
  end
  
  describe proc {read_veg_transect} do
    it "Loads Minnesota data correctly" do
      temp = read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix")
      assert temp.data == {:city_parcel_plot=>["MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_1", "MN_StCroix_2", "MN_StCroix_3", "MN_StCroix_4", "MN_StCroix_1", "MN_StCroix_2", "MN_StCroix_3", "MN_StCroix_4", "MN_StCroix_1", "MN_StCroix_2", "MN_StCroix_3", "MN_StCroix_4"], :sp_binomial=>["Acer negundo", "Achillea millefolium", "Ageratina altissima", "Amaranthus retroflexus", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Amorpha canescens", "Amorpha canescens", "Amorpha canescens", "Amorpha canescens", "Amphicarpaea bracteata", "Amphicarpaea bracteata", "Amphicarpaea bracteata", "Amphicarpaea bracteata"], :transect=>[1, 1, 1, 1, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]}
      assert temp.nrow == 16
      assert temp.ncol == 3
      assert temp.col_names == [:city_parcel_plot, :sp_binomial, :transect]
    end
    it "Doesn't care about case in file format" do
      assert read_veg_transect("test_files/minnesota_rural.xlsx", "minnesota", "MN", "StCroix") == read_veg_transect("test_files/minnesota_rural.xlsx", "mInnEsOtA", "MN", "StCroix")
    end
    it "Raises an error if it doesn't know what you've given it" do
      assert_raises(RuntimeError) {read_veg_transect("test_files/minnesota_rural.xlsx", "asdfghj", "MN", "StCroix")}
    end
  end
  
  describe proc {read_lawn_survey} do
    it "Loads Minnesota data correctly" do
      temp = read_lawn_survey("test_files/minnesota_lawn.xls", "minnesota")
      assert temp.data == {:city_parcel_plot=>["MN_7_F1", "MN_7_F2", "MN_7_B1", "MN_7_B2", "MN_7_B3", "MN_7_F2", "MN_7_F3", "MN_7_B2", "MN_7_F1", "MN_7_F2", "MN_7_F3", "MN_7_B1", "MN_7_B2", "MN_7_B3"], :sp_binomial=>["Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Amaranthus retroflexus", "Amaranthus retroflexus", "Chrysanthemum spp.", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra"], :sp_common=>["Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Redroot Pigweed", "Redroot Pigweed", "Chrysanthemum", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue"], :location=>["F1", "F2", "B1", "B2", "B3", "F2", "F3", "B2", "F1", "F2", "F3", "B1", "B2", "B3"]}
      assert temp.nrow == 14
      assert temp.ncol == 4
      assert temp.col_names == [:city_parcel_plot, :sp_binomial, :sp_common, :location]
    end
    it "Doesn't care about case in file format" do
      assert read_lawn_survey("test_files/minnesota_lawn.xls", "minnesota") == read_lawn_survey("test_files/minnesota_lawn.xls", "mInNeSoTa")
    end
    it "Raises an error if it doesn't know what you've given it" do
      assert_raises(RuntimeError) {read_lawn_survey("test_files/minnesota_lawn.xls", "asdfghjgtre")}
    end
  end
end

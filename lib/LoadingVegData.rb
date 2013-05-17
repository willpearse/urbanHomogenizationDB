# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  3/1/2013

require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

#Load iTree data
def read_iTree(file_name)
  output = DataFrame.new({:city_parcel=>[],:tree_no=>[],:sp_common=>[],:dbh=>[],:height=>[],:ground_area=>[],:condition=>[],:leaf_area=>[],:leaf_biomass=>[],:leaf_area_index=>[],:carbon_storage=>[],:gross_carbon_seq=>[],:money_value=>[],:street=>[],:native=>[]})
  curr_file = UniSheet.new file_name
  curr_file.each do |line|
    if line[0] and line[0] != "City ID"
      output << {:city_parcel=>[[line[0], line[1]].join("_")],:tree_no=>[line[5]],:sp_common=>[line[6]],:dbh=>[line[7]],:height=>[line[8]],:ground_area=>[line[9]],:condition=>[line[10]],:leaf_area=>[line[11]],:leaf_biomass=>[line[12]],:leaf_area_index=>[line[13]],:carbon_storage=>[line[14]],:gross_carbon_seq=>[line[15]],:money_value=>[line[16]],:street=>[line[17]],:native=>[line[18]]}
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
        location = ['frontLawn', 'backLawn', 'perennialGardenFront', 'perennialGardenBack', 'woodLot', 'annualPlanting', 'reference'][location_index]
      else
        location = ['frontLawn', 'backLawn', 'perennialGarden', 'woodLot', 'annualPlanting', 'reference'][location_index]
      end
    rescue Exception => e
      raise RuntimeError, "Bad columns in #{state} - #{parcel}"
    end
    city_parcel = [state, parcel].join("_")
    return DataFrame.new({:city_parcel=>[city_parcel],:sp_common=>[sp_common],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>[location],:cultivation=>[cultivation], :notes=>[notes]})
  end
  #Another helper for Boston, because its format is *completely* different!
  def make_boston_entry(parcel, sp_binomial, front, back, location_code, cultivation, notes, sp_native)
    entries = DataFrame.new({:city_parcel=>[],:sp_common=>[],:sp_binomial=>[],:sp_native=>[],:location=>[],:cultivation=>[], :notes=>[]})
    #The handling in this function is extremely inefficient, but I (personally) think it's easy-enough to read...
    if (front and front.downcase=="na") or (back and back.downcase=="na")
      entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["reference"],:cultivation=>[cultivation],:notes=>[notes]}
    end
    if front and front.downcase=="y"
      location_code.split(",").each do |code|
        if code == "l" or code.include? 'l-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontLawn"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code == "c" or code.include? 'c-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontCultivated"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code.downcase == "v" or code.include? 'v-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontVegetable"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code.downcase == "o" or code.include? 'o-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontUnmanaged"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code.downcase == "w" or code.include? 'w-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontUnmanaged"],:cultivation=>[cultivation],:notes=>[notes]} end
      end
    end
    if back and back.downcase=="y"
      location_code.split(",").each do |code|
        if code == "l" or code.include? 'l-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backLawn"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code == "c" or code.include? 'c-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backCultivated"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code.downcase == "v" or code.include? 'v-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backVegetable"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code.downcase == "o" or code.include? 'o-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontUnmanaged"],:cultivation=>[cultivation],:notes=>[notes]} end
        if code.downcase == "w" or code.include? 'w-' then entries << {:city_parcel=>["BOS_"+parcel],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backWoodlot"],:cultivation=>[cultivation],:notes=>[notes]} end
      end
    end
    return entries
  end
  
  curr_file = UniSheet.new file_name
  output = DataFrame.new({:city_parcel=>[],:sp_common=>[],:sp_binomial=>[],:sp_native=>[],:location=>[],:cultivation=>[], :notes=>[]})
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
       entry = DataFrame.new({:city_parcel=>["BA_"+line[2].to_s],:sp_common=>[''],:sp_binomial=>[''],:sp_native=>[''],:location=>[''],:cultivation=>[''], :notes=>['']})
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

  when format.downcase == "boston"
    curr_file.each do |line|
      if line[0] and line[0] != "City"
        output << make_boston_entry(line[2], line[5], line[6], line[7], line[9], line[8], line[11], line[12])
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
  output = DataFrame.new({:city_parcel=>[], :sp_binomial=>[], :transect=>[]})
  case
  when format.downcase == "minnesota"
    curr_file.each do |line|
      if line[5]
        (1..4).each do |i|
          #Transect is simply i because we want transect 1 to be transect 1, not transect 0
          if line[i] then output << {:city_parcel=>[[state, parcel].join("_")], :sp_binomial=>[line[0]], :transect=>[i.to_i]} end
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
    return DataFrame.new({:city_parcel=>[[state, parcel].join("_")], :sp_binomial=>[sp_binomial], :sp_common=>[sp_common], :location=>[location]})
  end
  
  output = DataFrame.new({:city_parcel=>[], :sp_binomial=>[], :sp_common=>[], :location=>[]})
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
      temp = read_iTree("test_files/iTree.csv")
      assert temp.data == {:city_parcel=>["MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie"], :tree_no=>["1", "2", "1", "2", "3"], :sp_common=>["Eastern white pine", "Boxelder", "Eastern red cedar", "Boxelder", "Boxelder"], :dbh=>["7.5", "4.8", "19", "29.2", "29.8"], :height=>["12", "8", "8.5", "19.5", "17.5"], :ground_area=>["6.6", "8.6", "21.2", "75.4", "51.5"], :condition=>["Poor", "Fair", "Poor", "Good", "Fair"], :leaf_area=>["8.33", "14.64", "84.66", "373.98", "160.12"], :leaf_biomass=>["0.54", "1.34", "23.52", "34.21", "14.65"], :leaf_area_index=>["1.26", "1.71", "3.99", "4.96", "3.11"], :carbon_storage=>["3.4", "3.73", "42.72", "210.98", "214.2"], :gross_carbon_seq=>["0.5", "1.06", "1.81", "9.6", "9.62"], :money_value=>["84", "57", "210", "745", "662"], :street=>["NO", "NO", "NO", "NO", "NO"], :native=>["YES", "YES", "YES", "YES", "YES"]}
      assert temp.ncol == 15
      assert temp.nrow == 5
      assert temp.col_names==[:city_parcel, :tree_no, :sp_common, :dbh, :height, :ground_area, :condition, :leaf_area, :leaf_biomass, :leaf_area_index, :carbon_storage, :gross_carbon_seq, :money_value, :street, :native]
    end
  end
  
  #Vegetation Survey tests
  describe proc {read_veg_survey} do
    it "Loads Baltimore data correctly" do
      temp = read_veg_survey("test_files/baltimore.xlsx", "baltimore")
      assert temp.data == {:city_parcel=>["BA_250", "BA_250", "BA_250"], :sp_common=>["chives", "lesser periwinkle", "chinese holly"], :sp_binomial=>["Allium schoenoprasum", "Vinca minor", "Ilex cornuta"], :sp_native=>["", "", ""], :location=>["perennialGarden", "frontLawn", "perennialGarden"], :cultivation=>["C-1 F", "C-1", "C-1 B"], :notes=>["Europe/Asia/North America", "Europe", "Asia"]}
      assert temp.nrow == 3
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Balitmore corrections data" do
      #Note: setting verbose to false, which also requires explicitly setting the name to nil
      temp = read_veg_survey("test_files/baltimore_corrections.xlsx", "baltimore corrections", nil, false)
      assert temp.data == {:city_parcel=>["BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_603", "BA_603", "BA_603"], :sp_common=>["", "", "", "", "", "", "", ""], :sp_binomial=>["Solidago gigantea", "", "", "", "", "Leersia", "Festuca", "Danthonia spicata"], :sp_native=>["", "", "", "", "", "", "", ""], :location=>["", "", "", "", "", "", "", ""], :cultivation=>["", "", "", "", "", "", "", ""], :notes=>["", "fern pinnae", "1/2 fern frond", "woody seedling", "woody", "Hanover, MD", "", ""]}
      assert temp.nrow == 8
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Minnesota urban data correctly" do
      temp = read_veg_survey("test_files/minnesota_urban.xls", "minnesota")
      assert temp.data == {:city_parcel=>["MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7"], :sp_common=>["Norway Maple", "Sugar Maple", "Goutweed", "Colonial Bentgrass", "Colonial Bentgrass", "Hollyhock", "Redroot Pigweed", "Redroot Pigweed"], :sp_binomial=>["Acer platanoides", "Acer saccharum", "Aegopodium podagraria", "Agrostis tenuis", "Agrostis tenuis", "Alcea rosea", "Amaranthus retroflexus", "Amaranthus retroflexus"], :sp_native=>["", "", "", "", "", "", "", ""], :location=>["frontLawn", "perennialGarden", "perennialGarden", "frontLawn", "backLawn", "perennialGarden", "frontLawn", "perennialGarden"], :cultivation=>["S5", "C1;S5", "C1", "S4", "S4", "C1", "S5", "S5"], :notes=>["", "", "", "", "", "", "", ""]}
      assert temp.nrow == 8
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Miami urban data correctly" do
      temp = read_veg_survey("test_files/miami.xlsx", "miami")
      assert temp.data == {:city_parcel=>["FL_827", "FL_827", "FL_827", "FL_827", "FL_827", "FL_827", "FL_827"], :sp_common=>["", "", "", "", "", "", ""], :sp_binomial=>["Bidens_alba", "Bidens_alba", "Youngia_japonica", "Youngia_japonica", "Phyla_nodiflora", "Stenotaphrum_secundatum", "Stenotaphrum_secundatum"], :sp_native=>[true, true, true, true, true, true, true], :location=>["frontLawn", "backLawn", "frontLawn", "backLawn", "frontLawn", "frontLawn", "backLawn"], :cultivation=>["S-5", "S-5", "S-5", "S-5", "S-5", "S-5", "S-5"], :notes=>["", "", "", "", "", "", ""]}
      assert temp.nrow == 7
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Boston urban data correctly" do
      temp = read_veg_survey("test_files/boston_veg.csv", "boston")
      assert temp.data == {:city_parcel=>["BOS_314", "BOS_5740", "BOS_11129"], :sp_common=>["", "", ""], :sp_binomial=>["(Betulaceae)", "(Cyperaceae)", "(Nymphaeaceae)"], :sp_native=>["U", "U", nil], :location=>["frontCultivated", "backLawn", "backCultivated"], :cultivation=>["5", "5", "1"], :notes=>["seedling - chestnut?", "carex?", nil]}
      assert temp.nrow == 3
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
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
      assert temp.data == {:city_parcel=>["MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix", "MN_StCroix"], :sp_binomial=>["Acer negundo", "Achillea millefolium", "Ageratina altissima", "Amaranthus retroflexus", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Ambrosia coronopifolia", "Amorpha canescens", "Amorpha canescens", "Amorpha canescens", "Amorpha canescens", "Amphicarpaea bracteata", "Amphicarpaea bracteata", "Amphicarpaea bracteata", "Amphicarpaea bracteata"], :transect=>[1, 1, 1, 1, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]}
      assert temp.nrow == 16
      assert temp.ncol == 3
      assert temp.col_names == [:city_parcel, :sp_binomial, :transect]
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
      assert temp.data == {:city_parcel=>["MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7"], :sp_binomial=>["Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Amaranthus retroflexus", "Amaranthus retroflexus", "Chrysanthemum spp.", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra"], :sp_common=>["Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Redroot Pigweed", "Redroot Pigweed", "Chrysanthemum", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue"], :location=>["F1", "F2", "B1", "B2", "B3", "F2", "F3", "B2", "F1", "F2", "F3", "B1", "B2", "B3"]}
      assert temp.nrow == 14
      assert temp.ncol == 4
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location]
    end
    it "Doesn't care about case in file format" do
      assert read_lawn_survey("test_files/minnesota_lawn.xls", "minnesota") == read_lawn_survey("test_files/minnesota_lawn.xls", "mInNeSoTa")
    end
    it "Raises an error if it doesn't know what you've given it" do
      assert_raises(RuntimeError) {read_lawn_survey("test_files/minnesota_lawn.xls", "asdfghjgtre")}
    end
  end
end

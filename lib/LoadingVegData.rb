# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  3/1/2013

require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

#Load iTree data
def read_iTree(file_name, format="default")
  output = DataFrame.new({:city_parcel=>[],:tree_no=>[],:sp_binomial=>[],:sp_common=>[],:dbh=>[],:height=>[],:ground_area=>[],:condition=>[],:leaf_area=>[],:leaf_biomass=>[],:leaf_area_index=>[],:carbon_storage=>[],:gross_carbon_seq=>[],:money_value=>[],:street=>[],:native=>[],:parcel_area=>[],:impervious_parcel_area=>[]})
  curr_file = UniSheet.new file_name
  case
  when format.downcase == "default"
    curr_file.each do |line|
      if line[0] and line[0] != "City ID" and line[0] != "ID Code" and line[0] != "Date" and line[0] != "City_Parcel" and line[0] != "CityID"
        output << {:city_parcel=>[[line[0], line[1]].join("_")],:tree_no=>[line[5]],:sp_binomial=>[""],:sp_common=>[line[6]],:dbh=>[line[7]],:height=>[line[8]],:ground_area=>[line[9]],:condition=>[line[10]],:leaf_area=>[line[11]],:leaf_biomass=>[line[12]],:leaf_area_index=>[line[13]],:carbon_storage=>[line[14]],:gross_carbon_seq=>[line[15]],:money_value=>[line[16]],:street=>[line[17]],:native=>[line[18]],:parcel_area=>[line[3]],:impervious_parcel_area=>[line[4]]}
      end
    end    
  when format.downcase == "saltlake"
    curr_file.set_sheet 3
    curr_file.each do |line|
      if line[0] and line[0] != "ID Code" and line[0] != "City_Parcel"
        (5..16).each do |i|
          unless line[i]==0 then output << {:city_parcel=>[["SL", line[0]].join("_")],:tree_no=>[""],:sp_binomial=>[""],:sp_common=>[line[2]],:dbh=>[line[i]],:height=>["4"],:ground_area=>[""],:condition=>[""],:leaf_area=>[""],:leaf_biomass=>[""],:leaf_area_index=>[""],:carbon_storage=>[""],:gross_carbon_seq=>[""],:money_value=>[""],:street=>[""],:native=>[""],:parcel_area=>[""],:impervious_parcel_area=>[""]} end
        end
      end
    end
  when format.downcase == "la"
    curr_file.each do |line|
      if line[0] and line[0] != "City ID" and line[0] != "City_Parcel"
        output << {:city_parcel=>[[line[0], line[1]].join("_")],:tree_no=>[line[3]],:sp_binomial=>[line[4]],:sp_common=>[""],:dbh=>[line[5]],:height=>[line[6]],:ground_area=>[line[7]],:condition=>[line[8]],:leaf_area=>[line[9]],:leaf_biomass=>[line[10]],:leaf_area_index=>[line[11]],:carbon_storage=>[line[12]],:gross_carbon_seq=>[line[13]],:money_value=>[line[14]],:street=>[line[15]],:native=>[line[16]],:parcel_area=>[""],:impervious_parcel_area=>[""]}
      end
    end
  when
    format.downcase == "phoenix"
    curr_file.each do |line|
      if line[0] and line[0] != "Date" and line[0] != "City_Parcel"
        (7..12).each do |i|
          unless line[i]=="" or line[i]==nil then output << {:city_parcel=>[["PX", line[1]].join("_")],:tree_no=>[""],:sp_binomial=>[line[3]],:sp_common=>[line[2]],:dbh=>[line[i]],:height=>[line[13]],:ground_area=>[""],:condition=>[""],:leaf_area=>[""],:leaf_biomass=>[""],:leaf_area_index=>[""],:carbon_storage=>[""],:gross_carbon_seq=>[""],:money_value=>[""],:street=>[""],:native=>[""],:parcel_area=>[""],:impervious_parcel_area=>[""]} end
        end
      end
    end
  else
    raise RuntimeError, "Unknown file format #{format} for file #{file_name}"
  end
  return output
end

#Vegetation surveys
# - Miami data distinguish between front and back 'PG'
def read_veg_survey(file_name, format, name=nil, verbose=true)
  #Helper function to write entries
  def make_entry(state, parcel, sp_common='', sp_binomial='', location_index='', cultivation='', notes='', sp_native='', abundance=perenial_garden_split=false)
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
      if location_code
        location_code.split(",").each do |code|
          if code == "l" or code.include? 'l-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontLawn"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code == "c" or code.include? 'c-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontCultivated"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code.downcase == "v" or code.include? 'v-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontVegetable"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code.downcase == "o" or code.include? 'o-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontUnmanaged"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code.downcase == "w" or code.include? 'w-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontWoodlot"],:cultivation=>[cultivation],:notes=>[notes]} end
        end
      else
        entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["frontUnknown"],:cultivation=>[cultivation],:notes=>[notes]}
      end
    end
    if back and back.downcase=="y"
      if location_code
        location_code.split(",").each do |code|
          if code == "l" or code.include? 'l-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backLawn"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code == "c" or code.include? 'c-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backCultivated"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code.downcase == "v" or code.include? 'v-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backVegetable"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code.downcase == "o" or code.include? 'o-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backUnmanaged"],:cultivation=>[cultivation],:notes=>[notes]} end
          if code.downcase == "w" or code.include? 'w-' then entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backWoodlot"],:cultivation=>[cultivation],:notes=>[notes]} end
        end
      else
        entries << {:city_parcel=>["BOS_"+parcel.to_s],:sp_common=>[''],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>["backUnknown"],:cultivation=>[cultivation],:notes=>[notes]}
      end
    end
    return entries
  end
  #Yet another wrapper for Phoenix data 
  def make_phoenix_entry(parcel, sp_common, sp_binomial, location, cultivation, sp_native, date)
    location_lookup = {"Annual Planting"=>"annualPlant", "Annual Plantings"=>"annualPlant", "back lawn"=>"backLawn", "Back Lawn"=>"backLawn", "Back Perennial Garden"=>"perennialGardenBack", "front lawn"=>"frontLawn", "Front Lawn"=>"frontLawn", "Front Perennial Garden"=>"perennialGardenFront", "nothing"=>"reference", "perennial garden"=>"perennialGarden", "POTTED"=>"pot", "T1"=>"reference", "T2"=>"reference", "T3"=>"reference", "T4"=>"reference", "T5"=>"reference", "T6"=>"reference", "T7"=>"reference", "T8"=>"reference", "Unmanaged"=>"unmanaged", "Vegetable Garden"=>"vegetableGarden", "Xeriscape"=>"xeriscape"}
    begin
      location = location_lookup[location]
    rescue
      raise RuntimeError, "Bad location entry #{location} in Phoenix site #{parcel}"
    end
    city_parcel = "AZ_#{parcel}"
    return DataFrame.new({:city_parcel=>[city_parcel],:sp_common=>[sp_common],:sp_binomial=>[sp_binomial],:sp_native=>[sp_native],:location=>[location],:cultivation=>[cultivation], :notes=>["Date:#{date}"]})
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
    
  when format.downcase == "phoenix"
    curr_file.set_sheet 1
    curr_file.each do |line|
      if line[0] and line[0] != "Case ID"
        output << make_phoenix_entry(line[0], line[2], line[3], line[6], line[7], line[5], line[1])
        if line[0] == "" then puts file end
      end
    end
    
  when format.downcase == "saltlake"
    curr_file.set_sheet 1
    curr_file.each do |line|
      if line[0] and line[0] != "ID Code"
        (5..9).each do |i|
          if line[i] then output << make_entry("SL", line[0], line[3], line[4], i-5, line[i]) end
        end
      end
    end

  when format.downcase == "la"
    0.upto(curr_file.n_sheets() -1) do |sheet|
      curr_file.set_sheet sheet
      curr_file.each do |line|
        if line[1] and line[0]!="Date"
          (6..10).each do |i|
            if line[i] then output << make_entry("LA", line[1], line[2], [line[3],line[4]].join("_"), i-6, line[i]) end
          end
        end
      end
    end
  else
    raise RuntimeError, "Unknown file format #{format} for file #{file_name}"
  end
  return output
end
    
#Transect surveys (of non-urban areas)
def read_veg_transect(file_name, format, state, parcel="ERROR")
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
  when format.downcase == "saltlake"
    curr_file.each do |line|
      if line[0] and line[0] != "Site"
        (5..12).each do |i|
          #Note I'm still trying to keep transect 0 transect 1 in the database...
          if line[i]!="0" then output << {:city_parcel=>[[state, line[0]].join("_")], :sp_binomial=>[[line[3], line[4]].join("+")], :transect=>[(i-4).to_i]} end
        end
      end
    end
  when format.downcase == "la"
    0.upto(curr_file.n_sheets() -1) do |sheet|
      curr_file.set_sheet sheet
      curr_file.each do |line|
        if line[1] and line[0]!="Common Name"
          (4..10).each do |i|
            if line[i] then output << {:city_parcel=>[[state,["CSS",(sheet+1).to_s].join("")].join("_")], :sp_binomial=>[[line[1],line[2]].join("_")], :transect=>[i-3]} end
          end
        end
      end
    end
  when format.downcase == "miami"
    curr_file.each do |line|
      if line[0] and line[0]!="ID"
        (5..12).each do |i|
          if line[i] and (line[i].downcase=="yes" or line[i].downcase=="y") then output << {:city_parcel=>[[state,line[1]].join("_")], :sp_binomial=>[line[2..4].join("_")], :transect=>[i-4]}
          end
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
  if format.downcase == "saltlake" then curr_file.set_sheet 2 end
  #Helper function - assumes particular ordering of front and back lawns
  def make_entry(state, parcel, sp_binomial, sp_common, location_index, abundance, reference=false, transect="")
    begin
      if reference
        location = location_index
      else
        location = ["F1", "F2", "F3", "B1", "B2", "B3"][location_index]
      end
    rescue Exception => e
      raise RuntimeError, "Bad columns in #{state} - #{parcel}"
    end
    if abundance.is_a? Float or abundance.is_a? Fixnum
      abundance = abundance.to_i
    else
      abundance = -1
    end
    return DataFrame.new({:city_parcel=>[[state, parcel].join("_")], :sp_binomial=>[sp_binomial], :sp_common=>[sp_common], :location=>[location], :abundance=>[abundance], :transect=>[transect]})
  end
  
  output = DataFrame.new({:city_parcel=>[], :sp_binomial=>[], :sp_common=>[], :location=>[], :abundance=>[], :transect=>[]})
  case
  when (format.downcase == "minnesota" or format.downcase == "saltlake")
    if format.downcase == "saltlake"
      curr_file.set_sheet 2
    end
    curr_file.each do |line|
      if line[0] and line[0]!= "Site" 
        (4..9).each do |i|
          if line[i] then output << make_entry("MN", line[0].to_i, line[3], line[2], i-4, line[i]) end
        end
      end
    end
  when format.downcase == "baltimore"
    curr_file.each do |line|
      if line[0] and line[1] and line[0] != "Common name" and line[0] != "Scientific Name"
        (2..7).each do |i|
          if line[i] then output << make_entry("BA", curr_file[1][3], line[1], line[0], i-2, line[i]) end
          end
        end
    end
  when format.downcase == "baltimore reference"
    curr_file.set_sheet 1
    curr_file.each do |line|
      if line[0] and line[0]!="References Site" and line[0]!="City" and line[0]!="Cover categories:" and line[0]!="R (rare, 1 individual), 1(<1%), 2 (1-2%), 3 (3-5%), 4 (6-15%), 5 (16-25%), 6 (26-50%), 7 (51-75%), 8 (76-100%)" and line[0]!="Genus Spp (Scientific Name)"
        (2..32).each do |i|
          if (0..32).step(3) === i then break end
          if line[i] then output << make_entry("BA", curr_file[0][1], line[0], "", (((i-2)%3)+1).to_s, line[i], true, ((i-2)/3+1).to_s) end
        end
      end
    end
  when format.downcase == "boston"
    #Urban sites
    curr_file.each do |line|
      if line[0] and line[0] != "City"
        if line[3] == "B" then t = 2 else t = -1 end
        output << make_entry("BOS", line[2], line[5], "", line[4].to_i+t, line[6])
      end
    end
  when format.downcase == "miami"
    #Urban
    curr_file.each do |line|
      if line[1] and line[1] != "Case ID"
        (4..9).each do |i|
          if line[i] then output << make_entry("FL", line[1], line[3], "", i-4, line[i]) end
        end
      end
    end
    #Reference
    curr_file.set_sheet 1
    curr_file.each do |line|
      if line[1] and line[1]!="Case ID"
        (4..15).each do |i|
          if line[i] then output << make_entry("FL", line[1], line[3], "", -1, line[i], true, curr_file[2][i]) end
        end
      end
    end
  when format.downcase == "phoenix"
    #Urban sites
    curr_file.set_sheet 1
    curr_file.each do |line|
      if line[0] and line[0] != "Date" and line[0]!=nil
        output << make_entry("PHX", line[1].to_s, line[3], line[2], line[4], line[5], true)
        if line[1] == "" then puts file end
      end
    end
    #Reference sites
    curr_file.set_sheet 2
    curr_file.each do |line|
      if line[0] and line[0] != "Date" and line[0]!=nil
        output << make_entry("PHX", line[1], line[3], line[2], line[5], line[6], true, line[4])
      end
    end
    #Agricultural sites
    curr_file.set_sheet 3
    curr_file.each do |line|
      if line[0] and line[0] != "Date" and line[0]!=nil
        output << make_entry("PHX", line[1], line[3], line[2], line[5], line[6], true, line[4])
      end
    end
  when format.downcase == "la"
    curr_file.each do |line|
      if line[1] and line[1]!="Site"
        (5..10).each do |i|
          if line[i] then output << make_entry("LA", line[1], line[3..4].join("_"), line[2], i-5, line[i]) end
        end
      end
    end
  when format.downcase == "la rural"
    offsets = [0, 9, 18]
    site = 1
    curr_transect = "ERROR"
    offsets.each do |offset|
      curr_file.each do |line|
        if line[2+offset] == "Location" then curr_transect = line[1+offset].to_s end
        if line[offset+3] and line[offset+3]!="Genus"
          (5..7).each do |i|
            if line[offset+i]
              output << make_entry("LA", site, line[(3+offset)..(4+offset)].join("_"), line[2+offset], i-5, line[i+offset], false, curr_transect)
            end
          end
        end
      end
      site = site + 1
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
    it "loads standard iTree data correctly" do
      temp = read_iTree("test_files/iTree.csv")
      assert temp.data == {:city_parcel=>["MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie", "MSP_Lost Valley Prairie"], :tree_no=>["1", "2", "1", "2", "3"], :sp_binomial=>["", "", "", "", ""], :sp_common=>["Eastern white pine", "Boxelder", "Eastern red cedar", "Boxelder", "Boxelder"], :dbh=>["7.5", "4.8", "19", "29.2", "29.8"], :height=>["12", "8", "8.5", "19.5", "17.5"], :ground_area=>["6.6", "8.6", "21.2", "75.4", "51.5"], :condition=>["Poor", "Fair", "Poor", "Good", "Fair"], :leaf_area=>["8.33", "14.64", "84.66", "373.98", "160.12"], :leaf_biomass=>["0.54", "1.34", "23.52", "34.21", "14.65"], :leaf_area_index=>["1.26", "1.71", "3.99", "4.96", "3.11"], :carbon_storage=>["3.4", "3.73", "42.72", "210.98", "214.2"], :gross_carbon_seq=>["0.5", "1.06", "1.81", "9.6", "9.62"], :money_value=>["84", "57", "210", "745", "662"], :street=>["NO", "NO", "NO", "NO", "NO"], :native=>["YES", "YES", "YES", "YES", "YES"], :parcel_area=>["0.02", "0.02", "0.02", "0.02", "0.02"], :impervious_parcel_area=>["0", "0", "0", "0", "0"]}
      assert temp.ncol == 18
      assert temp.nrow == 5
      assert temp.col_names==[:city_parcel, :tree_no, :sp_binomial, :sp_common, :dbh, :height, :ground_area, :condition, :leaf_area, :leaf_biomass, :leaf_area_index, :carbon_storage, :gross_carbon_seq, :money_value, :street, :native, :parcel_area, :impervious_parcel_area]
    end
    it "loads LA iTree data correctly" do
      temp = read_iTree("test_files/la_iTree.csv", "la")
      assert temp.data ==  {:city_parcel=>["LA_10317", "LA_3303"], :tree_no=>["1", "1"], :sp_binomial=>["Cercis canadensis", "Pinus edulis"], :sp_common=>["", ""], :dbh=>["8.5", "18.8"], :height=>["6.6", "3.3"], :ground_area=>["19.6", "3.1"], :condition=>["Excellent", "Excellent"], :leaf_area=>["61.9", "11.58"], :leaf_biomass=>["3.96", "1.12"], :leaf_area_index=>["3.15", "3.69"], :carbon_storage=>["8.92", "21.85"], :gross_carbon_seq=>["6.49", "5.43"], :money_value=>["477", "1773"], :street=>["NO", "NO"], :native=>["NO", "NO"], :parcel_area=>["", ""], :impervious_parcel_area=>["", ""]}
      assert temp.ncol == 18
      assert temp.nrow == 2
      assert temp.col_names == [:city_parcel, :tree_no, :sp_binomial, :sp_common, :dbh, :height, :ground_area, :condition, :leaf_area, :leaf_biomass, :leaf_area_index, :carbon_storage, :gross_carbon_seq, :money_value, :street, :native, :parcel_area, :impervious_parcel_area]
    end
    it "loads Phoenix iTree data correctly" do
      temp = read_iTree("test_files/phx_iTree.csv", "phoenix")
      assert temp.data ==  {:city_parcel=>["PX_11668", "PX_11668", "PX_11668", "PX_11668", "PX_15263", "PX_15263", "PX_15263", "PX_15263", "PX_15263", "PX_15263"], :tree_no=>["", "", "", "", "", "", "", "", "", ""], :sp_binomial=>["Prosopis glandulosa hybrid", "Prosopis glandulosa hybrid", "Prosopis glandulosa hybrid", "Prosopis glandulosa hybrid", "Parkinsonia praecox", "Parkinsonia praecox", "Parkinsonia praecox", "Parkinsonia praecox", "Parkinsonia praecox", "Parkinsonia praecox"], :sp_common=>["Honey mesquite hybrid", "Honey mesquite hybrid", "Honey mesquite hybrid", "Honey mesquite hybrid", "Sonoran palo verde", "Sonoran palo verde", "Sonoran palo verde", "Sonoran palo verde", "Sonoran palo verde", "Sonoran palo verde"], :dbh=>["13.1", "5.5", "7.2", "5.2", "3.8", "4.4", "2.6", "3", "2.2", "4.1"], :height=>["5.35", "5.35", "5.35", "5.35", "4.6", "4.6", "4.6", "4.6", "4.6", "4.6"], :ground_area=>["", "", "", "", "", "", "", "", "", ""], :condition=>["", "", "", "", "", "", "", "", "", ""], :leaf_area=>["", "", "", "", "", "", "", "", "", ""], :leaf_biomass=>["", "", "", "", "", "", "", "", "", ""], :leaf_area_index=>["", "", "", "", "", "", "", "", "", ""], :carbon_storage=>["", "", "", "", "", "", "", "", "", ""], :gross_carbon_seq=>["", "", "", "", "", "", "", "", "", ""], :money_value=>["", "", "", "", "", "", "", "", "", ""], :street=>["", "", "", "", "", "", "", "", "", ""], :native=>["", "", "", "", "", "", "", "", "", ""], :parcel_area=>["", "", "", "", "", "", "", "", "", ""], :impervious_parcel_area=>["", "", "", "", "", "", "", "", "", ""]}
      assert temp.ncol == 18
      assert temp.nrow == 10
      assert temp.col_names == [:city_parcel, :tree_no, :sp_binomial, :sp_common, :dbh, :height, :ground_area, :condition, :leaf_area, :leaf_biomass, :leaf_area_index, :carbon_storage, :gross_carbon_seq, :money_value, :street, :native, :parcel_area, :impervious_parcel_area]
    end
    it "Handles file types correctly" do
      assert_raises(RuntimeError) {read_iTree("test_files/la_iTree.csv", "nonsense")}
      assert read_iTree("test_files/iTree.csv") == read_iTree("test_files/iTree.csv", "default")
      assert read_iTree("test_files/iTree.csv", "DeFaUlT") == read_iTree("test_files/iTree.csv", "default")
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
      temp = read_veg_survey("test_files/boston_veg.xlsx", "boston")
      assert temp.data == {:city_parcel=>["BOS_314", "BOS_5740", "BOS_11129"], :sp_common=>["", "", ""], :sp_binomial=>["(Betulaceae)", "(Cyperaceae)", "(Nymphaeaceae)"], :sp_native=>["U", "U", nil], :location=>["frontCultivated", "backLawn", "backUnknown"], :cultivation=>[5, 5, 1], :notes=>["seedling - chestnut?", "carex?", nil]}
      assert temp.nrow == 3
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads Phoenix urban data correctly" do
      temp = read_veg_survey("test_files/phoenix.xlsx", "phoenix")
      assert temp.data == {:city_parcel=>["AZ_159", "AZ_159", "AZ_159"], :sp_common=>["Agave 'Shark Skin'", "Asparagus Fern", "Rescuegrass"], :sp_binomial=>["Agave ferdinandi-regis x scabra", "Asparagus densiflorus", "Bromus catharticus"], :sp_native=>[nil, "South Africa", "South America"], :location=>["xeriscape", "xeriscape", "frontLawn"], :cultivation=>["C-1", "C-1", "S-5"], :notes=>["Date:41363", "Date:41363", "Date:41363"]}
      assert temp.nrow == 3
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :sp_common, :sp_binomial, :sp_native, :location, :cultivation, :notes]
    end
    it "Loads LA urba data correctly" do
      temp = read_veg_survey("test_files/la_veg.xlsx", "la")
      assert temp.data == {:city_parcel=>["LA_1404", "LA_2259", "LA_2259"], :sp_common=>["Tree aeonium", "Tree aeonium", "Green pinwheel"], :sp_binomial=>["Aeonium_arboreum", "Aeonium_arboreum", "Aeonium_decorum"], :sp_native=>["", "", ""], :location=>["perennialGarden", "perennialGarden", "perennialGarden"], :cultivation=>["C-1 (pot), C-2", "S-5", "C-2"], :notes=>["", "", ""]}
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
    it "Loads LA data correctly" do
      temp = read_veg_transect("test_files/la_transect.xlsx", "la", "LA")
      assert temp.data == {:city_parcel=>["LA_CSS1", "LA_CSS1", "LA_CSS2", "LA_CSS3", "LA_CSS3"], :sp_binomial=>["Ambrosia_artemisiifolia", "Ambrosia_artemisiifolia", "Agrostis_pallens", "Amsinckia_menziesii", "Amsinckia_menziesii"], :transect=>[2, 5, 1, 3, 4]}
      assert temp.nrow == 5
      assert temp.ncol == 3
      assert temp.col_names == [:city_parcel, :sp_binomial, :transect]
    end
    it "Loads Miami data correctly" do
      temp = read_veg_transect("test_files/miami_transect.xlsx", "miami", "FL")
      assert temp.data == {:city_parcel=>["FL_Okeeheelee", "FL_Okeeheelee", "FL_Okeeheelee", "FL_Okeeheelee"], :sp_binomial=>["Quercus_laurifolia_", "Quercus_laurifolia_", "Quercus_laurifolia_", "Quercus_laurifolia_"], :transect=>[1, 2, 4, 8]}
      assert temp.nrow == 4
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
      assert temp.data == {:city_parcel=>["MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7", "MN_7"], :sp_binomial=>["Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Agrostis tenuis", "Amaranthus retroflexus", "Amaranthus retroflexus", "Chrysanthemum spp.", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra", "Festuca rubra"], :sp_common=>["Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Colonial Bentgrass", "Redroot Pigweed", "Redroot Pigweed", "Chrysanthemum", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue", "Creeping Red Fescue"], :location=>["F1", "F2", "B1", "B2", "B3", "F2", "F3", "B2", "F1", "F2", "F3", "B1", "B2", "B3"], :abundance=>[4, 5, 2, 2, 4, -1, 1, 2, 7, 7, 7, 8, 8, 8], :transect=>["", "", "", "", "", "", "", "", "", "", "", "", "", ""]}
      assert temp.nrow == 14
      assert temp.ncol == 6
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Loads Baltimore data correctly" do
      temp = read_lawn_survey("test_files/baltimore_lawn.xlsx", "baltimore")
      assert temp.data == {:city_parcel=>["BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250", "BA_250"], :sp_binomial=>["Festuca capillata", "Festuca capillata", "Festuca capillata", "Festuca capillata", "Festuca arundinacea", "Festuca arundinacea", "Festuca arundinacea", "Festuca arundinacea", "Festuca arundinacea", "Festuca arundinacea", "Poa pratensis", "Poa pratensis", "Poa pratensis", "Poa pratensis", "Poa pratensis", "Poa pratensis"], :sp_common=>["hair fescue", "hair fescue", "hair fescue", "hair fescue", "tall fescue", "tall fescue", "tall fescue", "tall fescue", "tall fescue", "tall fescue", "Kentucky bluegrass", "Kentucky bluegrass", "Kentucky bluegrass", "Kentucky bluegrass", "Kentucky bluegrass", "Kentucky bluegrass"], :location=>["F1", "F2", "F3", "B3", "F1", "F2", "F3", "B1", "B2", "B3", "F1", "F2", "F3", "B1", "B2", "B3"], :abundance=>[8, 5, 8, 4, 5, 4, 5, 7, 6, 3, 4, 8, 5, 6, 4, 5], :transect=>["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]}
      assert temp.ncol == 6
      assert temp.nrow == 16
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Loads Baltimore reference data correctly" do
      temp = read_lawn_survey("test_files/baltimore_lawn_ref.xlsx", "baltimore reference")
      assert temp.data == {:city_parcel=>["BA_Leakin", "BA_Leakin", "BA_Leakin", "BA_Leakin", "BA_Leakin"], :sp_binomial=>["Fagus grandefolia", "Fagus grandefolia", "Fagus grandefolia", "UNKN seedling 434", "UNKN grass 435"], :sp_common=>["", "", "", "", ""], :location=>["2", "1", "3", "2", "2"], :abundance=>[-1, 4, -1, -1, 2],  :transect=>["1","8","10","1","1"]}
      assert temp.ncol == 6
      assert temp.nrow == 5
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Loads Boston data correctly" do
      temp = read_lawn_survey("test_files/boston_lawn.xlsx", "boston")
      assert temp.data == {:city_parcel=>["BOS_7882"], :sp_binomial=>["Ajuga reptans"], :sp_common=>[""], :location=>["B1"], :abundance=>[3], :transect=>[""]}
      assert temp.ncol == 6
      assert temp.nrow == 1
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Loads Phoenix data correctly" do
      temp = read_lawn_survey("test_files/phx_lawn.xlsx", "phoenix")
      assert temp.data == {:city_parcel=>["PHX_11668", "PHX_3482", "PHX_Estrella", "PHX_AG 2", "PHX_AG 3"], :sp_binomial=>["Pectocarya platycarpa", "Cynadon dactylon", "Lesquerella gordonii", "Amaranthus sp.", "Parthenium argentatum"], :sp_common=>["Broadfruit Combseed", "Bermuda Grass", "Bladderpod", nil, "Guayule"], :location=>["F2", "F1", 1, 1, 1], :abundance=>[3, 6, 4, 1, 5], :transect=>["", "", "T1", "T3", "T1"]}
      assert temp.ncol == 6
      assert temp.nrow == 5
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Loads LA urban data correctly" do
      temp = read_lawn_survey("test_files/la_lawn.xlsx", "la")
      assert temp.data == {:city_parcel=>["LA_10317", "LA_10317", "LA_10317", "LA_10317", "LA_3303", "LA_3303", "LA_3303", "LA_3303", "LA_3303", "LA_3303"], :sp_binomial=>["Digitaria_ischaemum", "Festuca_arundinacea", "Festuca_arundinacea", "Festuca_arundinacea", "Festuca_arundinacea", "Festuca_arundinacea", "Festuca_arundinacea", "Festuca_arundinacea", "Festuca_arundinacea", "Festuca_arundinacea"], :sp_common=>["Smooth crabgrass", "Tall fescue", "Tall fescue", "Tall fescue", "Tall fescue", "Tall fescue", "Tall fescue", "Tall fescue", "Tall fescue", "Tall fescue"], :location=>["B2", "B1", "B2", "B3", "F1", "F2", "F3", "B1", "B2", "B3"], :abundance=>[3, 8, 8, 8, 8, 8, 8, 8, 8, 8], :transect=>["","","","","","","","","",""]}
      assert temp.nrow == 10
      assert temp.ncol == 6
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Loads LA rural data correctly" do
      temp = read_lawn_survey("test_files/la_lawn_rural.xlsx", "la rural")
      assert temp.data == {:city_parcel=>["LA_1", "LA_1", "LA_1", "LA_1", "LA_1", "LA_2", "LA_3", "LA_3", "LA_3"], :sp_binomial=>["Bromus_hordeaceus", "Bromus_hordeaceus", "Bromus_madritensis", "Bromus_madritensis", "Bromus_madritensis", "Avena_barbata", "Avena_barbata", "Avena_barbata", "Avena_barbata"], :sp_common=>["Soft brome", "Soft brome", "Compact brome", "Compact brome", "Compact brome", "Slender wild oat", "Slender wild oat", "Slender wild oat", "Slender wild oat"], :location=>["F1", "F2", "F1", "F2", "F3", "F1", "F1", "F2", "F3"], :abundance=>[2, 2, 3, 5, 4, 6, 4, 5, 5], :transect=>["8", "8", "8", "8", "8", "3219", "13353", "13353", "13353"]}
      assert temp.nrow == 9
      assert temp.ncol == 6
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Loads Miami data correctly" do
      temp = read_lawn_survey("test_files/miami_abundance.xlsx", "miami")
      assert temp.data == {:city_parcel=>["FL_5296", "FL_5296", "FL_5296", "FL_5296", "FL_5296", "FL_Okeeheelee", "FL_Okeeheelee"], :sp_binomial=>["Bidens alba", "Bidens alba", "Bidens alba", "Bidens alba", "Bidens alba", "Dichanthelium commutatum", "Dichanthelium commutatum"], :sp_common=>["", "", "", "", "", "", ""], :location=>["F1", "F2", "F3", "B1", "B3", -1, -1], :abundance=>[4, 6, 4, 3, 2, 6, 1], :transect=>["", "", "", "", "", "T-5-1", "T-7-2"]}
      assert temp.nrow == 7
      assert temp.ncol == 6
      assert temp.col_names == [:city_parcel, :sp_binomial, :sp_common, :location, :abundance, :transect]
    end
    it "Doesn't care about case in file format" do
      assert read_lawn_survey("test_files/minnesota_lawn.xls", "minnesota") == read_lawn_survey("test_files/minnesota_lawn.xls", "mInNeSoTa")
    end
    it "Raises an error if it doesn't know what you've given it" do
      assert_raises(RuntimeError) {read_lawn_survey("test_files/minnesota_lawn.xls", "asdfghjgtre")}
    end
  end
end

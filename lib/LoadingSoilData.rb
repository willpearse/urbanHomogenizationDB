# -*- coding: utf-8 -*-
require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

def read_soil_microclimate(file_name, city, split)
  output = DataFrame.new({:date=>[],:city_parcel=>[],:moisture=>[],:temperature=>[]})
  curr_file = UniSheet.new file_name
  city_parcel = city + "_" + file_name.split(/\/|\\/)[-1].split("_")[split]
  curr_file.each do |line|
    if line[1] and line[1]!="Port 1" and line[1]!="5TM Moisture/Temp" and line[1]!="m³/m³ VWC"
      output << {:date=>[line[0].to_s],:city_parcel=>[city_parcel],:moisture=>[line[1]],:temperature=>[line[2]]}
    end
  end
  return output
end

def read_soil_baseline(file_name)
  output = DataFrame.new({:date=>[],:core_id=>[],:city_parcel=>[],:site_no=>[],:core_no=>[],:plot_no=>[],:depth=>[],:total_L=>[],:notes=>[],:core_sections=>[],:section_length=>[],:volume=>[],:tot_sub_rock_vol=>[],:wet_weight=>[],:dry_weight=>[],:dry_weight_sub_rock_weight=>[],:density=>[],:root_mass=>[],:rock_mass=>[],:rock_vol=>[],:microb_biomass=>[],:respiration=>[],:NO2_over_NO3=>[],:NH4=>[],:bio_N=>[],:mineral=>[],:nitrogen=>[],:moisture=>[],:DEA=>[],:percent_sand=>[],:pH=>[]})
 curr_file = UniSheet.new file_name
  curr_file.each do |line|
    if line[0] and line[0] != "Sample ID"
      sand = ""
      notes = ""
      if line[14] != "." then notes = line[14] end
      if line[35] != "." then sand = line[35] end
      output << {:date=>[line[8]],:core_id=>[line[7]],:city_parcel=>[line[1]+"_"+line[2].to_s],:site_no=>[line[9]],:core_no=>[line[10]],:plot_no=>[line[11]],:depth=>[line[12]],:total_L=>[line[13]],:notes=>[notes],:core_sections=>[line[15]],:section_length=>[line[16]],:volume=>[line[17]], :tot_sub_rock_vol=>[line[18]], :wet_weight=>[line[19]], :dry_weight=>[line[20]], :dry_weight_sub_rock_weight=>[line[21]], :density=>[line[22]], :root_mass=>[line[23]], :rock_mass=>[line[24]], :rock_vol=>[line[25]], :microb_biomass=>[line[26]], :respiration=>[line[27]], :NO2_over_NO3=>[line[28]], :NH4=>[line[29]], :bio_N=>[line[30]], :mineral=>[line[31]], :nitrogen=>[line[32]], :moisture=>[line[33]], :DEA=>[line[34]], :percent_sand=>[sand], :pH=>[line[36]]}
    end
  end
  return output
end

if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  
  describe proc {read_soil_baseline} do
    it "loads baseline soil data correctly" do
      temp = read_soil_baseline("test_files/soil.xlsx")
      assert temp.data == {:date=>[41053, 41053], :core_id=>["1", "1"], :city_parcel=>["BAL_3187", "BAL_3187"], :site_no=>["1", "1"], :core_no=>["1", "1"], :plot_no=>["3", "3"], :depth=>["94", "94"], :total_L=>["80", "80"], :notes=>["", "that's a tasty burger"], :core_sections=>["0 - 10 cm", "10 - 30 cm"], :section_length=>[10, 20], :volume=>[73, 146], :tot_sub_rock_vol=>[71, 130], :wet_weight=>["79.92", "207.21"], :dry_weight=>[67.0226654578422, 177.21682382134], :dry_weight_sub_rock_weight=>[64.5926654578422, 144.37682382134], :density=>[0.909755851518904, 1.11059095247185], :root_mass=>[0, 0], :rock_mass=>[2.43, 32.84], :rock_vol=>[2, 16], :microb_biomass=>[590.051191534942, 263.960212211855], :respiration=>[9.99912878789777, 1.90912283986374], :NO2_over_NO3=>[20.2456216216216, 9.59553191489362], :NH4=>[2.48108108108108, 6.25163442940039], :bio_N=>[59.6408161102279, 22.1560757765389], :mineral=>[-0.00729298569157386, -0.0204786665149614], :nitrogen=>[0.137113131955485, 0.580912162930937], :moisture=>[0.161378059836809, 0.144747725392887], :DEA=>[617.917914079514, 36.9752219734004], :percent_sand=>["", 42.7674869373564], :pH=>[6.42, 6.5]}
      assert temp.nrow == 2
      assert temp.ncol == 31
      assert temp.col_names == [:date, :core_id, :city_parcel, :site_no, :core_no, :plot_no, :depth, :total_L, :notes, :core_sections, :section_length, :volume, :tot_sub_rock_vol, :wet_weight, :dry_weight, :dry_weight_sub_rock_weight, :density, :root_mass, :rock_mass, :rock_vol, :microb_biomass, :respiration, :NO2_over_NO3, :NH4, :bio_N, :mineral, :nitrogen, :moisture, :DEA, :percent_sand, :pH]
    end
  end

  describe proc {read_soil_microclimate} do
    it "loads (processed) soil microclimate data correctly" do
      temp = read_soil_microclimate("test_files/dummy_soil_11465_soil.xls", "FL", 2)
      assert temp.data == {:date=>["2013-03-28T14:30:00+00:00", "2013-03-28T15:00:00+00:00"], :city_parcel=>["FL_11465", "FL_11465"], :moisture=>[0.12013940513134003, 0.11924377828836441], :temperature=>[23.5, 23.600000381469727]}
      assert temp.nrow == 2
      assert temp.ncol == 4
      assert temp.col_names == [:date, :city_parcel, :moisture, :temperature]
      assert read_soil_microclimate("test_files/dummy_soil_11465_soil.xls", "FL", 0)[:city_parcel] == :city_parcel=>["dummy_11465", "dummy_11465"]
    end
  end
end

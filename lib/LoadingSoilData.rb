# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  4/19/2013

require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

def read_soil(file_name)
  output = DataFrame.new({:date=>[],:core_id=>[],:city=>[],:date=>[],:case_id=>[],:site_no=>[],:core_no=>[],:plot_no=>[],:depth=>[],:total_L=>[],:notes=>[],:core_sections=>[],:sample_id=>[],:weight=>[],:key_no=>[],:bio_C=>[],:resp_c=>[],:NO2_NO3=>[],:NH4=>[],:bio_N=>[],:min=>[],:nit=>[],:H20=>[],:DEA=>[],:sand_percent=>[],:pH=>[]})
  curr_file = UniSheet.new file_name
  curr_file.each do |line|
    if line[0] and line[0] != "Date"
      output << {:date=>[line[0]],:core_id=>[line[1]],:city=>[line[2]],:date=>[line[3]],:case_id=>[line[4]],:site_no=>[line[5]],:core_no=>[line[6]],:plot_no=>[line[7]],:depth=>[line[8]],:total_L=>[line[9]],:notes=>[line[10]],:core_sections=>[line[11]],:sample_id=>[line[12]],:weight=>[line[13]],:key_no=>[line[14]],:bio_C=>[line[15]],:resp_c=>[line[16]],:NO2_NO3=>[line[17]],:NH4=>[line[18]],:bio_N=>[line[19]],:min=>[line[20]],:nit=>[line[21]],:H20=>[line[22]],:DEA=>[line[23]],:sand_percent=>[line[24]],:pH=>[line[25]]}
    end
  end
  return output
end


if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  
  #iTree tests
  describe proc {read_soil} do
    it "loads soil data correctly" do
      temp = read_soil("/Users/will/Dropbox/homogenization/database/lib/test_files/soil.xlsx")
      assert temp.data == {:date=>[39731, 39731], :core_id=>[241, 241], :city=>["Miami", "Miami"], :case_id=>[11402, 11402], :site_no=>[1, 1], :core_no=>[1, 1], :plot_no=>[2, 2], :depth=>[44, 44], :total_L=>[43, 43], :notes=>[nil, nil], :core_sections=>["0 - 10 cm", "10 - 30 cm"], :sample_id=>[961, 962], :weight=>[884, 216.6], :key_no=>[961, 962], :bio_C=>[520.5286479058398, 216.67003041694414], :resp_c=>[8.208916910993821, 4.937267548490175], :NO2_NO3=>[28.527083027185896, 8.843145603237499], :NH4=>[1.2524085231447466, 0.5487285220470448], :bio_N=>[68.6208899978903, 22.545348621532753], :min=>[0.3009873462291107, 0.19077468173003975], :nit=>[0.3322067495507806, 0.1980418177219459], :H20=>[0.16246153846153846, 0.09664889565879653], :DEA=>[51.76546409535292, 1.5064599245568928], :sand_percent=>[nil, 73.26911591086505], :pH=>[7.83, 7.75]}
      assert temp.nrow == 2
      assert temp.ncol == 25
      assert temp.col_names == [:date, :core_id, :city, :case_id, :site_no, :core_no, :plot_no, :depth, :total_L, :notes, :core_sections, :sample_id, :weight, :key_no, :bio_C, :resp_c, :NO2_NO3, :NH4, :bio_N, :min, :nit, :H20, :DEA, :sand_percent, :pH]
    end
  end
end
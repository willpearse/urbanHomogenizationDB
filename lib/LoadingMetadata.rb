# -*- coding: utf-8 -*-
require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

def read_site_cats(file_name)
  curr_file = UniSheet.new file_name
  output = DataFrame.new({:city_parcel=>[],:code=>[],:cat_one=>[],:cat_two=>[],:age=>[],:prev=>[],:meta_area=>[]})
  curr_file.each do |line|
    if line[0] and line[0]!="case_id"
      output << {:city_parcel=>[line[6].to_s+"_"+line[0].to_s],:code=>[line[1]],:cat_one=>[line[2]],:cat_two=>[line[3]],:age=>[line[4]],:prev=>[line[5]],:meta_area=>[line[6]]}
    end
  end
  return output
end

if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  
  describe proc {read_site_cats} do
    it "loads parcel meta-data correctly" do
      temp = read_site_cats("test_files/meta.xlsx")
      assert temp.data == {:city_parcel=>["MSP_123456"], :code=>["T1Y1"], :cat_one=>["nonse"], :cat_two=>["exurban-agriculture"], :age=>["1974"], :prev=>["urban"], :meta_area=>["MSP"]}
      assert temp.nrow == 1
      assert temp.ncol == 7
      assert temp.col_names == [:city_parcel, :code, :cat_one, :cat_two, :age, :prev, :meta_area]
    end
  end
end

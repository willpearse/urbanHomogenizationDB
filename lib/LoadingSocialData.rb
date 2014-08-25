# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  2/21/2013

require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

def read_social(file_name)
  output = DataFrame.new({:city_parcel=>[],:income=>[],:landuse=>[],:year_built=>[],:yard_type=>[],:income_survey=>[],:income_combined=>[],:density_level=>[],:income_level=>[],:north_south=>[],:east_west=>[],:floral_biodiversity=>[],:local_nature_provisioning=>[],:supporting_environmental_services=>[],:local_cultural_value=>[],:neat_aesthetic=>[],:appearance=>[],:low_maintenance=>[],:low_cost=>[],:veg_private=>[],:veg_food=>[],:veg_cool=>[],:veg_condit=>[],:veg_common=>[],:veg_legac=>[],:yrd_weeds=>[],:yrd_looks=>[],:yrd_enjoy=>[],:yrd_social=>[],:yrd_common=>[],:yrd_air=>[],:yrd_climate=>[],:yrd_green=>[],:veg_aest=>[],:veg_ease=>[],:veg_wldlf=>[],:veg_nativ=>[],:veg_neat=>[],:veg_cost=>[],:veg_kids=>[],:veg_pets=>[],:veg_hoa=>[],:yrd_divers=>[],:yrd_learn=>[],:yrd_beaut=>[],:yrd_values=>[],:yrd_cost=>[],:yrd_tradit=>[],:yrd_drain=>[],:yrd_ease=>[],:yrd_pollut=>[],:yrd_neat=>[],:yrd_soil=>[],:yrd_kids=>[],:yrd_pets=>[],:yrd_flwrs=>[]})
  curr_file = UniSheet.new file_name
  city_code = ["ERROR", "AZ_", "LA_", "MN_", "BOS_", "FL_", "BA_"]
  curr_file.each do |line|
    if line[0] and line[0] != "CASE_ID"
      output << {:city_parcel=>[city_code[line[1].to_i]+line[0].to_s],:income=>[line[6]],:landuse=>[line[7]],:year_built=>[line[8]],:yard_type=>[line[9]],:income_survey=>[line[10]],:income_combined=>[line[11]],:density_level=>[line[12]],:income_level=>[line[13]],:north_south=>[line[14]],:east_west=>[line[15]],:floral_biodiversity=>[line[16]],:local_nature_provisioning=>[line[17]],:supporting_environmental_services=>[line[18]],:local_cultural_value=>[line[19]],:neat_aesthetic=>[line[20]],:appearance=>[line[21]],:low_maintenance=>[line[22]],:low_cost=>[line[23]],:veg_private=>[line[24]],:veg_food=>[line[25]],:veg_cool=>[line[26]],:veg_condit=>[line[27]],:veg_common=>[line[28]],:veg_legac=>[line[29]],:yrd_weeds=>[line[30]],:yrd_looks=>[line[31]],:yrd_enjoy=>[line[32]],:yrd_social=>[line[33]],:yrd_common=>[line[34]],:yrd_air=>[line[35]],:yrd_climate=>[line[36]],:yrd_green=>[line[37]],:veg_aest=>[line[38]],:veg_ease=>[line[39]],:veg_wldlf=>[line[40]],:veg_nativ=>[line[41]],:veg_neat=>[line[42]],:veg_cost=>[line[43]],:veg_kids=>[line[44]],:veg_pets=>[line[45]],:veg_hoa=>[line[46]],:yrd_divers=>[line[47]],:yrd_learn=>[line[48]],:yrd_beaut=>[line[49]],:yrd_values=>[line[50]],:yrd_cost=>[line[51]],:yrd_tradit=>[line[52]],:yrd_drain=>[line[53]],:yrd_ease=>[line[54]],:yrd_pollut=>[line[55]],:yrd_neat=>[line[56]],:yrd_soil=>[line[57]],:yrd_kids=>[line[58]],:yrd_pets=>[line[59]],:yrd_flwrs=>[line[60]]}
    end
  end
  return output
end

if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  describe proc {read_iTree} do
    it "loads social data correctly" do
      temp = read_social("test_files/social.csv")
      assert temp.data == {:city_parcel=>["MN_123", "5_123"], :income=>["High", "Middle"], :landuse=>["Ag", " "], :year_built=>["15-35", " "], :yard_type=>["Lawn", "Lawn"], :income_survey=>["7", "5"], :income_combined=>["2.00", "1.00"], :density_level=>["2.00", "1.00"], :income_level=>["3.00", "2.00"], :north_south=>["2.00", "2.00"], :east_west=>["2.00", "2.00"], :floral_biodiversity=>["2.5", ".0"], :local_nature_provisioning=>["2.0", "1.5"], :supporting_environmental_services=>[".0", ".7"], :local_cultural_value=>[".0", ".7"], :neat_aesthetic=>["1.0", "3.0"], :appearance=>["3.0", "3.0"], :low_maintenance=>["3.0", "2.5"], :low_cost=>[".0", ".0"], :veg_private=>["0", "2"], :veg_food=>["0", "0"], :veg_cool=>["2", "3"], :veg_condit=>["2", "2"], :veg_common=>["0", "0"], :veg_legac=>["3", "0"], :yrd_weeds=>["3", "3"], :yrd_looks=>["2", "0"], :yrd_enjoy=>["3", "3"], :yrd_social=>["0", "0"], :yrd_common=>["0", "0"], :yrd_air=>["0", "0"], :yrd_climate=>["0", "0"], :yrd_green=>["0", "3"], :veg_aest=>["3", "3"], :veg_ease=>["3", "3"], :veg_wldlf=>["2", "0"], :veg_nativ=>["2", "3"], :veg_neat=>["0", "3"], :veg_cost=>["0", "0"], :veg_kids=>["0", "2"], :veg_pets=>["2", "2"], :veg_hoa=>["0", "0"], :yrd_divers=>["3", "0"], :yrd_learn=>["0", "2"], :yrd_beaut=>["3", "3"], :yrd_values=>["0", "0"], :yrd_cost=>["0", "0"], :yrd_tradit=>["0", "0"], :yrd_drain=>["0", "0"], :yrd_ease=>["3", "2"], :yrd_pollut=>["0", "0"], :yrd_neat=>["2", "3"], :yrd_soil=>["0", "2"], :yrd_kids=>["0", "0"], :yrd_pets=>["3", "0"], :yrd_flwrs=>["2", "0"]}
      assert temp.nrow == 2
      assert temp.ncol == 56
      assert temp.col_names == [:city_parcel, :income, :landuse, :year_built, :yard_type, :income_survey, :income_combined, :density_level, :income_level, :north_south, :east_west, :floral_biodiversity, :local_nature_provisioning, :supporting_environmental_services, :local_cultural_value, :neat_aesthetic, :appearance, :low_maintenance, :low_cost, :veg_private, :veg_food, :veg_cool, :veg_condit, :veg_common, :veg_legac, :yrd_weeds, :yrd_looks, :yrd_enjoy, :yrd_social, :yrd_common, :yrd_air, :yrd_climate, :yrd_green, :veg_aest, :veg_ease, :veg_wldlf, :veg_nativ, :veg_neat, :veg_cost, :veg_kids, :veg_pets, :veg_hoa, :yrd_divers, :yrd_learn, :yrd_beaut, :yrd_values, :yrd_cost, :yrd_tradit, :yrd_drain, :yrd_ease, :yrd_pollut, :yrd_neat, :yrd_soil, :yrd_kids, :yrd_pets, :yrd_flwrs]
    end
  end
end





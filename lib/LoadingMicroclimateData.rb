# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  2/22/2013

# - the 'detection' in this is extremely basic, and all depends on the filename. Let's hope no one fucked that up!

require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

def read_iButton(file_name, city)
  type = "NA"
  output = DataFrame.new({:city_parcel=>[],:date=>[],:time=>[],:type=>[],:value=>[]})
  case
  when (file_name.split("_")[-1].downcase=="tm.csv" or file_name.split("_")[-1].downcase=="t.csv")
    if file_name.split("_")[-1].downcase=="t.csv"
      city_parcel = city +"_" + file_name.split("_")[1]
    else
      city_parcel = city +"_" + file_name.split("_")[2]
    end
    type = "temperature"
  when (file_name.split("_")[-1].downcase=="rh.csv" or file_name.split("_")[-1].downcase=="h.csv" or file_name.split("_")[-1].downcase=="hm.csv")
    if file_name.split("_")[-1].downcase=="h.csv"
      city_parcel = city +"_" + file_name.split("_")[1]
    else
      city_parcel = city +"_" + file_name.split("_")[2]
    end
    type = "humidity"
  else
    raise RuntimeError, "#{file_name} not a recognised iButton temperature or humidity sensor"
  end
  locker = false
  File.open file_name do |handle|
    handle.each do |line|
      line = line.split(",")
      if line[0]
        if locker
          date_time = line[0].split(" ")
          output << {:city_parcel=>[city_parcel],:date=>[date_time[0]],:time=>[date_time[1..2].join(" ")],:type=>[type],:value=>[line[2].chomp.to_f]}
        end
        if line[0]=="Date/Time" then locker = true end
      end
    end
  end
  return output
end

if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  describe proc {read_iButton} do
    it "loads iButton temperature data correctly" do
      temp = read_iButton("test_files/iButton_test_1234_TM.csv", "BOS")
      assert temp.data == {:city_parcel=>["BOS_test", "BOS_test", "BOS_test"], :date=>["4/27/13", "4/27/13", "4/27/13"], :time=>["10:08:01 PM", "10:38:01 PM", "11:08:01 PM"], :type=>["temperature","temperature","temperature"], :value=>[16.653, 16.151, 15.148]}
      assert temp.nrow == 3
      assert temp.ncol == 5
      assert temp.col_names == [:city_parcel, :date, :time, :type, :value]
    end
    it "loads iButton humidity data correctly" do
      temp = read_iButton("test_files/iButton_test_1234_RH.csv", "BOS")
      assert temp.data == {:city_parcel=>["BOS_test", "BOS_test", "BOS_test"], :date=>["4/27/13", "4/27/13", "4/27/13"], :time=>["10:08:01 PM", "10:38:01 PM", "11:08:01 PM"], :type=>["humidity","humidity","humidity"], :value=>[53.607, 55.981, 57.159]}
      assert temp.nrow == 3
      assert temp.ncol == 5
      assert temp.col_names == [:city_parcel, :date, :time, :type, :value]
    end
  end
end

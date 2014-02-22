# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  2/22/2013

# - the 'detection' in this is extremely basic, and all depends on the filename. Let's hope no one fucked that up!

require_relative 'UniSheet.rb'
require_relative 'DataFrame.rb'

def read_micro_temp(file_name, city)
  unless file_name.split("_")[-1].downcase=="tm.csv" or file_name.split("_")[-1].downcase=="t.csv" then raise RuntimeError, "#{file_name} is not an iButton temperature file" end
  if file_name.split("_")[-1].downcase=="t.csv"
    city_parcel = city +"_" + file_name.split("_")[1]
  else
    city_parcel = city +"_" + file_name.split("_")[2]
  end
  output = DataFrame.new({:city_parcel=>[],:date=>[],:time=>[],:temperature=>[]})
  locker = false
  File.open file_name do |handle|
    handle.each do |line|
      line = line.split(",")
      if line[0]
        if locker
          date_time = line[0].split(" ")
          output << {:city_parcel=>[city_parcel],:date=>[date_time[0]],:time=>[date_time[1..2].join(" ")],:temperature=>[line[2].chomp.to_f]}
        end
        locker = true if line[0]=="Date/Time"
      end
    end
  end
  return output
end

def read_micro_humidity(file_name, city)
  unless file_name.split("_")[-1].downcase=="rh.csv" or file_name.split("_")[-1].downcase=="h.csv" or file_name.split("_")[-1].downcase=="hm.csv" then raise RuntimeError, "#{file_name} is not an iButton humidity file" end
  if file_name.split("_")[-1].downcase=="h.csv"
    city_parcel = city +"_" + file_name.split("_")[1]
  else
    city_parcel = city +"_" + file_name.split("_")[2]
  end
  output = DataFrame.new({:city_parcel=>[],:date=>[],:time=>[],:humidity=>[]})
  locker = false
  File.open file_name do |handle|
    handle.each do |line|
      line = line.split(",")
      if line[0]
        if locker
          date_time = line[0].split(" ")
          output << {:city_parcel=>[city_parcel],:date=>[date_time[0]],:time=>[date_time[1..2].join(" ")],:humidity=>[line[2].chomp.to_f]}
        end
        locker = true if line[0]=="Date/Time"
      end
    end
  end
  return output
end

def read_iButton(file_name, city)
  if file_name.split("_")[-1].downcase=="tm.csv" or file_name.split("_")[-1].downcase=="t.csv"
    return [read_micro_temp(file_name, city), {:city_parcel=>[],:date=>[],:time=>[],:humidity=>[]}]
  else
    return [{:city_parcel=>[],:date=>[],:time=>[],:temperature=>[]}, read_micro_humidity(file_name, city)]
  end
end

if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  describe proc {read_micro_temp} do
    it "loads iButton temperature data correctly" do
      temp = read_micro_temp("test_files/iButton_test_1234_TM.csv", "BOS")
      assert temp.data == {:city_parcel=>["BOS_test", "BOS_test", "BOS_test"], :date=>["4/27/13", "4/27/13", "4/27/13"], :time=>["10:08:01 PM", "10:38:01 PM", "11:08:01 PM"], :temperature=>[16.653, 16.151, 15.148]}
      assert temp.nrow == 3
      assert temp.ncol == 4
      assert temp.col_names == [:city_parcel, :date, :time, :temperature]
    end
    it "fails on humidity data based on filename" do
      assert_raises(RuntimeError) {read_micro_temp("test_files/iButton_test_1234_RH.csv", "BOS")}
    end
  end
  describe proc {read_micro_humidity} do
    it "loads iButton humidity data correctly" do
      temp = read_micro_humidity("test_files/iButton_test_1234_RH.csv", "BOS")
      assert temp.data == {:city_parcel=>["BOS_test", "BOS_test", "BOS_test"], :date=>["4/27/13", "4/27/13", "4/27/13"], :time=>["10:08:01 PM", "10:38:01 PM", "11:08:01 PM"], :humidity=>[53.607, 55.981, 57.159]}
      assert temp.nrow == 3
      assert temp.ncol == 4
      assert temp.col_names == [:city_parcel, :date, :time, :humidity]
    end
    it "fails on temperature data based on filename" do
      assert_raises(RuntimeError) {read_micro_temp("test_files/iButton_test_1234_RH.csv", "BOS")}
    end
  end
  describe proc {read_iButton} do
    it "detects and loads temperature data based on filename" do
      temp = read_iButton("test_files/iButton_test_1234_TM.csv", "BOS")
      assert temp[0] == read_micro_temp("test_files/iButton_test_1234_TM.csv", "BOS")
      assert temp[1] == {:city_parcel=>[], :date=>[], :time=>[], :humidity=>[]}
      assert temp.length == 2
    end
    it "detects and loads humidity data based on filename" do
      temp = read_iButton("test_files/iButton_test_1234_RH.csv", "BOS")
      assert temp[0] == {:city_parcel=>[], :date=>[], :time=>[], :temperature=>[]}
      assert temp[1] == read_micro_humidity("test_files/iButton_test_1234_RH.csv", "BOS")
      assert temp.length == 2
    end
  end
end

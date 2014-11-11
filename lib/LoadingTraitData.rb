require_relative "UniSheet.rb"
require_relative "DataFrame.rb"

def read_leaves(file_name)
  output = DataFrame.new({:city_parcel=>[], :image_name=>[], :sp_binomial=>[], :raw_name=>[], :weight=>[], :height=>[]})
  curr_file = UniSheet.new file_name
  curr_file.each do |line|
    if line[0] != "" and line[1] != "file"
      city_parcel = "ERROR"
      if not line[3].include?("_")
        city_parcel = "MN_"+line[3]
      else city_parcel = line[3]
      end
      output << {:city_parcel=>[city_parcel], :image_name=>[line[1]], :sp_binomial=>[line[9]], :raw_name=>[line[2]], :weight=>[line[5]], :height=>[line[6]]}
    end
  end
  return output
end

def read_surface_areas(file_name, file_hash)
  output = DataFrame.new(:city_parcel=>[], :sp_binomial=>[], :image_name=>[], :seg_name=>[], :perimeter=>[], :surface_area=>[], :dissection=>[], :compactness=>[])
  curr_file = UniSheet.new file_name
  curr_file.each do |line|
    if line[0] and line[0] != "original.file"
      file = line[0]
      if file.include?("/") then file = file.split("/")[-1] end
      file.sub!(".png", "")
      city_parcel = "ERROR"
      t = file_hash.keys.grep Regexp.new(file)
      if t.length == 1
        city_parcel = file_hash[t[0]][0]
        sp_binomial = file_hash[t[0]][1]
      end
      output << {:city_parcel=>[city_parcel], :sp_binomial=>[sp_binomial], :image_name=>[line[0]], :seg_name=>[line[1]], :perimeter=>[line[2]], :surface_area=>[line[3]], :dissection=>[line[4]], :compactness=>[line[5]]}
    end
  end
  return output
end

if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  
  #Leaf tests
  describe proc {read_leaves} do
    it "loads Will's clean leaf format data correctly'" do
      temp = read_leaves("test_files/leaves.csv")
      assert temp.nrow == 2
      assert temp.ncol == 6
      assert temp.data == {:city_parcel=>["MN_7", "MN_7"], :image_name=>["/home/will/Documents/leaves/raw_data/Sam_et_al/Sam_Minnesota/TC.Agr_ten.1.7.png", "/home/will/Documents/leaves/raw_data/Sam_et_al/Sam_Minnesota/TC.Ama_ret.1.7.png"], :sp_binomial=>["Agrostis idahoensis", "Amaranthus retroflexus"], :raw_name=>["Agrostis tenuis", "Amaranthus retroflexus"], :weight=>["0.0694", "0.0243"], :height=>["8", "10"]}
      assert temp.col_names == [:city_parcel, :image_name, :sp_binomial, :raw_name, :weight, :height]
    end
  end

  describe proc {read_surface_areas} do
    it "loads stalkless statistics correct" do
      file = ["Baltimore_A 04-06-2013 9_9_9_9_3.png"]
      species = ["test"]
      city_parcel = ["penny lane"]
      hash = Hash[file.zip(city_parcel.zip(species))]
      temp = read_surface_areas("test_files/leaf_stats.txt", hash)
      assert temp.nrow == 2
      assert temp.ncol == 8
      assert temp.col_names == [:city_parcel, :sp_binomial, :image_name, :seg_name, :perimeter, :surface_area, :dissection, :compactness]
      assert temp.data == {:city_parcel=>["penny lane", "penny lane"], :sp_binomial=>["test", "test"], :image_name=>["Baltimore_A 04-06-2013 9_9_9_9_3", "Baltimore_A 04-06-2013 9_9_9_9_3"], :seg_name=>["Baltimore_A 04-06-2013 9_9_9_9_3_0.jpg", "Baltimore_A 04-06-2013 9_9_9_9_3_1.jpg"], :perimeter=>["1700.17889502", "951.447834896"], :surface_area=>["35590", "21242"], :dissection=>["0.0492491498166", "0.0938610550199"], :compactness=>["81.219676175", "42.6161840942"]}
    end
  end
end

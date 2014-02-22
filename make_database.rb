#!/usr/bin/env ruby
#Example:
#./make_database.rb thirdPass.db /home/will/Dropbox/homogenization/data/CFANSClone/

require_relative 'lib/LoadingVegData.rb'
require_relative 'lib/LoadingSoilData.rb'
require_relative 'lib/LoadingSocialData.rb'
require_relative 'lib/LoadingMicroclimateData.rb'
require_relative 'lib/ProcessingData.rb'

#MAIN
puts "\nUrban Homogenization of America - data cleaning and database generation script"
puts "2013-4-19 - Will Pearse (wdpearse@umn.edu)"
puts "Not recommended for use over a server. Watch for newly-created empty folders"
puts " - these may indicate that XLSX files are being multiply loaded"
puts "*** Does not load all Balitmore data"
puts "*** Converted social data to CSV because of XLSX loading problem (corrupt file?)"
puts "*** Currently don't know the name of cities 2 and 5; confirm (check with lookup)"
puts "*** Renamed some microclimates files to add .csv and remove .dxd and give MN decent names; not within script!"
puts "Each full stop = one city's data loaded"
if ARGV.length == 2
  if File.exist? ARGV[0]
    puts "\nERROR: Cowardly refusing to output to an existing database"
  else
    #Setup
    db = SQLite3::Database.open ARGV[0]    
    puts "\nEmpty database '#{ARGV[0]}' successfully created\n"
    
    #Change directory
    begin
      Dir.chdir ARGV[1]
    rescue
      abort "\nERROR: Cannot load specified CFANS directory. Exiting with no cleanup..."
    end

    ########################
    #Microclimate###########  
    ########################
    print "\nLoading microclimate temperature and humidity data";$stdout.flush
    #Baltimore
    temp = []
    Dir.foreach("iButton Data/Baltimore/August") {|file| if File.file? "iButton Data/Baltimore/August/"+file then temp << read_iButton("iButton Data/Baltimore/August/"+file, "BA") end}
    Dir.foreach("iButton Data/Baltimore/Dec13") {|file| if File.file? "iButton Data/Baltimore/Dec13/"+file then temp << read_iButton("iButton Data/Baltimore/Dec13/"+file, "BA") end}
    Dir.foreach("iButton Data/Baltimore/Forested Sites with Name Correction") {|file| if File.file? "iButton Data/Baltimore/Forested Sites with Name Correction/"+file then temp << read_iButton("iButton Data/Baltimore/Forested Sites with Name Correction/"+file, "BA") end}
    print ".";$stdout.flush
    #Boston
    Dir.foreach("iButton Data/Boston/Jan 2014") {|file| if File.file? "iButton Data/Boston/Jan 2014/"+file then temp << read_iButton("iButton Data/Boston/Jan 2014/"+file, "BOS") end}
    Dir.foreach("iButton Data/Boston/Nov 2013") {|file| if File.file? "iButton Data/Boston/Nov 2013/"+file then temp << read_iButton("iButton Data/Boston/Nov 2013/"+file, "BOS") end}
    Dir.foreach("iButton Data/Boston/Sep") {|file| if File.file? "iButton Data/Boston/Sep/"+file then temp << read_iButton("iButton Data/Boston/Sep/"+file, "BOS") end}
    print ".";$stdout.flush
    #Los Angeles
    Dir.foreach("iButton Data/Los Angeles/Sep") {|file| if File.file? "iButton Data/Los Angeles/Sep/"+file then temp << read_iButton("iButton Data/Los Angeles/Sep/"+file, "LA") end}
    Dir.foreach("iButton Data/Los Angeles/Dec2013Jan2014") {|file| if File.file? "iButton Data/Los Angeles/Dec2013Jan2014/"+file then temp << read_iButton("iButton Data/Los Angeles/Dec2013Jan2014/"+file, "LA") end}
    print ".";$stdout.flush
    #Miami
    Dir.foreach("iButton Data/Miami/July") {|file| if File.file? "iButton Data/Miami/July/"+file then temp << read_iButton("iButton Data/Miami/July/"+file, "FK") end}
    Dir.foreach("iButton Data/Miami/October") {|file| if File.file? "iButton Data/Miami/October/"+file then temp << read_iButton("iButton Data/Miami/October/"+file, "FL") end}
    print ".";$stdout.flush
    #Minnesota
    Dir.foreach("iButton Data/MSP") {|file| if File.file? "iButton Data/MSP/"+file then temp << read_iButton("iButton Data/MSP/"+file, "MN") end}
    print ".";$stdout.flush
    #Combine...
    print " - combining..."
    micro_temp = DataFrame.new({:city_parcel=>[],:date=>[],:time=>[],:temperature=>[]})
    micro_humidity = DataFrame.new({:city_parcel=>[],:date=>[],:time=>[],:humidity=>[]})
    temp.each do |entry|
      micro_temp << entry[0]
      micro_humidity << entry[1]
    end
    print " - #{micro_temp.nrow} + #{micro_temp.nrow} rows of data read"
    
    ########################
    #iTree##################
    ########################
    print "\nLoading tree survey data";$stdout.flush
    iTree = DataFrame.new({:city_parcel=>[],:tree_no=>[],:sp_common=>[],:dbh=>[],:height=>[],:ground_area=>[],:condition=>[],:leaf_area=>[],:leaf_biomass=>[],:leaf_area_index=>[],:carbon_storage=>[],:gross_carbon_seq=>[],:money_value=>[],:street=>[],:native=>[]})
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Lost Valley Prairie iTree summary.csv")
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/St. Croix Savanna iTree summary.csv")
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Wolsfeld Woods SNA iTree summary.csv")
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Wood Rill SNA iTree summary.csv")
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/iTree Data" do |file|
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Baltimore" do |file|
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    iTree << read_iTree('Data-Parcel-Maps/Data-Biophysical/Tree Sampling/BOS_Master_iTree.xlsx')
    print ".";$stdout.flush
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Miami" do |file|
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    print " - #{iTree.nrow} rows of data read"
    
    ########################
    #Vegetative surveys#####
    ########################
    print "\nLoading vegetative survey data";$stdout.flush
    veg_survey = DataFrame.new({:city_parcel=>[],:sp_common=>[],:sp_binomial=>[],:sp_native=>[],:location=>[],:cultivation=>[], :notes=>[]})
    veg_transect = DataFrame.new({:city_parcel=>[],:sp_binomial=>[], :transect=>[]})
    #Baltimore
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Baltimore" do |file|
      if file!=".DS_Store" and file!="lawn plant cover data" and file!="MISSING or UN-ID-ed.xlsx" and !file['BAL_DIV_Leakin'] and !file['BAL_DIV_ORU1'] and !file['.zip']
        file = "Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Baltimore/" + file
        if File.file? file then veg_survey << read_veg_survey(file, "baltimore") end
      end
    end
    print ".";$stdout.flush
    #Minnesota
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/Twin Cities Urban Plant diversity.xls", "minnesota")
    veg_transect << read_veg_transect("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/Wolsfeld Woods Diversity data.xlsx", "minnesota", "MN", "WolfsfeldWoods")
    veg_transect << read_veg_transect("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/Wood-Rill Diversity data.xlsx", "minnesota", "MN", "WoodRill")
    veg_transect << read_veg_transect("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/St. Croix savanna Diversity data.xlsx", "minnesota", "MN", "StCroix")
    veg_transect << read_veg_transect("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/Lost Valley Prairie Diversity data.xlsx", "minnesota", "MN", "LostValley")
    print ".";$stdout.flush
    #Miami
    #veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Miami/Miami Master Species List_FIU Query.xlsx", "miami")
    print ".";$stdout.flush
    #Boston
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Boston/Boston_specieslist.xls", "boston")
    veg_survey << read_veg_survey("/home/will/Dropbox/homogenization/data/CFANSClone/Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Boston/Boston_specieslist.xls", "boston")
    print ".";$stdout.flush
    #Phoenix
    veg_survey << read_veg_survey("/home/will/Dropbox/homogenization/data/CFANSClone/Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Phoenix/SP Diversity 30Sep.xlsx", "phoenix")
    print ".";$stdout.flush
    print " - #{veg_transect.nrow} rows of transect and #{veg_survey.nrow} rows of survey data read"

    ########################
    #Abundance surveys######
    ########################
    print "\nLoading lawn survey data";$stdout.flush
    lawn_survey = DataFrame.new({:city_parcel=>[], :sp_binomial=>[], :sp_common=>[], :location=>[], :abundance=>[]})
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/Twin Cities Abundance Data.xls", "minnesota")
    print ".";$stdout.flush
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Baltimore/lawn plant cover data" do |file|
      #Be careful of the diversity data that was accidentally placed in this folder...
      if File.file? file and file!=".DS_Store" and !file.include?("DIV")
        #Reference sites have a different data format
        if file.include?("Reference")
          lawn_survey << read_lawn_survey(file, "baltimore reference")
        else
          lawn_survey << read_lawn_survey(file, "baltimore")
        end
      end
    end
    print ".";$stdout.flush
    print " - #{lawn_survey.nrow} rows of data read"
    
    ########################
    #Soil cores#############
    ########################
    print "\nLoading soil cores data";$stdout.flush
    soil_survey = DataFrame.new({:date=>[],:core_id=>[],:city_parcel=>[],:date=>[],:site_no=>[],:core_no=>[],:plot_no=>[],:depth=>[],:total_L=>[],:notes=>[],:core_sections=>[],:sample_id=>[],:weight=>[],:key_no=>[],:bio_C=>[],:resp_c=>[],:NO2_NO3=>[],:NH4=>[],:bio_N=>[],:min=>[],:nit=>[],:H20=>[],:DEA=>[],:sand_percent=>[],:pH=>[]})
    soil_survey << read_soil("Data-Parcel-Maps/Soil/Miami_all_data.xlsx", "FL")
    print ".";$stdout.flush
    soil_survey << read_soil("Data-Parcel-Maps/Soil/MSB_Soils_data_compiled.xlsx", "MN", 1)
    print ".";$stdout.flush
    soil_survey << read_soil("Data-Parcel-Maps/Soil/MSB_Soils_data_compiled.xlsx", "BOS", 2)
    print ".";$stdout.flush
    soil_survey << read_soil("Data-Parcel-Maps/Soil/MSB_Soils_data_compiled.xlsx", "BA", 3)
    print ".";$stdout.flush
    print " - #{soil_survey.nrow} rows of data read"
    
    ########################
    #Phone surveys##########
    ########################
    print "\nLoading telephone survey data";$stdout.flush
    phone_survey = read_social("Data-Parcel-Maps/Social/Full_Data_withComposite_Scale_02-17-14.csv")
    print "......";$stdout.flush

    
    
    
    print ".";$stdout.flush

    
    ########################
    #Database Writing#######
    ########################
    puts "\nProcessing and simplifying database..."
    #Clean weird string values out
    iTree = clean_strings(iTree)
    veg_survey = clean_strings(veg_survey)
    veg_transect = clean_strings(veg_transect)
    lawn_survey = clean_strings(lawn_survey)
    soil_survey = clean_strings(soil_survey)
    phone_survey = clean_strings(phone_survey)
    micro_temp = clean_strings(micro_temp)
    micro_humidity = clean_strings(micro_humidity)
    #Create taxonomy table
    merger = merge_names([veg_survey, veg_transect, lawn_survey])
    veg_survey, veg_transect, lawn_survey = merger[0]
    taxonomy = merger[1]
    #Create city_parcel table
    merger = merge_cpp([iTree, veg_survey, veg_transect, lawn_survey, phone_survey, micro_temp, micro_humidity])
    iTree, veg_survey, veg_transect, lawn_survey, phone_survey, micro_temp, micro_humidity = merger[0]
    city_parcel = merger[1]
    
    puts "Writing database..."
    db.execute "CREATE TABLE iTree (cpp_index TEXT, tree_no TEXT, sp_common TEXT, dbh TEXT, height TEXT, ground_area TEXT, condition TEXT, leaf_area TEXT, leaf_biomass TEXT, leaf_area_index TEXT, carbon_storage TEXT, gross_carbon_seq TEXT, money_value TEXT, street TEXT, native TEXT)"
    add_to_data_base(iTree, db, "iTree", nil)
    db.execute "CREATE TABLE VegSurvey (cpp_index TEXT, sp_common TEXT, sp_index TEXT, sp_native TEXT, location TEXT, cultivation TEXT, notes TEXT)"
    add_to_data_base(veg_survey, db, "VegSurvey", nil)
    db.execute "CREATE TABLE VegTransect (cpp_index TEXT, sp_index TEXT, transect TEXT)"
    add_to_data_base(veg_transect, db, "VegTransect", nil)  
    db.execute "CREATE TABLE LawnSurvey (cpp_index TEXT, sp_index TEXT, sp_common TEXT, location TEXT, abundance INT)"
    add_to_data_base(lawn_survey, db, "LawnSurvey", nil)
    db.execute "CREATE TABLE PhoneSurvey (cpp_index TEXT, income TEXT, landuse TEXT, year_built TEXT, yard_type TEXT, income_survey TEXT, income_combined TEXT, density_level TEXT, income_level TEXT, north_south TEXT, east_west TEXT, floral_biodiversity TEXT, local_nature_provisioning TEXT, supporting_environmental_services TEXT, local_cultural_value TEXT, neat_aesthetic TEXT, appearance TEXT, low_maintenance TEXT, low_cost TEXT, veg_private TEXT, veg_food TEXT, veg_cool TEXT, veg_condit TEXT, veg_common TEXT, veg_legac TEXT, yrd_weeds TEXT, yrd_looks TEXT, yrd_enjoy TEXT, yrd_social TEXT, yrd_common TEXT, yrd_air TEXT, yrd_climate TEXT, yrd_green TEXT, veg_aest TEXT, veg_ease TEXT, veg_wldlf TEXT, veg_nativ TEXT, veg_neat TEXT, veg_cost TEXT, veg_kids TEXT, veg_pets TEXT, veg_hoa TEXT, yrd_divers TEXT, yrd_learn TEXT, yrd_beaut TEXT, yrd_values TEXT, yrd_cost TEXT, yrd_tradit TEXT, yrd_drain TEXT, yrd_ease TEXT, yrd_pollut TEXT, yrd_neat TEXT, yrd_soil TEXT, yrd_kids TEXT, yrd_pets TEXT, yrd_flwrs TEXT)"   
    add_to_data_base(phone_survey, db, "PhoneSurvey", nil)
    db.execute "CREATE TABLE MicroTemperature (cpp_index TEXT, date TEXT, time TEXT, temperature REAL)"
    add_to_data_base(micro_temp, db, "MicroTemperature", nil)
    db.execute "CREATE TABLE MicroHumidity (cpp_index TEXT, date TEXT, time TEXT, humidity REAL)"
    add_to_data_base(micro_humidity, db, "MicroHumidity", nil)
    db.execute "CREATE TABLE Taxonomy (sp_binomial TEXT, sp_index TEXT)"
    add_to_data_base(taxonomy, db, "Taxonomy", nil)
    db.execute "CREATE TABLE City_Parcel (city_parcel TEXT, cpp_index TEXT)"
    add_to_data_base(city_parcel, db, "City_Parcel", nil)
    
    puts "\nFinished!\n"
  end
else
  puts "ERROR: You *must* specify:"
  puts "\tOutput database filename (*.db)"
  puts "\tThe root of the raw data folder\n\n"
end

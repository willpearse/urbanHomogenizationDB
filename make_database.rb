#!/usr/bin/env ruby
#Example:
#./make_database.rb thirdPass.db /Users/will/Dropbox/homogenization/data/CFANSClone/

require_relative 'lib/LoadingVegData.rb'
require_relative 'lib/LoadingSoilData.rb'
require_relative 'lib/ProcessingData.rb'

#MAIN
puts "\nUrban Homogenization of America - data cleaning and database generation script"
puts "2013-4-19 - Will Pearse (wdpearse@umn.edu)"
puts "Not recommended for use over a server. Watch for newly-created empty folders"
puts " - these may indicate that XLSX files are being multiply loaded"
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
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Miami/Species list-Miami-1-8-13.xlsx", "miami")
    print ".";$stdout.flush
    #Boston
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Baltimore" do |file|
      veg_survey << read_veg_survey(file, "boston") if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    print " - #{veg_transect.nrow} rows of transect and #{veg_survey.nrow} rows of survey data read"

    ########################
    #Abundance surveys######
    ########################
    print "\nLoading lawn survey data";$stdout.flush
    lawn_survey = DataFrame.new({:city_parcel=>[], :sp_binomial=>[], :sp_common=>[], :location=>[]})
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/Twin Cities Abundance Data.xls", "minnesota")
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
    soil_survey << read_soil("Data-Parcel-Maps/Soil/MSB_Soils_data_compiled.xlsx", "MN", 2)
    print ".";$stdout.flush
    soil_survey << read_soil("Data-Parcel-Maps/Soil/MSB_Soils_data_compiled.xlsx", "MN", 3)
    print ".";$stdout.flush
    print " - #{soil_survey.nrow} rows of data read"
    
    ########################
    #Database Writing#######
    ########################
    puts "\nProcessing for database..."
    #Clean weird string values out
    iTree = clean_strings(iTree)
    veg_survey = clean_strings(veg_survey)
    veg_transect = clean_strings(veg_transect)
    lawn_survey = clean_strings(lawn_survey)
    soil_survey = clean_strings(soil_survey)
    #Create taxonomy table
    merger = merge_names([veg_survey, veg_transect, lawn_survey])
    veg_survey, veg_transect, lawn_survey = merger[0]
    taxonomy = merger[1]
    #Create city_parcel table
    merger = merge_cpp([iTree, veg_survey, veg_transect, lawn_survey])
    iTree, veg_survey, veg_transect, lawn_survey = merger[0]
    city_parcel = merger[1]
    
    puts "Writing database..."
    db.execute "CREATE TABLE iTree (cpp_index TEXT, tree_no TEXT, sp_common TEXT, dbh TEXT, height TEXT, ground_area TEXT, condition TEXT, leaf_area TEXT, leaf_biomass TEXT, leaf_area_index TEXT, carbon_storage TEXT, gross_carbon_seq TEXT, money_value TEXT, street TEXT, native TEXT)"
    add_to_data_base(iTree, db, "iTree", nil)
    db.execute "CREATE TABLE VegSurvey (cpp_index TEXT, sp_common TEXT, sp_index TEXT, sp_native TEXT, location TEXT, cultivation TEXT, notes TEXT)"
    add_to_data_base(veg_survey, db, "VegSurvey", nil)
    db.execute "CREATE TABLE VegTransect (cpp_index TEXT, sp_index TEXT, transect TEXT)"
    add_to_data_base(veg_transect, db, "VegTransect", nil)  
    db.execute "CREATE TABLE LawnSurvey (cpp_index TEXT, sp_index TEXT, sp_common TEXT, location TEXT)"
    add_to_data_base(lawn_survey, db, "LawnSurvey", nil)
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

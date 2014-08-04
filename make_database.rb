#!/usr/bin/env ruby
#Example:
#./make_database.rb esa.db /home/will/Dropbox/homogenization/data/CFANSClone/ 0
#Notes:
#Converted social data to CSV because of XLSX loading problem (corrupt file?)"
#Renamed some microclimates files to add .csv and remove .dxd and give MN decent names; not within script!
#Using this over a network may cause problems; xlsx loading gem is rubbish
#All Phoenix DBH heights are 1.7 so I've ignored this field

#To-DO:
#Salt Lake City and Phoenix has height for trees, but there seems to be the same measurement for many trees. This script loads this in as if it were correct; it likely isn't! 
#Does not load all Balitmore data
#Phoenix also seems to have none of the valuation information that the others sites have. Does this need to be run manually?
#No tests written for Salt Lake City because OpenOffice is shite"
#Add abundance to lawn survey!!!
#Some lawn surveys have transect numbers in rural areas; include? (...probably, as a separate column...)

require_relative 'lib/LoadingVegData.rb'
require_relative 'lib/LoadingSoilData.rb'
require_relative 'lib/LoadingSocialData.rb'
require_relative 'lib/LoadingMicroclimateData.rb'
require_relative 'lib/LoadingMetadata.rb'
require_relative 'lib/ProcessingData.rb'

#MAIN
puts "\nUrban Homogenization of America database script"
puts "v0.3 - DEV - Will Pearse (wdpearse@umn.edu)"
puts "*** Does not load all Balitmore data"
puts "*** Converted social data to CSV because of XLSX loading problem (corrupt file?)"
puts "*** Currently don't know the name of cities 2 and 5; confirm (check with lookup)"
puts "*** Renamed some microclimates files to add .csv and remove .dxd and give MN decent names; not within script!"
puts "*** Only loads the processed soil microclimate data; the raw structure is intelligible but I'm unwilling to put my neck out and guess!"
puts "Each full stop = one city's data loaded"

if ARGV.length == 3
  if File.exist? ARGV[0]
    puts "\nERROR: Cowardly refusing to output to an existing database"
  else
    #Setup
    db = SQLite3::Database.open ARGV[0]    
    puts "\nEmpty database '#{ARGV[0]}' successfully created\n"
    
    #Change directory
    begin
      orig_wd = Dir.getwd
      Dir.chdir ARGV[1]
    rescue
      abort "\nERROR: Cannot load specified CFANS directory. Exiting with no cleanup..."
    end

    ########################
    #Metadata######
    ########################
    print "\nLoading parcel meta-data        ";$stdout.flush
    metadata = read_site_cats("Data-Parcel-Maps/Data-Biophysical/MSB_parcels_categories.xlsx")
    print "......";$stdout.flush
    
    ########################
    #Soil microclimate######
    ########################
    print "\nLoading soil microclimate data  ";$stdout.flush
    soil_microclimate = DataFrame.new({:date=>[],:city_parcel=>[],:moisture=>[],:temperature=>[]})
    #Baltimore
    Dir.foreach("Soil Moisture Sensor Data/Baltimore") {|file| if file[".xls"] then soil_microclimate << read_soil_microclimate("Soil Moisture Sensor Data/Baltimore/"+file, "BA", 2) end}
    
    Dir.foreach("Soil Moisture Sensor Data/Baltimore/Forested Sites with name corrections") {|file| if file[".xls"] then soil_microclimate << read_soil_microclimate("Soil Moisture Sensor Data/Baltimore/Forested Sites with name corrections/"+file, "BA", 0) end}
    print ".";$stdout.flush
    #Boston
    Dir.foreach("Soil Moisture Sensor Data/Boston/Sep") {|file| if file[".xls"] then soil_microclimate << read_soil_microclimate("Soil Moisture Sensor Data/Boston/Sep/"+file, "BOS", 0) end}
    print ".";$stdout.flush
    #Miami
    Dir.foreach("Soil Moisture Sensor Data/Miami") {|file| if file[".xls"] then soil_microclimate << read_soil_microclimate("Soil Moisture Sensor Data/Miami/"+file, "BOS", 2) end}
    print ".";$stdout.flush
    
    ########################
    #Microclimate###########  
    ########################
    
    print "\nLoading microclimate data       ";$stdout.flush
    #Baltimore
    microclimate = DataFrame.new({:city_parcel=>[],:date=>[],:time=>[],:type=>[],:value=>[]})
    Dir.foreach("iButton Data/Baltimore/August") {|file| if File.file? "iButton Data/Baltimore/August/"+file then microclimate << read_iButton("iButton Data/Baltimore/August/"+file, "BA") end}
    Dir.foreach("iButton Data/Baltimore/Dec13") {|file| if File.file? "iButton Data/Baltimore/Dec13/"+file then microclimate << read_iButton("iButton Data/Baltimore/Dec13/"+file, "BA") end}
    Dir.foreach("iButton Data/Baltimore/Forested Sites with Name Correction") {|file| if File.file? "iButton Data/Baltimore/Forested Sites with Name Correction/"+file then microclimate << read_iButton("iButton Data/Baltimore/Forested Sites with Name Correction/"+file, "BA") end}
    print ".";$stdout.flush
    #Boston
    Dir.foreach("iButton Data/Boston/Jan 2014") {|file| if File.file? "iButton Data/Boston/Jan 2014/"+file then microclimate << read_iButton("iButton Data/Boston/Jan 2014/"+file, "BOS") end}
    Dir.foreach("iButton Data/Boston/Nov 2013") {|file| if File.file? "iButton Data/Boston/Nov 2013/"+file then microclimate << read_iButton("iButton Data/Boston/Nov 2013/"+file, "BOS") end}
    Dir.foreach("iButton Data/Boston/Sep") {|file| if File.file? "iButton Data/Boston/Sep/"+file then microclimate << read_iButton("iButton Data/Boston/Sep/"+file, "BOS") end}
    print ".";$stdout.flush
    #Los Angeles
    Dir.foreach("iButton Data/Los Angeles/Sep") {|file| if File.file? "iButton Data/Los Angeles/Sep/"+file then microclimate << read_iButton("iButton Data/Los Angeles/Sep/"+file, "LA") end}
    Dir.foreach("iButton Data/Los Angeles/Dec2013Jan2014") {|file| if File.file? "iButton Data/Los Angeles/Dec2013Jan2014/"+file then microclimate << read_iButton("iButton Data/Los Angeles/Dec2013Jan2014/"+file, "LA") end}
    print ".";$stdout.flush
    #Miami
    Dir.foreach("iButton Data/Miami/July") {|file| if File.file? "iButton Data/Miami/July/"+file then microclimate << read_iButton("iButton Data/Miami/July/"+file, "FL") end}
    Dir.foreach("iButton Data/Miami/October") {|file| if File.file? "iButton Data/Miami/October/"+file then microclimate << read_iButton("iButton Data/Miami/October/"+file, "FL") end}
    print ".";$stdout.flush
    #Minnesota
    Dir.foreach("iButton Data/MSP") {|file| if File.file? "iButton Data/MSP/"+file then microclimate << read_iButton("iButton Data/MSP/"+file, "MN") end}
    print ".";$stdout.flush
    
    ########################
    #iTree##################
    ########################
    print "\nLoading tree survey data        ";$stdout.flush
    #Minnesota
    iTree = read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Lost Valley Prairie iTree summary.csv")
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/St. Croix Savanna iTree summary.csv")
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Wolsfeld Woods SNA iTree summary.csv")
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Wood Rill SNA iTree summary.csv")
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/iTree Data" do |file|
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    #Baltimore
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Baltimore" do |file|
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    #Boston
    iTree << read_iTree('Data-Parcel-Maps/Data-Biophysical/Tree Sampling/BOS_Master_iTree.xlsx')
    print ".";$stdout.flush
    #Miami
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Miami" do |file|
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    #LA
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/LA_2013_iTree.csv", "la")
    print ".";$stdout.flush
    #Phoenix
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Tree Sampling/PHX iTree 13 Feb.xlsx", "phoenix")
    print ".";$stdout.flush
    #Salt Lake
    iTree << read_iTree("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Salt Lake/SLC_SpeicesList_LawnQuad_Trees.xlsx", "saltlake")
    print ".";$stdout.flush
    
    ########################
    #Vegetative surveys#####
    ########################
    print "\nLoading vegetative survey data  ";$stdout.flush
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
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Miami/Vascular Diversity by ID code 2-21-13.xlsx", "miami")
    veg_transect << read_veg_transect("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Miami/Miami Control Sites.xlsx", "miami", "FL")
    print ".";$stdout.flush
    #Boston
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Boston/Boston_specieslist.xls", "boston")
    veg_survey << read_veg_survey("/home/will/Dropbox/homogenization/data/CFANSClone/Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Boston/Boston_specieslist.xls", "boston")
    print ".";$stdout.flush
    #Phoenix
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Phoenix/SP Diversity 30Sep.xlsx", "phoenix")
    print ".";$stdout.flush
    #Los Angeles
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/LA/LA2013SpeciesInventory_Will_Corrections.xlsx", "la")
    veg_transect << read_veg_transect("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/LA/LA2013SpeciesInventoryNativeCSSFinal4Will.xlsx", "la", "LA")
    print ".";$stdout.flush
    #Salt Lake City
    veg_survey << read_veg_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Salt Lake/SLC_SpeicesList_LawnQuad_Trees.xlsx", "saltlake")
    veg_transect << read_veg_transect("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Salt Lake/SLC_ReferenceSites_ForWill.xlsx", "saltlake", "SL")
    print ".";$stdout.flush

    ########################
    #Abundance surveys######
    ########################
    print "\nLoading lawn survey data        ";$stdout.flush
    #Minnesota
    lawn_survey = read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Twin Cities Data/Twin Cities Abundance Data.xls", "minnesota")
    print ".";$stdout.flush
    #Baltimore
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
    #Boston
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Boston/Boston lawn data 2012.xlsx", "boston")
    print ".";$stdout.flush
    #Phoenix
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Phoenix/PHX Yard Cover 17 Feb.xlsx", "phoenix")
    print ".";$stdout.flush
    #LA
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/LA/LA2013LawnCover4Will.xlsx", "la")
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/LA/LA2013PlantCoverNativeCSSFinal4Will.xlsx", "la rural")
    print ".";$stdout.flush
    #Miami
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Miami/Copy of Veg_grass_cover_LL.xlsx", "miami")
    print ".";$stdout.flush
    #Salt Lake
    lawn_survey << read_lawn_survey("Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Salt Lake/SLC_SpeicesList_LawnQuad_Trees.xlsx", "saltlake")
    print ".";$stdout.flush

    ########################
    #Soil cores#############
    ########################
    print "\nLoading soil baseline data      ";$stdout.flush
    soil = read_soil_baseline("Data-Parcel-Maps/Soil/MSB_all data with categories.xlsx")
    print "......";$stdout.flush
    
    ########################
    #Phone surveys##########
    ########################
    print "\nLoading telephone survey data   ";$stdout.flush
    phone_survey = read_social("Data-Parcel-Maps/Social/Full_Data_withComposite_Scale_02-17-14.csv")
    print "......";$stdout.flush
   
    ########################
    #Database cleaning######
    ########################
    puts "\nProcessing database..."
    #Clean weird string values out
    iTree = clean_strings(iTree)
    veg_survey = clean_strings(veg_survey)
    veg_transect = clean_strings(veg_transect)
    lawn_survey = clean_strings(lawn_survey)
    phone_survey = clean_strings(phone_survey)
    soil = clean_strings(soil)
    microclimate = clean_strings(microclimate)
    soil_microclimate = clean_strings(soil_microclimate)
    metadata = clean_strings(metadata)

    #Create city_parcel table
    merger = merge_cpp([iTree, veg_survey, veg_transect, lawn_survey, phone_survey, soil, microclimate, soil_microclimate, metadata])
    iTree, veg_survey, veg_transect, lawn_survey, phone_survey, soil, microclimate, soil_microclimate, metadata = merger[0]
    city_parcel = merger[1]

    #Cleanup site names
    change_names!({"BA_"=>"BA_6503"}, city_parcel, :city_parcel)
    change_names_regex!({"LAX"=>"LA", "MSP"=>"MN", "BAL"=>"BA", "MIA"=>"FL", "AZ"=>"PHX"}, city_parcel, :city_parcel)
    
    ########################
    #Taxonomy###############
    ########################
    Dir.chdir orig_wd
    merger = merge_names([veg_survey, veg_transect, lawn_survey, iTree])
    veg_survey, veg_transect, lawn_survey, iTree = merger[0]
    taxonomy = merger[1]
    case
    when ARGV[2] == "0"
      puts "Ignoring taxonomy..."
    when (ARGV[2] == "1" or ARGV[2] == "2")
      if ARGV[2] == "1"
        puts "DOESN'T WORK. R script assumes it has a species input; using existing.."
        #puts "Calculating taxonomy..."
        #`R CMD BATCH taxonomy_cleaning.R`
      else
        puts "Using existing taxonomy..."
      end
      taxonomy = DataFrame.new({:sp_index=>[],:sp_binomial=>[],:sp_binomial_clean=>[]})
      curr_file = UniSheet.new "taxonomy.csv"
      curr_file.each do |line|
        taxonomy << {:sp_index=>[line[0]],:sp_binomial=>[line[1]],:sp_binomial_clean=>[line[2]]}
      end
    else
      puts "ERROR! Nonsense taxonomy request, ignoring..."
    end
    
    ########################
    #Database writing#######
    ########################    
    puts "Writing database..."
    db.execute "CREATE TABLE iTree (cpp_index TEXT, tree_no TEXT, sp_index TEXT, sp_common TEXT, dbh TEXT, height TEXT, ground_area TEXT, condition TEXT, leaf_area TEXT, leaf_biomass TEXT, leaf_area_index TEXT, carbon_storage TEXT, gross_carbon_seq TEXT, money_value TEXT, street TEXT, native TEXT)"
    add_to_data_base(iTree, db, "iTree", nil)
    db.execute "CREATE TABLE VegSurvey (cpp_index TEXT, sp_common TEXT, sp_index TEXT, sp_native TEXT, location TEXT, cultivation TEXT, notes TEXT)"
    add_to_data_base(veg_survey, db, "VegSurvey", nil)
    db.execute "CREATE TABLE VegTransect (cpp_index TEXT, sp_index TEXT, transect TEXT)"
    add_to_data_base(veg_transect, db, "VegTransect", nil)  
    db.execute "CREATE TABLE LawnSurvey (cpp_index TEXT, sp_index TEXT, sp_common TEXT, location TEXT, abundance INT, transect TEXT)"
    add_to_data_base(lawn_survey, db, "LawnSurvey", nil)
    db.execute "CREATE TABLE PhoneSurvey (cpp_index TEXT, income TEXT, landuse TEXT, year_built TEXT, yard_type TEXT, income_survey TEXT, income_combined TEXT, density_level TEXT, income_level TEXT, north_south TEXT, east_west TEXT, floral_biodiversity TEXT, local_nature_provisioning TEXT, supporting_environmental_services TEXT, local_cultural_value TEXT, neat_aesthetic TEXT, appearance TEXT, low_maintenance TEXT, low_cost TEXT, veg_private TEXT, veg_food TEXT, veg_cool TEXT, veg_condit TEXT, veg_common TEXT, veg_legac TEXT, yrd_weeds TEXT, yrd_looks TEXT, yrd_enjoy TEXT, yrd_social TEXT, yrd_common TEXT, yrd_air TEXT, yrd_climate TEXT, yrd_green TEXT, veg_aest TEXT, veg_ease TEXT, veg_wldlf TEXT, veg_nativ TEXT, veg_neat TEXT, veg_cost TEXT, veg_kids TEXT, veg_pets TEXT, veg_hoa TEXT, yrd_divers TEXT, yrd_learn TEXT, yrd_beaut TEXT, yrd_values TEXT, yrd_cost TEXT, yrd_tradit TEXT, yrd_drain TEXT, yrd_ease TEXT, yrd_pollut TEXT, yrd_neat TEXT, yrd_soil TEXT, yrd_kids TEXT, yrd_pets TEXT, yrd_flwrs TEXT)"   
    add_to_data_base(phone_survey, db, "PhoneSurvey", nil)
    db.execute "CREATE TABLE Microclimate (cpp_index TEXT, date TEXT, time TEXT, type TEXT, value TEXT REAL)"
    add_to_data_base(microclimate, db, "Microclimate", nil)
    db.execute "CREATE TABLE SoilMicroclimate (cpp_index TEXT, date TEXT, time TEXT, temperature TEXT, moisture TEXT)"
    add_to_data_base(soil_microclimate, db, "SoilMicroclimate", nil)
    #Taxonomy requires special attention
    if (ARGV[2]=="1" or ARGV[2]=="2")
      db.execute "CREATE TABLE Taxonomy (sp_index TEXT, sp_binomial TEXT, sp_binomial_clean TEXT)"
      add_to_data_base(taxonomy, db, "Taxonomy", nil)
    else
      db.execute "CREATE TABLE Taxonomy (sp_binomial TEXT, sp_index TEXT)"
      add_to_data_base(taxonomy, db, "Taxonomy", nil)
    end
    db.execute "CREATE TABLE SoilSurvey (cpp_index TEXT, date TEXT, core_id TEXT, site_no TEXT, core_no TEXT, plot_no TEXT, depth TEXT, total_L TEXT, notes TEXT, core_sections TEXT, section_length TEXT, volume TEXT, tot_sub_rock_vol TEXT, wet_weight TEXT, dry_weight TEXT, dry_weight_sub_rock_weight TEXT, density TEXT, root_mass TEXT, rock_mass TEXT, rock_vol TEXT, microb_biomass TEXT, respiration TEXT, NO2_over_NO3 TEXT, NH4 TEXT, bio_N TEXT, mineral TEXT, nitrogen TEXT, moisture TEXT, DEA TEXT, percent_sand TEXT, pH TEXT)"    
    add_to_data_base(soil, db, "SoilSurvey", nil)
    db.execute "CREATE TABLE City_Parcel (city_parcel TEXT, cpp_index TEXT)"
    add_to_data_base(city_parcel, db, "City_Parcel", nil)
    db.execute "CREATE TABLE MetaData (cpp_index TEXT, code TEXT, cat_one TEXT, cat_two TEXT, age TEXT, prev TEXT, meta_area TEXT)"
    add_to_data_base(metadata, db, "MetaData", nil)
    
    puts "\nFinished!\n"
  end
else
  puts "ERROR: You *must* specify:"
  puts "\tOutput database filename (*.db)"
  puts "\tThe root of the raw data folder\n\n"
  puts "\tHow to fix species taxonomy:"
  puts "\t\t0 - do nothing"
  puts "\t\t1 - build new taxonomy from scratch (requires R etc.)"
  puts "\t\t2 - use existing taxonomy lookup ('taxonomy.csv')"
end

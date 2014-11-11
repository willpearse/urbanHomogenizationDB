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
require_relative 'lib/LoadingTraitData.rb'
require_relative 'lib/LoadingMetadata.rb'
require_relative 'lib/ProcessingData.rb'

#MAIN
puts "\nUrban Homogenization of America database script"
puts "v0.3 - DEV - Will Pearse (wdpearse@umn.edu)"
puts "*** Does not load all Balitmore data"
puts "*** Converted social data to CSV because of XLSX loading problem (corrupt file?)"
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
    #Metadata###############
    ########################
    print "\nLoading parcel meta-data        ";$stdout.flush
    metadata = read_site_cats("Data-Parcel-Maps/Data-Biophysical/MSB_parcels_categories_wdp.xlsx")
    parcel_areas = read_parcel_area("Data-Parcel-Maps/HouseholdSurvey_Parcels.xls")
    print "......";$stdout.flush   
    
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
      file = "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/iTree Data/"+file
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    #Baltimore
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Baltimore" do |file|
      file = "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Baltimore/"+file
      iTree << read_iTree(file) if File.file? file and file!=".DS_Store"
    end
    print ".";$stdout.flush
    #Boston
    iTree << read_iTree('Data-Parcel-Maps/Data-Biophysical/Tree Sampling/BOS_Master_iTree.xlsx')
    print ".";$stdout.flush
    #Miami
    Dir.foreach "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Miami" do |file|
      file = "Data-Parcel-Maps/Data-Biophysical/Tree Sampling/Miami/" + file 
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
      file = "Data-Parcel-Maps/Data-Biophysical/Plant Diversity/Vegetation data by Region/Baltimore/lawn plant cover data/"+file
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
    #Leaf traits###########
    ########################
    print "\nLoading leaf trait data         ";$stdout.flush
    leaves = read_leaves("Data-Parcel-Maps/Leaf traits/meta_data.csv")
    temp = Hash[leaves.data[:image_name].zip(leaves.data[:city_parcel].zip(leaves.data[:sp_binomial]))]
    leaf_surface_areas = read_surface_areas("Data-Parcel-Maps/Leaf traits/stalkless_numberless.txt", temp)
    leaf_surface_areas << read_surface_areas("Data-Parcel-Maps/Leaf traits/stalkless_numbered.txt", temp)
    print "......";$stdout.flush
    
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
    metadata = clean_strings(metadata)
    leaves = clean_strings(leaves)
    leaf_surface_areas = clean_strings(leaf_surface_areas)

    #Create city_parcel table
    merger = merge_cpp([iTree, veg_survey, veg_transect, lawn_survey, phone_survey, soil, metadata, leaves, leaf_surface_areas])
    iTree, veg_survey, veg_transect, lawn_survey, phone_survey, soil, metadata, leaves, leaf_surface_areas = merger[0]
    city_parcel = merger[1]

    #Cleanup site names
    city_parcel.insert :orig_city_parcel
    city_parcel.data[:orig_city_parcel] = city_parcel[:city_parcel].dup
    change_names!({"BA_"=>"BA_6503"}, city_parcel, :city_parcel)
    change_names_regex!({".0"=>""}, city_parcel, :city_parcel)
    change_names_regex!({"LAX"=>"LA", "MSP"=>"MN", "BAL"=>"BA", "MIA"=>"FL", "AZ"=>"PHX", "PX"=>"PHX", "_00"=>"_", "_0"=>"_"}, city_parcel, :city_parcel)
    change_names!({"PHX_AG 3"=>"PHX_Ag3","PHX_AG Site 2"=>"PHX_Ag2","BOS_11400"=>"FL_11400","BOS_11465"=>"FL_11465","BOS_11801"=>"FL_11801","BOS_11823"=>"FL_11823","BOS_14405"=>"FL_14405","BOS_1663"=>"FL_1663","BOS_16943"=>"FL_16943","BOS_17089"=>"FL_17089","BOS_4666"=>"FL_4666","BOS_5276"=>"FL_5276","BOS_8486"=>"FL_8486","BOS_8963"=>"FL_8963","BOS_ADBarnes"=>"FL_ADBarnes","BOS_Barnacle"=>"FL_Barnacle","BOS_Simpson"=>"FL_Simpson","BOS_TradeWinds"=>"FL_Tradewinds","FL_A.D. Barnes"=>"FL_ADBarnes","FL_ADbarnes"=>"FL_ADBarnes","FL_Bsarnacle"=>"FL_Barnacle","FL_Simpsons"=>"FL_Simpson","LA_CSS1"=>"LA_LOMARidge","LA_CSS2"=>"LA_ShadyCanyon","LA_CSS3"=>"LA_BommerCanyon","LA_1"=>"LA_LOMARidge","LA_2"=>"LA_ShadyCanyon","LA_3"=>"LA_BommerCanyon","FL_Sugar Sand"=>"FL_SugarSand","MN_CedarCreek"=>"MN_NatRef_CedarCreek","MN_L3N.Ag"=>"MN_AgRef_UMN","MN_LostValley"=>"MN_NatRef_LostValleyPrairie","MN_STCROIX"=>"MN_NatRef_StCroixSavanna","MN_StCroix"=>"MN_NatRef_StCroixSavanna","MN_WolfsfeldWoods"=>"MN_NatRef_WolsfeldWoods","MN_WoodRill"=>"MN_NatRef_WoodRill","MN_Woodrill"=>"MN_NatRef_WoodRill","MN_X1.Ag"=>"MN_AgRef_UMN","MN_woodsril"=>"MN_NatRef_WoodRill","MN_woodsrill"=>"MN_NatRef_WoodRill","MN_CCF 1 CDR Ag (Corn) "=>"MN_AgRef_CedarCreek","MN_CCF 2 CDR Ag (Soy)"=>"MN_AgRef_CedarCreek","MN_CDR104"=>"MN_NatRef_CedarCreek","MN_CDR108"=>"MN_NatRef_CedarCreek","MN_CDRAgLoamCCF1"=>"MN_AgRef_CedarCreek","MN_CDRSoybeanCCF2"=>"MN_AgRef_CedarCreek","MN_Cedar Creek-plot 108 and 104"=>"MN_NatRef_CedarCreek","MN_Has1"=>"MN_NatRef_HelenAllison","MN_Has3"=>"MN_NatRef_HelenAllison","MN_Helen Alison-plot 1 and 3"=>"MN_NatRef_HelenAllison","MN_L-3N"=>"MN_AgRef_UMN","MN_L3N"=>"MN_AgRef_UMN","MN_Lost Valley Prairie"=>"MN_NatRef_LostValleyPrairie","MN_Lost Valley-plot 1 and 2"=>"MN_NatRef_LostValleyPrairie","MN_LostValleyForest1"=>"MN_NatRef_LostValleyPrairie","MN_LostValleyPrairie"=>"MN_NatRef_LostValleyPrairie","MN_St. Croix Savanna"=>"MN_NatRef_StCroixSavanna","MN_St. Croix- plot 1 and 2"=>"MN_NatRef_StCroixSavanna","MN_St.Croixplot1"=>"MN_NatRef_StCroixSavanna","MN_St.Croixplot2"=>"MN_NatRef_StCroixSavanna","MN_Wolsfeld Woods SNA"=>"MN_NatRef_WolsfeldWoods","MN_Wolsfeld-Plot 4 and 5"=>"MN_NatRef_WolsfeldWoods","MN_WolsfieldWoodsplot4"=>"MN_NatRef_WolsfeldWoods","MN_WolsfieldWoodsplot5"=>"MN_NatRef_WolsfeldWoods","MN_Wood Rill SNA"=>"MN_NatRef_WoodRill","MN_Wood-Rill-Plot 1 and 3"=>"MN_NatRef_WoodRill","MN_Woodrillplot1"=>"MN_NatRef_WoodRill","MN_Woodrillplot3"=>"MN_NatRef_WoodRill","MN_X-1"=>"MN_AgRef_UMN","MN_X-28"=>"MN_AgRef_UMN","MN_X1"=>"MN_AgRef_UMN","MN_X28"=>"MN_AgRef_UMN"}, city_parcel, :city_parcel)
    change_names!({"BOS_Willowdaleforest"=>"BOS_WDF","BOS_WillowdaleForest"=>"BOS_WDF","BOS_WillowdalePasture"=>"BOS_WDP","BOS_BlueHillsForest"=>"BOS_BHF","BOS_BlueHillsPasture"=>"BOS_BHP","BOS_BlueHillsForest"=>"BOS_BHF","BOS_BlueHillsPasture"=>"BOS_BHP","PHX_AG 2"=>"PHX_Ag2","PHX_AG 1"=>"PHX_Ag1","BOS_MN"=>"BOS_MylesStandishPasture"#This exists because of the regex change two lines above
                  }, city_parcel, :city_parcel)
    change_names!({"BOS_MylesStandishForest"=>"BOS_MSF", "BOS_MylesStandishPasture"=>"BOS_MSP", "PHX_Estrella"=>"PHX_Estrellas", "PHX_"=>"PHX_Usery", "FL_1140"=>"FL_11400", "FL_11824"=>"FL_11823", "FL_17098"=>"FL_17089", "FL_5377"=>"FL_5733", "FL_Okee"=>"FL_Okeheelee", "FL_Okeeheelee"=>"FL_Okeheelee", "FL_Barnecle"=>"FL_Barnacle", "BA_Lot 21"=>"BA_V21", "BA_Lot 27"=>"BA_V27", "BA_ Lot 7"=>"BA_V07", "BA_V7"=>"BA_V07", "BA_Lot 7"=>"BA_V07", "BA_V-7"=>"BA_V07", "BA_V-21"=>"BA_V21", "BA_V-27"=>"BA_V27", "BA_Oregon Ridge 2"=>"BA_OR2", "BA_ORU 1"=>"BA_OR1", "BA_ORU1"=>"BA_OR1", "BA_ORU2"=>"BA_OR2", "BA_Leakin"=>"BA_LK2", "BA_Leakin Park"=>"BA_LK2", "BOS_15414"=>"BOS_15514", "MN_Cedar Creek_111"=>"MN_NatRef_CedarCreek", "MN_Helen Allison Savanna"=>"MN_NatRef_HelenAllison", "PHX_White Tanks"=>"PHX_WhiteTanks"}, city_parcel, :city_parcel)
    #Handle parcel area problems for parcel_area lookup
    city_parcel.insert :parcel
    city_parcel.data[:parcel] = city_parcel[:city_parcel].dup
    change_names_regex!({"[A-Za-z]_"=>""}, city_parcel, :parcel)
    
    ########################
    #Taxonomy###############
    ########################
    Dir.chdir orig_wd
    merger = merge_names([veg_survey, veg_transect, lawn_survey, iTree, leaves, leaf_surface_areas])
    veg_survey, veg_transect, lawn_survey, iTree, leaves, leaf_surface_areas = merger[0]
    taxonomy = merger[1]
    case
    when ARGV[2] == "0"
      puts "Ignoring taxonomy..."
    when (ARGV[2] == "1" or ARGV[2] == "2")
      puts "*WILL! STOP DOING THIS!*"
      if ARGV[2] == "1"
        puts "DOESN'T WORK. R script assumes it has a species input; using existing.."
        #puts "Calculating taxonomy..."
        #`R CMD BATCH taxonomy_cleaning.R`
      else
        puts "Using existing taxonomy..."
      end
      taxonomy.insert :sp_binomial_clean
      new_taxonomy = []
      curr_file = UniSheet.new "taxonomy.csv"
      curr_file.each do |line|
        new_taxonomy << line[2]
      end
      taxonomy.data[:sp_binomial_clean] = new_taxonomy
    else
      puts "ERROR! Nonsense taxonomy request, ignoring..."
    end
    
    ########################
    #Database writing#######
    ########################    
    puts "Writing database..."
    db.execute "CREATE TABLE iTree (cpp_index TEXT, tree_no TEXT, sp_index TEXT, sp_common TEXT, dbh TEXT, height TEXT, ground_area TEXT, condition TEXT, leaf_area TEXT, leaf_biomass TEXT, leaf_area_index TEXT, carbon_storage TEXT, gross_carbon_seq TEXT, money_value TEXT, street TEXT, native TEXT, parcel_area TEXT, impervious_parcel_area TEXT)"
    add_to_data_base(iTree, db, "iTree", nil)
    db.execute "CREATE TABLE VegSurvey (cpp_index TEXT, sp_common TEXT, sp_index TEXT, sp_native TEXT, location TEXT, cultivation TEXT, notes TEXT)"
    add_to_data_base(veg_survey, db, "VegSurvey", nil)
    db.execute "CREATE TABLE VegTransect (cpp_index TEXT, sp_index TEXT, transect TEXT)"
    add_to_data_base(veg_transect, db, "VegTransect", nil)  
    db.execute "CREATE TABLE LawnSurvey (cpp_index TEXT, sp_index TEXT, sp_common TEXT, location TEXT, abundance INT, transect TEXT)"
    add_to_data_base(lawn_survey, db, "LawnSurvey", nil)
    db.execute "CREATE TABLE PhoneSurvey (cpp_index TEXT, income TEXT, landuse TEXT, year_built TEXT, yard_type TEXT, income_survey TEXT, income_combined TEXT, density_level TEXT, income_level TEXT, north_south TEXT, east_west TEXT, floral_biodiversity TEXT, local_nature_provisioning TEXT, supporting_environmental_services TEXT, local_cultural_value TEXT, neat_aesthetic TEXT, appearance TEXT, low_maintenance TEXT, low_cost TEXT, veg_private TEXT, veg_food TEXT, veg_cool TEXT, veg_condit TEXT, veg_common TEXT, veg_legac TEXT, yrd_weeds TEXT, yrd_looks TEXT, yrd_enjoy TEXT, yrd_social TEXT, yrd_common TEXT, yrd_air TEXT, yrd_climate TEXT, yrd_green TEXT, veg_aest TEXT, veg_ease TEXT, veg_wldlf TEXT, veg_nativ TEXT, veg_neat TEXT, veg_cost TEXT, veg_kids TEXT, veg_pets TEXT, veg_hoa TEXT, yrd_divers TEXT, yrd_learn TEXT, yrd_beaut TEXT, yrd_values TEXT, yrd_cost TEXT, yrd_tradit TEXT, yrd_drain TEXT, yrd_ease TEXT, yrd_pollut TEXT, yrd_neat TEXT, yrd_soil TEXT, yrd_kids TEXT, yrd_pets TEXT, yrd_flwrs TEXT)"   
    add_to_data_base(phone_survey, db, "PhoneSurvey", nil)
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
    db.execute "CREATE TABLE LeafRaw (cpp_index TEXT, image_name TEXT, sp_index TEXT, raw_name TEXT, weight TEXT, height TEXT)"
    add_to_data_base(leaves, db, "LeafRaw", nil)
    db.execute "CREATE TABLE LeafMorphology (cpp_index TEXT, sp_index TEXT, image_name TEXT, seg_name TEXT, perimeter TEXT, surface_area TEXT, dissection TEXT, compactness TEXT)"
    add_to_data_base(leaf_surface_areas, db, "LeafMorphology", nil)
    db.execute "CREATE TABLE City_Parcel (city_parcel TEXT, cpp_index TEXT, orig_city_parcel TEXT, parcel TEXT)"
    add_to_data_base(city_parcel, db, "City_Parcel", nil)
    db.execute "CREATE TABLE MetaData (cpp_index TEXT, code TEXT, cat_one TEXT, cat_two TEXT, age TEXT, prev TEXT, meta_area TEXT)"
    add_to_data_base(metadata, db, "MetaData", nil)
    db.execute "CREATE TABLE ParcelArea (parcel TEXT, area_m2 TEXT)"
    add_to_data_base(parcel_areas, db, "ParcelArea", nil)

    ########################
    #Flat-files#############
    ########################
    #puts "\nWriting flat-files..."
    #`sqlite3 -batch -init sql.txt #{ARGV[0]}`
    
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
  puts "\tWhether to include microclimate data"
  puts "\t\t0 - Skip"
  puts "\t\t1 - Include (takes a while and has issues)"
end

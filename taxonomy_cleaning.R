#Setup; load from a (recent) dump of the taxonomy table
require(Taxonstand)
species <- read.csv("/home/will/Dropbox/homogenization/database/species.txt")
db.names <- species[,1]

#Basic pre-processing to remove sp., fix known fuck-ups, etc.
lookup <- data.frame(db.names, search.term=db.names, final.cut=rep(TRUE, length(db.names)))
lookup$search.term <- gsub(" sp.", "", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub(" spp.", "", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub("[0-9]*", "", lookup$search.term)
lookup$search.term <- gsub("#", "", lookup$search.term, fixed=TRUE)
lookup$search.term[grepl("hibiscus rosa-sinensis", lookup$search.term, fixed=TRUE)] <- "hibiscus rosa-sinesnsis"
lookup$search.term[lookup$search.term==" quercus rubra"] <- "quercus rubra"
lookup$search.term[lookup$search.term=="calyptocarpus  vialis_straggler daisy"] <- "calyptocarpus vialis"
lookup$search.term[lookup$search.term=="drymaria  cordata_west indian chickweed"] <- "drymaria cordata"
lookup$search.term[lookup$search.term=="dypsis  lutescens_areca palm"] <- "dypsis lutescens"
lookup$search.term[lookup$search.term=="eremochloa  ophiuroides"] <- "eremochloa ophiuroides"

#Pull out just the genera and species names
# - weird splits because apparently there're some character encoding issues
lookup$gen.search <- sapply(strsplit(lookup$search.term, ",|_| | "), function(x) x[1])
lookup$sp.search <- sapply(strsplit(lookup$search.term, ",|_| | "), function(x) x[2])
lookup$final.cut <- lookup$final.cut & lookup$gen.search != ""
lookup$final.cut <- lookup$final.cut & lookup$gen.search != "x"
lookup$final.cut <- lookup$final.cut & lookup$gen.search != "×"
genera.only <- unique(as.character(lookup$gen.search))

lookup$final.cut <- lookup$final.cut & lookup$sp.search != "x"
lookup$final.cut <- lookup$final.cut & !is.na(lookup$sp.search)
lookup$final.cut <- lookup$final.cut & lookup$sp.search != "×"
lookup$final.cut <- lookup$final.cut & lookup$sp.search != ""
lookup$final.cut <- lookup$final.cut & lookup$sp.search != "sp"
lookup$final.cut <- lookup$final.cut & lookup$sp.search != "cf"
lookup$final.cut <- lookup$final.cut & lookup$sp.search != "cf."
lookup$final.cut <- lookup$final.cut & lookup$sp.search != "cv."
lookup$final.cut <- lookup$final.cut & lookup$sp.search != "hybrid."
lookup$final.cut <- lookup$final.cut & lookup$sp.search != "."
lookup$final.cut <- lookup$final.cut & !duplicated(paste(lookup$gen.search, lookup$sp.search, sep="_"))
lookup$gen.search <- as.character(lookup$gen.search)
genera.only <- setdiff(genera.only, lookup$gen.search[lookup$final.cut==TRUE])

#Do the search
plant.list <- with(lookup[lookup$final.cut,], TPL(genus=gen.search, species=sp.search, corr=TRUE, infra=FALSE))
save.image("/home/will/Dropbox/homogenization/phylogeny/names.RData")

#Fill in the results of the search
lookup$tpl.binomial <- lookup$tpl.family <- lookup$tpl.genus <- rep("NA", nrow(lookup))
lookup$tpl.binomial[lookup$final.cut] <- with(plant.list, paste(as.character(New.Genus), as.character(New.Species), sep="_"))
lookup$tpl.genus[lookup$final.cut] <- with(plant.list, as.character(New.Genus))
lookup$tpl.family[lookup$final.cut] <- with(plant.list, as.character(Family))
lookup$tpl.authority [lookup$final.cut] <- with(plant.list, as.character(Authority))
#Now need to handle in the species with duplicate real names, but different database names
dups <- duplicated(lookup$sp.search)
for(i in seq(nrow(lookup))){
  if(dups[i]){
    which.searched <- which(lookup$sp.search==lookup$sp.search[i])[1]
    lookup$tpl.binomial[i] <- lookup$tpl.binomial[which.searched]
    lookup$tpl.genus[i] <- lookup$tpl.genus[which.searched]
    lookup$tpl.family[i] <- lookup$tpl.family[which.searched]
    lookup$tpl.authority[i] <- lookup$tpl.authority[which.searched]
  }
}
#Now need to handle genus-only entries
for(i in seq(nrow(lookup))){
  if(is.na(lookup$sp.search[i])){
    t.lookup <- lookup[lookup$gen.search == lookup$gen.search[i] & lookup$final.cut,]
    if(nrow(t.lookup) > 0){
      lookup$tpl.genus[i] <- t.lookup$tpl.genus[1]
      lookup$tpl.binomial[i] <- paste(lookup$tpl.genus[i], "unknown", sep="_")
      lookup$tpl.family[i] <- t.lookup$tpl.family[1]
      lookup$tpl.authority[i] <- "unknown"
    }
  }
}
#Manually handle the remaining genus-only measures we have nothing for...
# - slow, but easy to type!
# - found from lookup$db.names[lookup$gen.search %in% genera.only]
# - for the record, I think this is a very bad idea. Some of these could easily be hybrids, and we wouldn't know. I think the _unknowns should be stripped from the (phylogenetic) database
fix.entry <- function(table, db.sp, genus.name){
  table$tpl.genus[table$db.names==db.sp] <- genus.name
  table$tpl.binomial[table$db.names==db.sp] <- paste(genus.name, "unknown", sep="_")
  table$tpl.family[table$db.names==db.sp] <- "unknown"
  table$tpl.authority[table$db.names==db.sp] <- "unknown"
  return(table)
}
lookup <- fix.entry(lookup, "ageratum spp.", "ageratum")
lookup <- fix.entry(lookup, "araceae sp._", "araceae")
lookup <- fix.entry(lookup, "asilbe sp. 1", "asilbe")
lookup <- fix.entry(lookup, "baptisia spp.", "baptisia")
lookup <- fix.entry(lookup, "bromeliaceae sp._", "bromeliaceae")
lookup <- fix.entry(lookup, "cleome sp. 1", "cleome")
lookup <- fix.entry(lookup, "cortaderia cv.", "cortaderia")
lookup <- fix.entry(lookup, "cosmos spp.", "cosmos")
lookup <- fix.entry(lookup, "dahlia", "dahlia")
lookup <- fix.entry(lookup, "echeveria spp.", "echeveria")
lookup <- fix.entry(lookup, "gladiolus sp.", "gladiolus")
lookup <- fix.entry(lookup, "gladiolus sp. 1", "gladiolus")
lookup <- fix.entry(lookup, "gnapthalium sp._", "gnapthalium")
lookup <- fix.entry(lookup, "latania_", "latania")
lookup <- fix.entry(lookup, "lemna spp.", "lemna")
lookup <- fix.entry(lookup, "luzula sp.", "luzula")
lookup <- fix.entry(lookup, "lyonia cf.", "lyonia")
lookup <- fix.entry(lookup, "myosotis spp.", "myosotis")
lookup <- fix.entry(lookup, "narcissus sp. 1", "narcissus")
lookup <- fix.entry(lookup, "narcissus spp.", "narcissus")
lookup <- fix.entry(lookup, "nepetea sp.", "nepetea")
lookup <- fix.entry(lookup, "orchidaceae sp. #1_", "orchidaceae")
lookup <- fix.entry(lookup, "orchidaceae sp. #2_", "orchidaceae")
lookup <- fix.entry(lookup, "orchidaceae sp. #3_", "orchidaceae")
lookup <- fix.entry(lookup, "orchidaceae sp. #4_", "orchidaceae")
lookup <- fix.entry(lookup, "orchidaceae sp._", "orchidaceae")
lookup <- fix.entry(lookup, "osteospermum spp.", "osteospermum")
lookup <- fix.entry(lookup, "pelagonium sp. 1", "pelagonium")
lookup <- fix.entry(lookup, "petunia spp.", "petunia")
lookup <- fix.entry(lookup, "phaleonopsis sp._", "phaleonopsis")
lookup <- fix.entry(lookup, "philodendron sp. #1_", "philodendron")
lookup <- fix.entry(lookup, "philodendron sp. #2_", "philodendron")
lookup <- fix.entry(lookup, "philodendron spp.", "philodendron")
lookup <- fix.entry(lookup, "portea sp._", "portea")
lookup <- fix.entry(lookup, "scaevola spp.", "scaevola")
lookup <- fix.entry(lookup, "selaginella cf.", "selaginella")
lookup <- fix.entry(lookup, "selaginella spp.", "selaginella")
lookup <- fix.entry(lookup, "selenicereus  sp._", "selenicereus")
lookup <- fix.entry(lookup, "solanaceae sp._", "solanaceae")
lookup <- fix.entry(lookup, "spathiphyllum spp.", "spathiphyllum")
lookup <- fix.entry(lookup, "spathophyllum  sp._", "spathophyllum")
lookup <- fix.entry(lookup, "tricyrtis sp. 1", "tricyrtis")
lookup <- fix.entry(lookup, "trillium sp. 1", "trillium")
lookup <- fix.entry(lookup, "vriesea sp._", "vriesea")
lookup <- fix.entry(lookup, "zinia sp.", "zinia")

#Write it out!
write.csv(lookup, "/home/will/Dropbox/homogenization/database/taxonomy.csv")

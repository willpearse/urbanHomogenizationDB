#Setup; load from a (recent) dump of the taxonomy table
require(Taxonstand)
require(testdat)
species <- read.csv("species_dump.csv")
db.names <- as.character(species[,1])

#Basic pre-processing to remove sp., fix character encoding, etc.
lookup <- data.frame(db.names, search.term=db.names, final.cut=rep(TRUE, length(db.names)))
lookup$search.term <- gsub(" sp.", "", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub(" spp.", "", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub("[0-9]*", "", lookup$search.term)
lookup$search.term <- gsub("#", "", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub("cult.", "", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub("_", " ", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub(".", " ", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub("+", " ", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub(" ", " ", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub("  ", " ", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub("  ", " ", lookup$search.term, fixed=TRUE)
lookup$search.term <- gsub(" × ", " x ", lookup$search.term, fixed=TRUE)
lookup$search.term <- sanitize_text(lookup$search.term)


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
plant.list <- with(lookup[lookup$final.cut,], TPL(splist=paste(gen.search, sp.search)))

#save.image("names.RData")

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

#Write it out!
output <- data.frame(seq(nrow(lookup)), lookup$db.names, lookup$tpl.binomial)
write.csv(output, "taxonomy.csv", row.names=FALSE, col.names=FALSE, quote=FALSE)

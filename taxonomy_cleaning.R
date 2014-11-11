#Setup; load from the SQL of the taxonomy table
require(RSQLite)
require(Taxonstand)
require(testdat)
require(willeerd)
require(ape)

handle <- dbConnect(dbDriver("SQLite"), dbname="~/Dropbox/homogenization/urbanHomogenizationDB/v4.db")
t <- dbSendQuery(handle, "SELECT * FROM Taxonomy")
species <- fetch(t, n=-1)
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
lookup$search.term <- gsub("^[ ]*", "", lookup$search.term)
lookup$search.term <- gsub("[ ]*$", "", lookup$search.term)
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
plant.list <- with(lookup[lookup$final.cut,], TPL(splist=paste(gen.search, sp.search), corr=TRUE))
lookup$search.term <- with(lookup, paste(gen.search, sp.search))
#save.image("names.RData")

#Fill in species that weren't searched because their search.term was a duplicated
lookup$tpl.binomial <- NA
lookup$tpl.binomial[lookup$final.cut] <- with(plant.list, paste(as.character(New.Genus), as.character(New.Species), sep="_"))
dups <- duplicated(lookup$sp.search)
for(i in seq(nrow(lookup))){
  if(dups[i]){
    which.searched <- which(lookup$search.term==lookup$search.term[i])[1]
    lookup$tpl.binomial[i] <- lookup$tpl.binomial[which.searched]
  }
}

#Sadly, now I have to go through and add-in genus_sp as something, because otherwise we lose a metric fuck-tonne of species
# - I'm going to assume that, if someone couldn't spell the genus properly, they're a complete moron and should be ignored
lookup$tpl.binomial <- ifelse(lookup$final.cut==FALSE & (lookup$sp.search=="sp"|lookup$sp.search=="spp"|lookup$sp.search==""|is.na(lookup$sp.search)), paste(lookup$gen.search,"sp",sep="_"), lookup$tpl.binomial)

#Writing out
output <- data.frame(seq(nrow(lookup))-1, lookup$db.names, lookup$tpl.binomial)
output <- as.matrix(output)
colnames(output) <- NULL
rownames(output) <- NULL
write.table(output, "~/Dropbox/homogenization/urbanHomogenizationDB/taxonomy.csv", row.names=FALSE, col.names=FALSE, quote=FALSE, sep=",")

#Let's build us a phylogeny
tree <- read.tree("~/Dropbox/SESYNC.Macroevolution.ES.Trees/Phylos/Tank(Zanne)Tree/Vascular_Plants_rooted.dated.tre")
tree$node.label <- NULL
spp <- unique(lookup$tpl.binomial)
spp <- spp[!is.na(spp)]
tree <- congeneric.merge(spp, tree)
tree <- drop.tip(tree, setdiff(tree$tip.label, spp))
write.tree(tree, "~/Dropbox/homogenization/urbanHomogenizationDB/phylogeny.tre")


Urban Homogenization database generator
============================================
Will Pearse (wdpearse@umn.edu)

##Overview
This is intended to put together the urban homogenization database from the files available on the University of Minnesota server. It's not going to work with any other file structure.
You may find the internal classes and functions useful in your own programs. If you do, go ahead and use them. You owe me a beer though!

##Requirements
* Ruby >= 1.9 (with gems: RubyXL, spreadsheet, minitest)
* SQLite3

##Notes
* Run each of the files in 'lib' with something like 'ruby DataFrame.rb' to conduct the unit tests
* Build the database with something like 'ruby output.db /path/to/directory'.
* I've not put details on where the data server is deliberately. If you're on the project, you're of course welcome to a copy of the data (!...!) - just send me an email.

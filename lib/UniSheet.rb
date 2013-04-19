# Author::    Will Pearse  (mailto:wdpearse@umn.edu)
# Date::  2/28/2013
require 'csv'
require 'spreadsheet'
require 'rubyXL'

#Allows loading and iterating over Excel (xls and xlsx) and CSV files
#without requiring the user to know what kind of file they're opening.
#Poorly tested, and doesn't attempt to handle exceptions thrown from
#underlying classes (e.g., file not found errors)
class UniSheet
  #Getters
  attr_reader :file_name, :file_type
  
  #Give it a filename, and it will auto-detect what the file format is.
  #Otherwise, give it a filetype as a second argument "xls, xlxs, csv, etc."
  #Doesn't guarantee lazy evaluation *ever*
  def initialize(file_name, file_type=nil)
    #Detect filetype if not given
    @file_name = file_name
    if not file_type
      if file_name[".csv"]
        @file_type = "csv"
        @csv = CSV.read @file_name
        return @file_type
      elsif file_name[".xlsx"]
        @xlsx_book = RubyXL::Parser.parse file_name
        @xlsx_sheet = @xlsx_book.worksheets[0].extract_data
        @file_type = "xlsx"
        #Do our best not to get extra folders popping up all over the place
        #sleep 1
        return @file_type
      elsif file_name[".xls"]
        @excel_book = Spreadsheet.open file_name
        @excel_sheet = @excel_book.worksheet 0
        @file_type = "xls"
        return @file_type
      else
        raise RuntimeError, "File #{file_name} of undetectable or unsupported filetype"
      end
    end
    @file_type = file_type
    return @file_type
  end
  
  #Iterator
  def each(&block)
    case
    when @file_type=="csv"
      @csv.each(&block)
    when @file_type=="xls"
      @excel_sheet.each(&block)
    when @file_type=="xlsx"
      @xlsx_sheet.each(&block)
    else
      raise RuntimeError, "File #{@file_name} used in improperly defined UniSheet class"
    end
  end
  
  #Pull out a row; returns an array so columns can also be called in this way
  def [](index)
    case
    when @file_type=="csv"
      return @csv[index]
    when @file_type=="xls"
      return @excel_sheet.row(index).to_a
    when @file_type=="xlsx"
      return @xlsx_sheet[index]
    else
      raise RuntimeError, "File #{@file_name} used in improperly defined UniSheet class"
    end
  end
  
  #Change sheet if xls or xlsx file
  def set_sheet(sheet)
    if @file_type == "xls"
      @excel_sheet = @excel_book.workseet sheet
    elsif @file_type == "xlsx"
      @xlsx_sheet = @xlsx_book.worksheets[0]
    else
      raise RuntimeError, "File #{@file_name} is not an xls or xlsx file, so cannot change sheet" 
    end
  end 
end

#Run tests if we're just running this script from the command line
if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  describe UniSheet do
    before do
      @csv_test = UniSheet.new "test_files/dataFrame.csv"
      @xls_test = UniSheet.new "test_files/dataFrame.xls"
      @xlsx_test = UniSheet.new "test_files/dataFrame.xlsx"
    end
    describe "When loading a CSV file" do
      it "Will iterate correctly" do
        temp = []
        @csv_test.each {|line| temp << line[0]}
        assert_equal ["Name", "John Ward", "Tom Ensom"], temp
      end
      it "Will load a row correctly" do
        @csv_test[0].must_equal ["Name", "Emailed?", "Confirmed?", "Emailed Re. Payment?","Paid?"]
      end
      it "Doesn't have sheets" do
        proc {@csv_test.set_sheet(1)}.must_raise RuntimeError
      end
    end
    describe "When loading an XLS file" do
      it "Will iterate correctly" do
        temp = []
        @xls_test.each {|line| temp << line[0]}
        assert_equal ["Name", "John Ward", "Tom Ensom"], temp
      end
      it "Will load a row correctly" do
        @xls_test[0].must_equal ["Name", "Emailed?", "Confirmed?", "Emailed Re. Payment?","Paid?"]
      end
    end
    describe "When loading an XLSX file" do
      it "Will iterate correctly" do
        temp = []
        @xlsx_test.each {|line| temp << line[0]}
        assert_equal ["Name", "John Ward", "Tom Ensom"], temp
      end
      it "Will load a row correctly" do
        @xlsx_test[0].must_equal ["Name", "Emailed?", "Confirmed?", "Emailed Re. Payment?","Paid?"]
      end
      it "Doesn't just have to go on the filename for file type" do
        @trick = UniSheet.new("test_files/dataFrameXLSTrick.csv", "xls")
        temp = []
        @xls_test.each {|line| temp << line[0]}
        assert_equal ["Name", "John Ward", "Tom Ensom"], temp
      end
    end
  end
end

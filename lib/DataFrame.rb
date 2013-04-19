#Helper function to check all members of a Hash have the same length
module HashHelpers
  def self.equal_length(hash)
    hash_length = []
    hash.each {|key, value| hash_length << value.length}
    if hash_length.uniq.length == 1
      return hash_length[0]
    else
      return false
    end
  end
end

#Class to hold data; guarantees all elements will be of same length
#Has no pretty printing, and only basic equality checking
#Read/write access to the data isn't properly setup, and fixing it may break parts of ProcessingData.rb
class DataFrame
  include HashHelpers
  #Getters
  attr_reader :nrow, :ncol, :col_names, :data
  
  #Initialize with a hash
  def initialize(input_hash)
    #Assert that input object is compatible
    unless input_hash.is_a? Hash then raise RuntimeError, "Must create a DataFrame with a Hash" end 
    unless HashHelpers.equal_length(input_hash) then raise RuntimeError, "Cannot add a hash with unequal element lengths to a data_base" end
    
    #Setup parameters
    @data = input_hash
    @nrow = HashHelpers.equal_length(input_hash)
    @ncol = @data.keys.length
    @col_names = @data.keys
  end
  
  #Copy constructor
  def initialize_copy(orig)
    #Can't do this using .dup or you won't copy the arrays within the hash...
    @data = Marshal::load(Marshal.dump(@data))
    @nrow = @nrow
    @ncol = @ncol
    @col_names = @col_names.dup
  end
  
  #Wrapper for individual columns
  def [](element)
    return self.data[element]
  end
  
  #Insert new column
  def insert(column)
    if @col_names.include? column then raise RuntimeError, "Cannot add a column whose name is already taken in DataFrame" end
    @data[column] = [''] * @nrow
    @ncol += 1
    @col_names.push column
    return column
  end
  
  #Delete a column
  def delete(column)
    if !@col_names.include? column then raise RuntimeError, "Attempting to remove non-existant column from DataFrame" end
    @data.delete(column)
    @ncol -= 1
    @col_names = @col_names - [column]
    return column
  end
  
  #Append a DataFrame or Hash
  def <<(binder)
    if binder.is_a? DataFrame
      unless self.data.keys.sort == binder.data.keys.sort then raise RuntimeError, "Cannot merge DataFrames with non-matching columns" end
      binder.data.each {|key, value| @data[key] += value}
      @nrow += HashHelpers.equal_length(binder.data)
    elsif binder.is_a? Hash
      unless self.data.keys.sort == binder.keys.sort then raise RuntimeError, "Cannot merge DataFrame and Hash with non-matching elements" end
      unless HashHelpers.equal_length(binder) then raise RuntimeError, "Cannot merge DataFrame with non-equal-length Hash" end
      binder.each {|key, value| @data[key] += value}
      @nrow += HashHelpers.equal_length(binder)
    else
      raise RuntimeError, "Can only merge DataFrame with a DataFrame or Hash"
    end
    return @nrow
  end
  
  #Equality checking
  def ==(comparison)
    if comparison.is_a? DataFrame and self.data == comparison.data and self.nrow == comparison.nrow and self.ncol == comparison.ncol and self.col_names == comparison.col_names
      return true
    else
      return false
    end
  end
          
  #Iterator for columns
  def each_column
    @data.each do |column, value|
      yield column, value
    end
  end
  
  #Iterator for rows
  def each_row
    (0...@nrow).each do |i|
      yield @data.keys.map {|x| @data[x][i]}
    end
  end
end

#Run tests if we're running this from the command line
if File.identical?(__FILE__, $PROGRAM_NAME)
  require 'minitest/spec'
  require 'minitest/autorun'
  
  describe HashHelpers do
    it "Returns the length of equally-lengthed hashes" do
      assert HashHelpers.equal_length({:a=>[1,2,3], :b=>["a", "v", "a"]}) == 3
      assert HashHelpers.equal_length({:a=>[], :b=>[]}) == 0
    end
    it "Returns false for unequal length hashes" do
      assert HashHelpers.equal_length({:a=>[1,2,3], :b=>["a", "a"]}) == false
    end
  end
  
  describe DataFrame do
    it "Initialises with a Hash" do
      temp = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      assert temp.data == {:a=>[1, 2, 3], :b=>["a", "v", "a"]}
      assert temp.nrow == 3
      assert temp.ncol == 2
      assert_raises(RuntimeError) {DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a", "d"]})}
    end
    it "Appends rows from a DataFrame or Hash" do
      first = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      second = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      first << second
      assert first.data == {:a=>[1, 2, 3, 1, 2, 3], :b=>["a", "v", "a", "a", "v", "a"]}
      assert first.nrow == 6
      second << {:a=>[1,2,3], :b=>["a", "v", "a"]}
      assert second.data == {:a=>[1, 2, 3, 1, 2, 3], :b=>["a", "v", "a", "a", "v", "a"]}
      assert second.nrow == 6
    end
    it "Allows access to columns" do
      first = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      assert first[:a] == [1,2,3]
    end
    it "Iterates columns" do 
      columns = []; values = []
      first = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      first.each_column  do |x,y|
        y.each do |z|
          columns << x
          values << z
        end
      end
      assert columns == [:a, :a, :a, :b, :b, :b]
      assert values == [1, 2, 3, "a", "v", "a"]
    end
    it "Iterates rows" do
      x = []; y = []
      first = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      first.each_row  do |a,b|
        x << a
        y << b
      end
      assert x == [1, 2, 3]
      assert y == ["a", "v", "a"]
      merged = []
      first.each_row  {|x| merged << x}
      assert merged == [[1, "a"], [2, "v"], [3, "a"]]
    end
    it "Checks for equality" do
      assert DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]}) == DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      assert DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]}) != DataFrame.new({:a=>[1,2,3,4], :b=>["a", "v", "a", "b"]})
    end
    it "Adds columns" do 
      first = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      first.insert :test
      assert first.nrow == 3
      assert first.ncol == 3
      assert first[:test] == ['', '', '']
    end
    it "Delete columns" do
      first = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      first.delete :a
      assert first.nrow == 3
      assert first.ncol == 1
    end
    it "Has a copy constructor" do
      first = DataFrame.new({:a=>[1,2,3], :b=>["a", "v", "a"]})
      second = first.dup
      second[:a][0] = "asd"
      second.delete :a
      second.col_names[1] = "derp"
      assert first[:a][0] != "asd"
      assert first.ncol == 2
    end
  end
end
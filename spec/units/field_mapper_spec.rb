require 'spec_helper'

describe Solrizer::FieldMapper do
  
  # --- Test Mappings ----
  
  class TestMapper0 < Solrizer::FieldMapper
    id_field 'ident'
    index_as :searchable, :suffix => '_s',    :default => true
    index_as :edible,     :suffix => '_food'
    index_as :laughable,  :suffix => '_haha', :default => true do |type|
      type.integer :suffix => '_ihaha' do |value, field_name|
        "How many #{field_name}s does it take to screw in a light bulb? #{value.capitalize}."
      end
      type.default do |value|
        "Knock knock. Who's there? #{value.capitalize}. #{value.capitalize} who?"
      end
    end
    index_as :fungible, :suffix => '_f0' do |type|
      type.integer :suffix => '_f1'
      type.date
      type.default :suffix => '_f2'
    end
    index_as :unstemmed_searchable, :suffix => '_s' do |type|
      type.date do |value|
        "#{value} o'clock"
      end
    end
  end
  
  class TestMapper1 < TestMapper0
    index_as :searchable do |type|
      type.date :suffix => '_d'
    end
    index_as :fungible, :suffix => '_f3' do |type|
      type.garble  :suffix => '_f4'
      type.integer :suffix => '_f5'
    end
  end
  
  before(:each) do
    @mapper = TestMapper0.new
  end
  
  after(:all) do
  end
  
  # --- Tests ----
  
  it "should handle the id field" do
    @mapper.id_field.should == 'ident'
  end
  
  describe '.solr_name' do
    it "should map based on index_as" do
      @mapper.solr_name('bar', :string, :edible).should == 'bar_food'
      @mapper.solr_name('bar', :string, :laughable).should == 'bar_haha'
    end

    it "should default the index_type to :searchable" do
      @mapper.solr_name('foo', :string).should == 'foo_s'
    end
    
    it "should map based on data type" do
      @mapper.solr_name('foo', :integer, :fungible).should == 'foo_f1'
      @mapper.solr_name('foo', :garble,  :fungible).should == 'foo_f2'  # based on type.default
      @mapper.solr_name('foo', :date,    :fungible).should == 'foo_f0'  # type.date falls through to container
    end
  
    it "should return nil for an unknown index types" do
      silence do
        @mapper.solr_name('foo', :string, :blargle).should == nil
      end
    end
    
    it "should allow subclasses to selectively override suffixes" do
      @mapper = TestMapper1.new
      @mapper.solr_name('foo', :date).should == 'foo_d'   # override
      @mapper.solr_name('foo', :string).should == 'foo_s' # from super
      @mapper.solr_name('foo', :integer, :fungible).should == 'foo_f5'  # override on data type
      @mapper.solr_name('foo', :garble,  :fungible).should == 'foo_f4'  # override on data type
      @mapper.solr_name('foo', :fratz,   :fungible).should == 'foo_f2'  # from super
      @mapper.solr_name('foo', :date,    :fungible).should == 'foo_f3'  # super definition picks up override on index type
    end
    
    it "should support field names as symbols" do
      @mapper.solr_name(:active_fedora_model, :symbol).should == "active_fedora_model_s"
    end
    
    it "should support scenarios where field_type is nil" do
      mapper = Solrizer::FieldMapper::Default.new
      mapper.solr_name(:heifer, nil, :searchable).should == "heifer_t"
    end
  end
  
  describe '.solr_names_and_values' do
    it "should map values based on index_as" do
      @mapper.solr_names_and_values('foo', 'bar', :string, [:searchable, :laughable, :edible]).should == {
        'foo_s'    => ['bar'],
        'foo_food' => ['bar'],
        'foo_haha' => ["Knock knock. Who's there? Bar. Bar who?"]
      }
    end
    
    it "should apply default index_as mapping unless excluded with not_" do
      @mapper.solr_names_and_values('foo', 'bar', :string, []).should == {
        'foo_s' => ['bar'],
        'foo_haha' => ["Knock knock. Who's there? Bar. Bar who?"]
      }
      @mapper.solr_names_and_values('foo', 'bar', :string, [:edible, :not_laughable]).should == {
        'foo_s' => ['bar'],
        'foo_food' => ['bar']
      }
      @mapper.solr_names_and_values('foo', 'bar', :string, [:not_searchable, :not_laughable]).should == {}
    end
  
    it "should apply mappings based on data type" do
      @mapper.solr_names_and_values('foo', 'bar', :integer, [:searchable, :laughable]).should == {
        'foo_s'     => ['bar'],
        'foo_ihaha' => ["How many foos does it take to screw in a light bulb? Bar."]
      }
    end
    
    it "should skip unknown index types" do
      silence do
        @mapper.solr_names_and_values('foo', 'bar', :string, [:blargle]).should == {
          'foo_s' => ['bar'],
          'foo_haha' => ["Knock knock. Who's there? Bar. Bar who?"]
        }
      end
    end
    
    it "should generate multiple mappings when two return the _same_ solr name but _different_ values" do
      @mapper.solr_names_and_values('roll', 'rock', :date, [:unstemmed_searchable, :not_laughable]).should == {
        'roll_s' => ["rock o'clock", 'rock']
      }
    end
    
    it "should not generate multiple mappings when two return the _same_ solr name and the _same_ value" do
      @mapper.solr_names_and_values('roll', 'rock', :string, [:unstemmed_searchable, :not_laughable]).should == {
        'roll_s' => ['rock'],
      }
    end
  end

  describe "#load_mappings" do 
    before(:each) do
      class TestMapperLoading < Solrizer::FieldMapper
      end
    end
    it "should take mappings file as an optional argument" do
      file_path = File.join(File.dirname(__FILE__), "..", "fixtures","test_solr_mappings.yml")
  	  TestMapperLoading.load_mappings(file_path)
  	  mapper = TestMapperLoading.new
      mappings_from_file = YAML::load(File.open(file_path))
      mapper.id_field.should == "pid"
      mapper.mappings[:edible].opts[:default].should == true
      mapper.mappings[:edible].data_types[:boolean].opts[:suffix].should == "_edible_bool"
      mappings_from_file["edible"].each_pair do |k,v|
        mapper.mappings[:edible].data_types[k.to_sym].opts[:suffix].should == v        
      end
      mapper.mappings[:displayable].opts[:suffix].should == mappings_from_file["displayable"]
      mapper.mappings[:facetable].opts[:suffix].should == mappings_from_file["facetable"]
      mapper.mappings[:sortable].opts[:suffix].should == mappings_from_file["sortable"]
	  end
	  it 'should default to using the mappings from config/solr_mappings.yml' do
	    TestMapperLoading.load_mappings
  	  mapper = TestMapperLoading.new
  	  default_file_path = File.join(File.dirname(__FILE__), "..", "..","config","solr_mappings.yml")
      mappings_from_file = YAML::load(File.open(default_file_path))
      mapper.id_field.should == mappings_from_file["id"]
      mappings_from_file["searchable"].each_pair do |k,v|
        mapper.mappings[:searchable].data_types[k.to_sym].opts[:suffix].should == v        
      end
      mapper.mappings[:displayable].opts[:suffix].should == mappings_from_file["displayable"]
      mapper.mappings[:facetable].opts[:suffix].should == mappings_from_file["facetable"]
      mapper.mappings[:sortable].opts[:suffix].should == mappings_from_file["sortable"]
    end
    it "should wipe out pre-existing mappings without affecting other FieldMappers" do
      TestMapperLoading.load_mappings
      file_path = File.join(File.dirname(__FILE__), "..", "fixtures","test_solr_mappings.yml")
  	  TestMapperLoading.load_mappings(file_path)
  	  mapper = TestMapperLoading.new
  	  mapper.mappings[:searchable].should be_nil
  	  default_mapper = Solrizer::FieldMapper::Default.new
  	  default_mapper.mappings[:searchable].should_not be_nil
  	end
  	it "should raise an informative error if the yaml file is structured improperly"
  	it "should raise an informative error if there is no YAML file"
	end
  
  describe Solrizer::FieldMapper::Default do
    before(:each) do
      @mapper = Solrizer::FieldMapper::Default.new
    end
  	
    it "should call the id field 'id'" do
      @mapper.id_field.should == 'id'
    end
    
    it "should not apply mappings for searchable by default" do
      # Just sanity check a couple; copy & pasting all data types is silly
      @mapper.solr_names_and_values('foo', 'bar', :string, []).should == {  }
      @mapper.solr_names_and_values('foo', "1", :integer, []).should == { }
    end

    it "should support full ISO 8601 dates" do
      @mapper.solr_names_and_values('foo', "2012-11-06",              :date, [:searchable]).should == { 'foo_dt' =>["2012-11-06T00:00:00Z"] }
      @mapper.solr_names_and_values('foo', "November 6th, 2012",      :date, [:searchable]).should == { 'foo_dt' =>["2012-11-06T00:00:00Z"] }
      @mapper.solr_names_and_values('foo', Date.parse("6 Nov. 2012"), :date, [:searchable]).should == { 'foo_dt' =>["2012-11-06T00:00:00Z"] }
      @mapper.solr_names_and_values('foo', '', :date, [:searchable]).should == { 'foo_dt' => [] }
    end
    
    it "should support displayable, facetable, sortable, unstemmed" do
      @mapper.solr_names_and_values('foo', 'bar', :string, [:searchable, :displayable, :facetable, :sortable, :unstemmed_searchable]).should == {
        'foo_t' => ['bar'],
        'foo_display' => ['bar'],
        'foo_facet' => ['bar'],
        'foo_sort' => ['bar'],
        'foo_unstem_search' => ['bar'],
      }
    end
  end
  
  def silence
    old_level = @mapper.logger.level
    @mapper.logger.level = 100
    begin
      yield
    ensure
      @mapper.logger.level = old_level
    end
  end
end

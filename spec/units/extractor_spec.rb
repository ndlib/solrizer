require 'spec_helper'

describe Solrizer::Extractor do
  
  before(:all) do
    @extractor = Solrizer::Extractor.new
  end
  
  describe ".format_node_value" do
    it "should strip white space out of the array and join it with a single blank" do
      Solrizer::Extractor.format_node_value([" test    \n   node    \t value \t"]).should == "test node value"
      Solrizer::Extractor.format_node_value([" test ", "     \n   node ", "   \t value \t"]).should == "test node value"
    end
    it "should return an empty string if given an argument of nil" do
      Solrizer::Extractor.format_node_value(nil).should == ""
    end

    it "should strip white space out of a string" do
      Solrizer::Extractor.format_node_value("raw  string\n with whitespace").should == "raw string with whitespace"
    end
  end

  describe "#insert_solr_field_value" do
    it "should initialize a solr doc field as an Array if it is nil" do
       solr_doc = {'my_field' => nil }
       Solrizer::Extractor.insert_solr_field_value(solr_doc, 'my_field', 'Frank')
       solr_doc['my_field'].should == ['Frank']
    end
    it "should add a new value to an Array rather than overwriting an existing value" do
      solr_doc = {'my_field' => ['Frank'] }
      Solrizer::Extractor.insert_solr_field_value(solr_doc, 'my_field', 'Bing')
      solr_doc['my_field'].should == ['Frank', 'Bing']
    end
    it "should call format_node_value to normalize value" do
      Solrizer::Extractor.should_receive(:format_node_value).once
      Solrizer::Extractor.insert_solr_field_value({}, 'my_field', "value")
    end
  end
  
end

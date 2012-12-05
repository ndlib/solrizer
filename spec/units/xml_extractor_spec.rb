require 'spec_helper'

describe Solrizer::XML::Extractor do
  
  before(:all) do
    @extractor = Solrizer::Extractor.new
  end
  
  describe ".xml_to_solr" do
    it "should turn simple xml into a solr document" do
      desc_meta = fixture("druid-bv448hq0314-descMetadata.xml")

      result = @extractor.xml_to_solr(desc_meta)
      result[:type_teim].should == "text"
      result[:medium_teim].should == "Paper Document"
      result[:rights_teim].should == "Presumed under copyright. Do not publish."
      result[:date_teim].should == "1985-12-30"
      result[:format_teim].should be_kind_of(Array)
      result[:format_teim].should include("application/tiff")
      result[:format_teim].should include("application/pdf")
      result[:format_teim].should include("application/jp2000")
      result[:title_teim].should == "This is a Sample Title"
      result[:publisher_teim].should == "Sample Unversity"
    end
  end
  
end

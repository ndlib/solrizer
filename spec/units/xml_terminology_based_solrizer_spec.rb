require 'spec_helper'
require 'fixtures/mods_article'

describe Solrizer::XML::TerminologyBasedSolrizer do
  
  before(:all) do
    Samples::ModsArticle.send(:include, Solrizer::XML::TerminologyBasedSolrizer)
  end
  
  before(:each) do
    article_xml = fixture( File.join("mods_articles", "hydrangea_article1.xml") )
    @mods_article = Samples::ModsArticle.from_xml(article_xml)
  end
  
  describe ".to_solr" do
  
    it "should provide .to_solr and return a SolrDocument" do
      @mods_article.should respond_to(:to_solr)
      @mods_article.to_solr.should be_kind_of(Hash)
    end
  
    it "should optionally allow you to provide the Hash to add fields to and return that document when done" do
      doc = Hash.new
      @mods_article.to_solr(doc).should equal(doc)
    end
  
    it "should iterate through the terminology terms, calling .solrize_term on each and passing in the solr doc" do
      solr_doc = Hash.new
      @mods_article.field_mapper = Solrizer::FieldMapper::Default.new
      Samples::ModsArticle.terminology.terms.each_pair do |k,v|
        @mods_article.should_receive(:solrize_term).with(v, solr_doc, @mods_article.field_mapper)
      end
      @mods_article.to_solr(solr_doc)
    end
  
    it "should use Solr mappings to generate field names" do

      solr_doc =  @mods_article.to_solr
      solr_doc["abstract"].should be_nil
      solr_doc["abstract_t"].should == ["ABSTRACT"]
      solr_doc["title_info_1_language_t"].should == ["finnish"]
      solr_doc["person_1_role_0_text_t"].should == ["teacher"]
      # No index_as on the code field.
      solr_doc["person_1_role_0_code_t"].should be_nil 
      solr_doc["person_last_name_t"].sort.should == ["FAMILY NAME", "Gautama"]
      solr_doc["topic_tag_t"].sort.should == ["CONTROLLED TERM", "TOPIC 1", "TOPIC 2"]
      
      # These are a holdover from an old verison of OM
      solr_doc['journal_0_issue_0_publication_date_dt'].should == ["2007-02-01T00:00:00Z"]

      
    end
    
  end

  describe ".solrize_term" do
  
    it "should add fields to a solr document for all nodes corresponding to the given term and its children" do
      solr_doc = Hash.new
      result = @mods_article.solrize_term(Samples::ModsArticle.terminology.retrieve_term(:title_info), solr_doc)
      result.should == solr_doc
    end

    it "should add multiple fields based on index_as" do
      fake_solr_doc = {}
      term = Samples::ModsArticle.terminology.retrieve_term(:name)
      term.children[:namePart].index_as = [:searchable, :displayable, :facetable]

      @mods_article.solrize_term(term, fake_solr_doc)
      
      expected_names = ["DR.", "FAMILY NAME", "GIVEN NAMES"]
      %w(_t _display _facet).each do |suffix|
        actual_names = fake_solr_doc["name_0_namePart#{suffix}"].sort
        {suffix => actual_names}.should == {suffix => expected_names}
      end
    end

    it "should add fields based on type using proxy" do
      unless RUBY_VERSION.match("1.8.7")
        solr_doc = Hash.new
        result = @mods_article.solrize_term(Samples::ModsArticle.terminology.retrieve_term(:pub_date), solr_doc)
        solr_doc["pub_date_dt"].should == ["2007-02-01T00:00:00Z"]
      end
    end

    it "should add fields based on type using ref" do
      solr_doc = Hash.new
      result = @mods_article.solrize_term(Samples::ModsArticle.terminology.retrieve_term(:issue_date), solr_doc)
      solr_doc["issue_date_dt"].should == ["2007-02-15T00:00:00Z"]
    end

    it "shouldn't index terms where index_as is an empty array" do
      fake_solr_doc = {}
      term = Samples::ModsArticle.terminology.retrieve_term(:name)
      term.children[:namePart].index_as = []

      @mods_article.solrize_term(term, fake_solr_doc)
      fake_solr_doc["name_0_namePart_t"].should be_nil
    end

    it "shouldn't index terms where index_as is searchable" do
      fake_solr_doc = {}
      term = Samples::ModsArticle.terminology.retrieve_term(:name)
      term.children[:namePart].index_as = [:searchable]

      @mods_article.solrize_term(term, fake_solr_doc)
      
      fake_solr_doc["name_0_namePart_t"].sort.should == ["DR.", "FAMILY NAME", "GIVEN NAMES"]
    end
    
  end

  describe ".solrize_node" do
    it "should optionally allow you to provide the Hash to add fields to and return that document when done"
    it "should create a solr field containing node.text"
    it "should create hierarchical field entries if parents is not empty"
    it "should only create one node if parents is empty"
  end

end

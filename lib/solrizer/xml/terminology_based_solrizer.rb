# This module is only suitable to mix into Classes that use the OM::XML::Document Module
module Solrizer::XML::TerminologyBasedSolrizer
  
  # Module Methods
  
  # Build a solr document from +doc+ based on its terminology
  # @doc  OM::XML::Document
  # @solr_doc (optional) Solr::Document to populate
  def self.solrize(doc, solr_doc=Solr::Document.new)
    unless doc.class.terminology.nil?
      doc.class.terminology.terms.each_pair do |term_name,term|
        doc.solrize_term(term, solr_doc)     
        # self.solrize_by_term(accessor_name, accessor_info, :solr_doc=>solr_doc)
      end
    end

    return solr_doc
  end
  
  # Populate a solr document with fields based on nodes in +xml+ corresponding to the 
  # term identified by +term_pointer+ within +terminology+
  # @doc OM::XML::Document or Nokogiri::XML::Node
  # @term_pointer Array pointing to the desired term in +terminology+  
  def self.solrize_term(doc, term, solr_doc = Solr::Document.new, opts={})
    terminology = doc.class.terminology
    parents = opts.fetch(:parents, [])

    term_pointer = parents+[term.name]
  
    # term = terminology.retrieve_term(term_pointer)

    # prep children hash
    # child_accessors = accessor_info.fetch(:children, {})
    # xpath = term.xpath_for(*term_pointer)
    nodeset = doc.find_by_terms(*term_pointer)
    
    nodeset.each do |node|
      # create solr fields
      
      self.solrize_node(node, doc, term_pointer, term, solr_doc)
      term.children.each_pair do |child_term_name, child_term|
        doc.solrize_term(child_term, solr_doc, opts={:parents=>parents+[{term.name=>nodeset.index(node)}]})
        # self.solrize_term(doc, child_term_name, child_term, opts={:solr_doc=>solr_doc, :parents=>parents+[{accessor_name=>nodeset.index(node)}] })
      end
    end
    solr_doc
  end
  
  # Populate a solr document with solr fields corresponding to the given xml node
  # Field names are generated using settings from the term in the +doc+'s terminology corresponding to +term_pointer+
  # @doc OM::XML::Document or Nokogiri::XML::Node
  # @term_pointer Array pointing to the desired term in +terminology+
  # @solr_doc (optional) Solr::Document to populate
  def self.solrize_node(node, doc, term_pointer, term, solr_doc = Solr::Document.new)
    terminology = doc.class.terminology
    # term = terminology.retrieve_term(*term_pointer)
    
    if term.path.kind_of?(Hash) && term.path.has_key?(:attribute)
      node_value = node.value
    else
      node_value = node.text
    end
    
    generic_field_name_base = OM::XML::Terminology.term_generic_name(*term_pointer)
    generic_field_name = generate_solr_symbol(generic_field_name_base, term.data_type)
    
    solr_doc << Solr::Field.new(generic_field_name => node_value)
    
    if term_pointer.length > 1
      hierarchical_field_name_base = OM::XML::Terminology.term_hierarchical_name(*term_pointer)
      hierarchical_field_name = generate_solr_symbol(hierarchical_field_name_base, term.data_type)
      solr_doc << Solr::Field.new(hierarchical_field_name => node_value)
    end
    solr_doc
  end
  
  # Use Solrizer::FieldNameMapper to generate an appropriate solr field name +field_name+ and +field_type+
  def self.generate_solr_symbol(field_name, field_type) # :nodoc:
    Solrizer::FieldNameMapper.solr_name(field_name, field_type)
  end
  
  # Instance Methods
  
  
  def to_solr(solr_doc = Solr::Document.new) # :nodoc:
    Solrizer::XML::TerminologyBasedSolrizer.solrize(self, solr_doc)
  end
  
  
  def solrize_term(term, solr_doc = Solr::Document.new, opts={})
    Solrizer::XML::TerminologyBasedSolrizer.solrize_term(self, term, solr_doc, opts)    
  end
  
  def solrize_node(node, term_pointer, term, solr_doc = Solr::Document.new)
    Solrizer::XML::TerminologyBasedSolrizer.solrize_node(node, self, term_pointer, solr_doc)
  end
  
  protected

  def generate_solr_symbol(field_name, field_type) # :nodoc:
    Solrizer::XML::TerminologyBasedSolrizer.generate_solr_symbol(field_name, field_type)
  end
  
end
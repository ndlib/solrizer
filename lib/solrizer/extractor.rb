require "nokogiri"
require 'yaml'

module Solrizer
  
# Provides utilities for extracting solr fields from a variety of objects and/or creating solr documents from a given object
# Note: These utilities are optional.  You can implement .to_solr directly on your classes if you want to bypass using Extractors.
#
# Each of the Solrizer implementations (ie. solrizer-fedora) provides its own Extractor module that extends the behaviors of Solrizer::Extractor
# with methods specific to that implementation (ie. extract_tag, extract_rels_ext, xml_to_solr, html_to_solr).  
# By convention, the solrizer implementations will mix their own Extractors' behaviors into this class when you load them into an application.
#
class Extractor
  
  # Insert +field_value+ for +field_name+ into +solr_doc+
  # Handles inserting new values into a Hash while ensuring that you don't destroy or overwrite any existing values in the hash.
  # Ensures that field values are always appended to arrays within the values hash. 
  # Also ensures that values are run through format_node_value
  # @param [Hash] solr_doc
  # @param [String] field_name
  # @param [String] field_value
  def self.insert_solr_field_value(solr_doc, field_name, field_value)
    formatted_value = self.format_node_value(field_value)
    solr_doc[field_name] ||= []
    solr_doc[field_name] << formatted_value
    return solr_doc
  end
  
  # Strips the majority of whitespace from the values array and then joins them with a single blank delimitter
  # Returns an empty string if values argument is nil
  #
  # @param [Array] values Array of strings or dates representing the values to be formatted
  # @return [String] 
  def self.format_node_value values
    if values.nil?
      return ""
    else
      values = [values] unless values.respond_to? :map
      return values.map { |val|
        if val.is_a?(Date)
          val.to_time.utc.iso8601.to_s
        else
          val.gsub(/\s+/,' ').strip
        end
      }.join(" ")
    end
  end
  
  # Instance Methods
  
  # Alias for Solrizer::Extractor#insert_solr_field_value
  def insert_solr_field_value(solr_doc, field_name, field_value)
    Solrizer::Extractor.insert_solr_field_value(solr_doc, field_name, field_value)
  end
  
  # Alias for Solrizer::Extractor#format_node_value
  def format_node_value values
    Solrizer::Extractor.format_node_value(values)
  end
  
  # Deprecated.
  # merges input_hash into solr_hash
  # @param [Hash] input_hash the input hash of values
  # @param [Hash] solr_hash the solr values hash to add the values into
  # @return [Hash] the populated Solr values hash
  # 
  def extract_hash( input_hash, solr_hash=Hash.new )   
    warn "[DEPRECATION] `extract_hash` is deprecated.  Just pass values directly into your solr values hash" 
    return solr_hash.merge!(input_hash)
  end
  
end
end

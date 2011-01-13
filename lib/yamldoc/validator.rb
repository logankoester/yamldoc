module YAMLDoc

  module Validator
    
    # Public: Validates the format of a YAMLDoc comment block and logs warnings
    # and errors found.
    #
    # mapping - The YAMLDoc::Mapping object containing the docblock in question
    #
    # Returns true when valid, otherwise false.
    def self.validate_docblock(mapping)
      result = true
      # Check for presence
      if mapping.docblock
        if mapping.docblock.empty?
          YAMLDoc.logger.error "Missing YAMLDoc block for '#{mapping.key}'" 
          result = false
        end

        # Check for length
        mapping.docblock.each_with_index do |line, i|
          YAMLDoc.logger.warn "Line #{i + 1} of YAMLDoc block for " +
          "'#{mapping.key}' exceeds recommended wrap length (80 characters)" if line.size > 80
        end
      else
        result = false
      end
      return result
    end

    # Public: Validate a collection of documents at a time
    #
    # collection - Array of YAMLDoc::Document objects.
    #
    # Returns false if one or more failed, returns true if all passed.
    def self.validate_documents(collection)
      r = true
      collection.each do |d| 
        r = false unless d.validate 
      end
      r
    end

    # Public: Validates the value of a mapping against its associated comment 
    # block, and logs warnings and errors found.
    #
    # docblock - The comment block as an array of lines.
    # value    - The value of a key:value Mapping
    #
    # Returns true when valid, otherwise false.
    def self.validate_value(docblock, value)
      true # TODO Implement
    end
  end

  class TemplateValidator
    include Validator
  end

  class DeploymentValidator
    include Validator
  end

end

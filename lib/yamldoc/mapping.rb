module YAMLDoc
  class Mapping

    # Get the key for this mapping. Typically in YAMLDoc documents this will be
    # the name of a configuration setting.
    #
    # Returns the key as a Ruby object.
    attr_reader :key
    
    # Get the value for this mapping. This may be any structure which can be 
    # expressed in YAML and mapped to a Ruby object.
    #
    # Returns the value as a Ruby object.
    attr_reader :value

    # Get the YAMLDoc block describing this mapping.
    #
    # Returns an array of unformatted comment lines.
    attr_reader :docblock

    # Get a list of valid choices described in the docblock.
    # Some mappings allow you to choose more than one value in the list.
    # Call #choice_range for a valid range.
    #
    # Returns the full array of usable values.
    attr_reader :choices

    # Get the number of choices which may be selected.
    #
    # Returns a Fixnum or Range.
    attr_reader :choice_range

    def initialize(options={})
      @key = options[:key] or raise ArgumentError, 
        "YAMLDoc::Mapping requires option :key"
      @value = options[:value]
      self.docblock = options[:docblock] || nil
    end

    def value=(new_value)
      @value = new_value
    end

    def docblock=(lines)
      @docblock = lines
      # Parse the choices section
      if parsed_choices = YAMLDoc::Parser.parse_choices(self.docblock)
        self.choice_range = parsed_choices[:choice_range]
        self.choices = parsed_choices[:choices]
      end
    end
    
    def choice_range=(choice_range)
      @choice_range = choice_range
    end

    def choices=(choices)
      @choices = choices
    end

    def validate
      valid_docblock = YAMLDoc::Validator.validate_docblock(self)
      valid_value = YAMLDoc::Validator.validate_value(self.docblock, self.value)
      (valid_docblock && valid_value) ? true : false
    end

    def to_yaml
      yaml = {@key => @value}.to_yaml
      yaml.sub!(/---.*\n/, '')
      full = @docblock.clone << yaml
      full.join("\n")
    end

  end
end

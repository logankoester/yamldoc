module YAMLDoc
  class Document

    attr_reader :mappings

    def initialize(options={})
      @mappings = options[:mappings] || []
    end

    def validate
      valid_mappings = []
      @mappings.each do |m|
        valid_mappings << m if m.validate
      end
      (valid_mappings.size == @mappings.size) ? true : false
    end

    def to_yaml
      yaml = "---\n"
      yaml << @mappings.map { |m| m.to_yaml }.join("\n")
      yaml
    end
  end
end

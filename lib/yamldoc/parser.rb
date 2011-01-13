require 'yaml'

module YAMLDoc
  class Parser

    # Public: Lines in the YAMLDoc
    # 
    # Returns each line in an Array
    attr_reader :lines
    attr_reader :yamldoc_data

  private
    def initialize(input)
      @input = input
    end

  public
    # Public: Load YAMLDoc from a string
    #
    # str - The String containing the YAMLDoc data
    #
    # Returns a new YAMLDoc::Parser 
    def self.load(str)
      @documents = YAMLDoc::Parser.new(str).parse!
    end

    # Public: Load YAMLDoc from a file
    #
    # fname - The String containing the filename to be loaded
    #
    # Returns a new YAMLDoc::Parser 
    def self.load_file(fname)
      self.load(File.read(fname))
    end

    def parse!
      @documents = split_by_document(@input).map do |doc|
        parse_document(doc)
      end
    end

  private
    # Split a block of YAML text into embedded documents using YAML's document 
    # prefix syntax.
    #
    # str - A string containing one or more YAML documents.
    #
    # Returns: An array of Strings, each containing one YAML document
    def split_by_document(str)
      docs = []
      doc = []
      str.split("\n").each_with_index do |line, i|
        # Start a new document beginning with '---'
        if line.match /^---.*/
          docs << doc.join("\n") unless doc.empty?
          doc = []
          doc << line
        elsif line.match /^\.\.\..*/
          # Start a new document after "..."
          doc << line
          docs << doc.join("\n")
          doc = []
        else
          doc << line
        end
      end
      docs << doc.join("\n")
      docs
    end

    # Iterate through a YAML document mapping data to YAMLDoc::Mappings to build
    # a YAMLDoc::Document.
    #
    # str - String containing the YAML document to be parsed.
    # 
    # Returns a new YAMLDoc::Document object containing all the data found in
    # the document.
    def parse_document(str)
      document = YAMLDoc::Document.new
      lines = str.split("\n")
      line = 0

      # Ensure that the document's root node is a Mapping, as required by YAMLDoc
      doc = YAML.load(str)
      raise TypeError, "YAMLDoc document's root node is not a Mapping" unless doc.is_a? Hash

      doc.each do |map|

        # Create a YAMLDoc::Mapping for each key
        mapping = YAMLDoc::Mapping.new(
          :key => map.first, 
          :value => map.last,
          :document => document
        )

        # Search the YAML text for this key, to extract additional data not provided
        # by the normal YAML parser (comments and formatting to be preserved when the
        # file is regenerated later), and YAMLDoc markup especially.
        while(line < lines.size)
          if lines[line].match /\s*#{mapping.key}:.*/

            # Grab the YAMLDoc block above the first line we found the key on
            mapping.docblock = block_above(line)

            line += 1
            break
          end
          line += 1
        end

        document.mappings << mapping
      end

      document
    end

    # Fetch the comment block directly above a given line in @input.
    #
    # line - The zero-indexed line number to look above
    #
    # Returns an array of unaltered comment line strings, or an empty array
    # if there was not a comment directly above line.
    def block_above(line)
      lines = @input.split("\n")
      block = []
      line -= 1
      while(line >= 0)
        if lines[line].match /\s*#.*/
          block << lines[line]
        else
          break
        end
        line -= 1
      end
      block.reverse!
    end

    def self.parse_choices(docblock)
      return false unless docblock
      line = 1 # Only a Description is allowed on the first docblock line
      while (line < docblock.size)
        if match = docblock[line].match(/.*Choose\s*(\((\d|\.)+\))?:(.*)/)
          # Choice Section found!

          # Parse the Fixnum or Range of selections allowed
          if match[2]
            if match[2].include?('..')
              choice_range = Range.new( *match[2].split('..').map{|s| s.to_i} )
            else 
              choice_range = match[2].to_i
            end
          else
            choice_range = 1
          end

          choices = match[3]
          if choices.empty?
            # Choices should be described on the remaining lines
            line += 1
            choices = []
            while(line < docblock.size)
              choices << docblock[line].uncomment
              line += 1
            end
            choices = YAML.load(choices.join("\n"))
          else
            # Parse the choices if described inline
            choices = YAML.load(choices)
          end

          return { :choice_range => choice_range, :choices => choices }
        end
        line += 1
      end
      return false
    end

  end
end

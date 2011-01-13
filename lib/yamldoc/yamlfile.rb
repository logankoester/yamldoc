require 'find'

module YAMLDoc
  module YAMLFile
    class << self
      # Determine whether a file is an example.yml template or real deployment.
      #
      # filename - String
      #
      # Examples
      #
      #   template?('settings.example.yml.erb') # => true
      #   template?('application.yml')          # => false
      # 
      # Returns true if it is a template or false if it is not
      def template?(filename)
        filename.include?('example.yml')
      end
      
      # Determine whether a file is an example.yml template or real deployment.
      # The inverse of #template?
      #
      # filename - String
      #
      # Returns true if it is a deployment or false if it is not
      def deployment?(filename)
        filename.include?('.yml') and not filename.include?('example.yml')
      end

      # Return the name of the file associated with the provided filename.
      #
      # filename - String
      #
      # Examples
      #   
      #   find_associated('config/application.yml')
      #   # => 'config/application.example.yml'
      #
      #   find_associated('config/application.example.yml')
      #   # => 'config/application.yml'
      #
      # Returns a filename String or raises ArgumentError on invalid input.
      def associated_filename(filename)
        if template?(filename)
          return filename.sub('.example', '')
        else
          result = filename.sub('.yml', '.example.yml')
          result.include?('example.yml') ? result : raise(ArgumentError)
        end
      end

      # Locate the YAML file associated with the specified file.
      #
      # filename - String
      #
      # Examples
      #   
      #   find_associated('config/application.yml')
      #   # => 'config/application.example.yml'
      #
      #   find_associated('config/application.example.yml')
      #   # => 'config/application.yml'
      #
      # Returns a filename String or false if it doesn't exist.
      def find_associated(filename)
        assoc = associated_filename(filename)
        File.exists?(assoc) ? assoc : false
      end

      # Determine whether a template has a deployment copy installed.
      #
      # filename - String
      #
      # Examples
      # 
      # installed?('config/application.example.yml')
      #   # => returns true if 'config/application.yml' exists
      # 
      # Returns true if the template is installed and false in all other cases.
      def installed?(filename)
        ( template?(filename) && find_associated(filename) ) ? true : false
      end

      # Search for YAML template files beneath the specified path.
      # 
      # path - String
      #
      # Returns an array of matching files.
      def find_templates(path)
        templates = []
        Find.find(path) do |path|
          templates << path if template?(path)
        end
        templates
      end

      # Search for deployed YAML files beneath the specified path.
      # 
      # path - String
      #
      # Returns an array of matching files.
      def find_deploys(path)
        templates = []
        Find.find(path) do |path|
          templates << path if deployment?(path)
        end
        templates
      end

      # Copies a template to its associated path, overwriting any
      # existing deployment without warning. Rather than do a filesystem
      # copy, #install rebuilds the deployed copy from the template.
      #
      # Any diff should be considered a parser bug, assuming your template
      # validates correctly (use "$ yamldoc validate FILE").
      #
      # A template that does not validate will fail to install.
      # 
      # If you find a diff, a patch or failing unit test demonstrating the
      # defect would be greatly appreciated. Thank you!
      #
      # template     - String template filename
      #
      # Returns true if installed successfully, otherwise false.
      def install(template)
        # Load & parse
        return false unless ( File.exists?(template) && 
          YAMLDoc::YAMLFile.template?(template) )

        target = associated_filename(template)

        documents = YAMLDoc::Parser.load_file(template)

        # Validate (only proceed if all pass)
        return false unless YAMLDoc::Validator.validate_documents(documents)
        
        # Generate YAML
        yaml = documents.map { |d| d.to_yaml }.join("\n")

        # Write to file
        File.open(target, 'w+') { |f| f << yaml }
      end

    end
  end
end

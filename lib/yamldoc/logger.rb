require 'logger'
module YAMLDoc
  # A nice clean logger without the timestamp. Default for YAMLDoc.
  class SimpleLogger < Logger::Formatter
    def call(severity, time, program_name, message)
      print_message = "#{severity} - #{message}\n"
    end
  end

  # ColorizedSimpleLogger used by the 'yamldoc' tool to alert users of
  # validation errors and warnings, for the most part. Use SimpleLogger
  # if you prefer no color.
  class ColorizedSimpleLogger < SimpleLogger
    def call(severity, time, program_name, message)
      colors = { 
        "FATAL" => :red, "ERROR" => :red, "WARN" => :yellow, 
        "INFO" => :green, "DEBUG" => :default
      }
      print_message = "#{severity} - #{message}\n".colorize(colors[severity])
    end
  end

  @logger = Logger.new(STDOUT)
  @logger.formatter = SimpleLogger.new

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

end

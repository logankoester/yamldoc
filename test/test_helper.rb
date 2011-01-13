require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'bacon'
require 'fakefs/safe'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'yamldoc'

class TestLogger
  attr_reader :errors, :warnings
  def initialize
    @errors = []
    @warnings = []
  end

  def error(e)
    @errors << e
  end

  def warn(e)
    @warnings << e
  end
end

YAMLDoc.logger = TestLogger.new


require File.join(File.expand_path(File.dirname(__FILE__)), 'test_helper')
require 'pp'

describe "The YAMLDoc Parser" do

  describe "can handle valid embedded document styles" do

    it 'should allow one document beginning with "---"' do
      YAMLDoc::Parser.load("---\nfoo: 1").size.should.equal 1
    end
    
    it 'should allow one document omitting the "---"' do
      YAMLDoc::Parser.load("foo: 1").size.should.equal 1
    end

    it 'should allow two documents, omitting the "---" for the first' do
      YAMLDoc::Parser.load("foo: 1\n---\nbar: 2").size.should.equal 2
    end

  end

  describe "...with the simple.yml fixture loaded" do
    before do
      @documents = YAMLDoc::Parser.load_file('test/fixtures/simple.yml')
    end

    it 'should load a single Document' do
      @documents.class.should.equal Array
      @documents.size.should.equal 1
      @documents.first.class.should.equal YAMLDoc::Document
    end

    it 'should contain the YAML data' do
      mapping = @documents.first.mappings.first
      mapping.key.should.equal('purpose')
      mapping.value.should.match /Simplest possible/
    end

    it 'should contain the YAMLDoc data' do
      docblock = @documents.first.mappings.first.docblock
      docblock.class.should.equal Array
      docblock.first.should.match /purpose of this fixture/
      docblock.last.should.match /described in a/
    end
  end

end

describe "A YAMLDoc Document" do
  describe "...within the simple.yml fixture" do
    before do
      @document = YAMLDoc::Document.new
    end

    it "should return an array from #mappings" do
      @document.mappings.class.should.equal Array
    end
  end
end

describe "A YAMLDoc Mapping" do
  it "should raise an error if initialized without required options" do
    lambda { 
      @setting = YAMLDoc::Mapping.new
    }.should.raise(ArgumentError)
  end

  describe "...with valid options" do
    before do
      @mapping = YAMLDoc::Mapping.new(:key => 'appname', :value => 'Hello World')    
    end

    it "should set the #key and value from options" do
      @mapping.key.should.equal 'appname'
      @mapping.value.should.equal 'Hello World'
    end

    it "should return nil for docblock unless set" do
      @mapping.docblock.should.equal nil
    end

    it "should allow the value to be changed" do
      @mapping.value = "new value"
      @mapping.value.should.equal "new value"
    end

    it "should allow the docblock to be changed" do
      @mapping.docblock = ["# Added after instantiation"]
      @mapping.docblock.size.should.equal 1
      @mapping.docblock.first.should.match /Added/
    end

    describe "...with a single-choice inline Choose section" do
      before do
        @mapping.docblock = ["# Description", "# Choose: ['oranges', 'bananas']"]
      end

      it "should return a list of two choices when #choices is called" do
        @mapping.choices.size.should.equal 2
      end

      it "should maintain the list order described in the docblock" do
        @mapping.choices.first.should.equal 'oranges'
        @mapping.choices.last.should.equal  'bananas'
      end

      it "should return 1 for #choice_range" do 
        @mapping.choice_range.should.equal 1
      end
      
    end

    describe "...with a 2-choice block Choose section" do
      before do
        @mapping.docblock = ["# Description", 
          "# Choose (2):", "# - oranges", "# - bananas"]
      end

      it "should return a list of two choices when #choices is called" do
        @mapping.choices.size.should.equal 2
      end

      it "should maintain the list order described in the docblock" do
        @mapping.choices.first.should.equal 'oranges'
        @mapping.choices.last.should.equal  'bananas'
      end

      it "should return 2 for #choice_range" do 
        @mapping.choice_range.should.equal 2
      end

      it "should allow a range as the choice_range" do
        @mapping.docblock = ["# Description", 
          "# Choose (1..2):", "# - oranges", "# - bananas"]
        @mapping.choice_range.should.equal 2
      end

    end

  end
end

describe "Validation" do
  describe "...with the missing_yamldoc.yml fixture loaded" do
    before do
      YAMLDoc.logger = TestLogger.new
      @documents = YAMLDoc::Parser.load_file('test/fixtures/missing_yamldoc.yml')
      @documents.first.validate
    end

    it 'should log the missing YAMLDoc error' do
      YAMLDoc.logger.errors.size.should.equal 1
      YAMLDoc.logger.errors.first.should.match(
        /Missing YAMLDoc block/
      )
    end
  end

  describe "...with a YAMLDoc line exceeding 80 characters" do
    before do
      YAMLDoc.logger = TestLogger.new
      chars = ""
      81.times { chars << "0" }
      @documents = YAMLDoc::Parser.load("---\n# #{chars}\nfoo: bar")
      @documents.first.validate
    end

    it 'should log a warning' do
      YAMLDoc.logger.warnings.size.should.equal 1
      YAMLDoc.logger.warnings.first.should.match(
        /exceeds recommended wrap length/
      )
    end
  end
end

describe "YAMLFile" do
  it "should recognize various template and non-template filenames" do
    YAMLDoc::YAMLFile.template?('test.example.yml').should.equal true
    YAMLDoc::YAMLFile.template?('config/test.example.yml.erb').should.equal true
    YAMLDoc::YAMLFile.template?('config/test.yml.erb').should.equal false
  end

  it "should accurately determine associated filenames (template/deployment)" do
    YAMLDoc::YAMLFile.associated_filename('test.example.yml').
      should.equal 'test.yml'
    YAMLDoc::YAMLFile.associated_filename('config/test.yml.erb').
      should.equal 'config/test.example.yml.erb'
  end

  it "should raise an error if associated_filename is passed a non-YAML file" do
    lambda { YAMLDoc::YAMLFile.associated_filename('/usr/bin/fortune') }.
      should.raise ArgumentError
  end

  it "should realize I'm making these filenames up" do
    YAMLDoc::YAMLFile.find_associated('config/test.yml').should.equal false
  end

  it "should find templates and deployed YAML in a directory" do
    FakeFS do
      Dir.mkdir('yaml-in-here')
      File.new('yml-in-here/foo.example.yml', 'w+')
      File.new('yml-in-here/bar.yml', 'w+')
      File.exists?('yml-in-here/foo.example.yml').should.equal true
      File.exists?('yml-in-here/bar.yml').should.equal true

      YAMLDoc::YAMLFile.find_templates('yml-in-here').size.should.equal 1
      YAMLDoc::YAMLFile.find_templates('yml-in-here').
        should.include 'yml-in-here/foo.example.yml'

      YAMLDoc::YAMLFile.find_deploys('yml-in-here').size.should.equal 1
      YAMLDoc::YAMLFile.find_deploys('yml-in-here').
        should.include 'yml-in-here/bar.yml'
    end
  end
end

describe "Installing a basic template" do
  before do
    @template = 'test/fixtures/basic_config.example.yml'
  end

  it "should create an associated deployment file" do
      @installed = YAMLDoc::YAMLFile.install(@template)
      File.exists?(YAMLDoc::YAMLFile.associated_filename(@template)).
                  should.equal true
  end

end

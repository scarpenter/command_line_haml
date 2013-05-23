#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"

require "haml"

class Context
  attr_reader :example_boolean

  def initialize(example_boolean, scope, options)
    @example_boolean = example_boolean
    @scope = scope
    @options = options
  end

  def copyright_year
    start_year = 2013
    end_year = Time.now.year
    if end_year == start_year
      start_year.to_s
    else
      "#{start_year}&#8211;#{end_year}"
    end
  end

  def render_partial(file_name)
    file_to_render = "./views/partials/#{file_name.to_s}.haml"
    if @scope
      scope_file = "./views/partials/#{@scope.to_s}_#{file_name.to_s}.haml"
      file_to_render = scope_file if File.exists? scope_file
    end
    if File.exists? file_to_render
      partial = Haml::Engine.new(File.read(file_to_render), @options)
      partial.render
    else
      nil
    end
  end
end

class Generator
  def initialize(example_boolean, output_dir = ".")
    @example_boolean = example_boolean
    @output_dir = output_dir
    @haml_options = { attr_wrapper: '"', format: :html5 }
  end

  def generate(input_file)
    layout = Haml::Engine.new(File.read("./views/layout.haml"), @haml_options)
    c = Context.new @example_boolean, input_file, @haml_options

    output = layout.render c do
      body = Haml::Engine.new(File.read("./views/#{input_file}.haml"), @haml_options)
      body.render c
    end

    output_path = File.join(@output_dir, "#{input_file}.html")
    File.open(output_path, "w") do |f|
      f.write output
    end
  end
end

if __FILE__==$0
  example_boolean = ARGV.length > 0 && (ARGV[0] == "true" || ARGV[0] == "yes")
  g = Generator.new example_boolean
  g.generate "index"
end

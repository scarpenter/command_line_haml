#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"

require "haml"

# Calls to "render" can take a context object that will be accessible from the templates.
class Context
  # Any properties of this object are available in the Haml templates.
  attr_reader :example_boolean

  def initialize(example_boolean, scope, options)
    @example_boolean = example_boolean
    @scope = scope
    @options = options
  end

  # This is an example function that can be called inside Haml templates.
  def copyright_year
    start_year = 2013
    end_year = Time.now.year
    if end_year == start_year
      start_year.to_s
    else
      "#{start_year}&#8211;#{end_year}"
    end
  end

  # This function is no different from the "copyright_year" function above. It just uses some
  # conventions to render another template file when it's called.
  def render_partial(file_name)
    # The "default" version of the partial.
    file_to_render = "./views/partials/#{file_name.to_s}.haml"
    if @scope
      # Look for a partial prefixed with the current "scope" (which is just the name of the
      # primary template being rendered).
      scope_file = "./views/partials/#{@scope.to_s}_#{file_name.to_s}.haml"
      # Use it if it's there.
      file_to_render = scope_file if File.exists? scope_file
    end
    # If we found a matching partial (either the scoped one or the default), render it now.
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
    # Change these to whatever makes sense for your needs.
    @haml_options = { attr_wrapper: '"', format: :html5 }
  end

  def generate(input_file)
    layout = Haml::Engine.new(File.read("./views/layout.haml"), @haml_options)
    c = Context.new @example_boolean, input_file, @haml_options

    # If the file being processed by Haml contains a yield statement, the block passed to
    # "render" will be called when it's hit.
    output = layout.render c do
      # Render the actual page contents in place of the call to "yield".
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
  g.generate "another_page"
end

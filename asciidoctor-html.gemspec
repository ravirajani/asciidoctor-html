# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "asciidoctor-html"
  spec.version = "1.0.3"
  spec.authors = ["Ravi Rajani"]
  spec.email = ["ravi.inajar@gmail.com"]

  spec.summary = "An AsciiDoc-to-HTML static site generator based on Asciidoctor."
  spec.homepage = "https://github.com/ravirajani/asciidoctor-html"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ docs/ .git .github appveyor Gemfile Gemfile.lock])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "asciidoctor", "2.0.23"
  spec.add_dependency "filewatcher", "2.1.0"
  spec.add_dependency "nokogiri", "1.18.9"
  spec.add_dependency "psych", "5.2.6"
  spec.add_dependency "roman-numerals", "0.3.0"
end

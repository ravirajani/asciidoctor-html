[![Build](https://github.com/ravirajani/asciidoctor-html/actions/workflows/main.yml/badge.svg)](https://github.com/ravirajani/asciidoctor-html/actions/workflows/main.yml)

# Asciidoctor::Html

**The code in this repo is being actively developed and currently has limited functionality.**

When complete, this gem will provide an alternative HTML converter for [Asciidoctor](https://github.com/asciidoctor/asciidoctor) as well as a simple static site generator.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add asciidoctor-html
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install asciidoctor-html
```

## Usage

```ruby
require "asciidoctor"
require "asciidoctor/html"

Asciidoctor.convert_file "mydoc.adoc"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

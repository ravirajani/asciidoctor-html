[![Build](https://github.com/ravirajani/asciidoctor-html/actions/workflows/main.yml/badge.svg)](https://github.com/ravirajani/asciidoctor-html/actions/workflows/main.yml)

# asciidoctor-html

**The code in this repo is being actively developed. Use at your own risk.**

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add asciidoctor-html
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install asciidoctor-html
```
## Configuration

See [documentation config](docs/asciidoc/config.yml) for an example of a configuration file.
In a typical scenario, you would put this file in the same directory as your AsciiDoc
sources.

## Basic Usage

Assuming your config file is in the same directory as your AsciiDoc sources, execute:

```shell
cd <ASCIIDOC_SOURCES_DIR>
adoctohtml [--watch]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bundle exec rake` to run the tests. You can also run `bin/cli` to test the CLI after making changes.

Run `jekyll serve --livereload` inside the `docs/html` directory to preview your changes after running `bundle exec rake`.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `asciidoctor-html.gemspec`,
and then run

```shell
bundle exec rake stylesheet
bundle exec rake release
```

The first line runs the tests and builds the stylesheet `assets/css/styles.css`.
The second line creates a git tag for the version, pushes git commits and the created tag,
and pushes the `.gem` file to [rubygems.org](https://rubygems.org).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# frozen_string_literal: true

require "pathname"
require "zlib"
require "strscan"

module Asciidoctor
  module Html
    # Postprocess site with cachebusting paths
    module CacheBuster
      AssetData = Struct.new("AssetData", :filehash, :newpath)

      def self.process(outdir)
        puts "Cache busting..."
        puts
        cache = {} # assetpath => {:filehash,:newpath}
        glob = ["**/*.html", "*.webmanifest"]
        Pathname(outdir).glob(glob) do |filepath|
          puts "Processing #{filepath}"
          scanner = StringScanner.new(filepath.read)
          rgx = %r{"((?<prefix>[\./]*?#{ASSETS_PATH}/.+?)(?<hash>\.|\.[a-f0-9]{8}\.)(?<ext>[a-z]+?))"}
          buffer = []
          while (scanned = scanner.scan_until(rgx))
            matched = scanner.matched
            buffer << scanned[0, scanned.size - matched.size]
            matchedpath = Pathname(matched[1..-2])
            assetpath = filepath.dirname / matchedpath
            if assetpath.file?
              assetpath = assetpath.realpath
              captures = scanner.named_captures
              cache[assetpath] ||= AssetData.new
              assetdata = cache[assetpath]
              assetdata.filehash ||= format("%08x", Zlib.crc32(assetpath.read))
              new_hash = assetdata.filehash
              found_hash = captures["hash"][1..-2] unless captures["hash"] == "."
              if new_hash == found_hash
                buffer << matched
              else
                new_name = "#{captures["prefix"]}.#{new_hash}.#{captures["ext"]}"
                buffer << %("#{new_name}")
                assetdata.newpath = filepath.dirname / Pathname(new_name)
              end
            else
              buffer << matched
            end
          end
          buffer << scanner.rest
          filepath.write buffer.join
        end
        cache.each_pair do |assetpath, assetdata|
          next unless assetdata.newpath

          puts
          puts "Renaming:"
          puts assetpath
          puts "-> #{assetdata.newpath}"
          assetpath.rename(assetdata.newpath)
        end
      end
    end
  end
end

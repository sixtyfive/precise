module Precise

  using CoreExtensions # the more generic ones

  class Corpora
    using Precise::CoreExtensions

    def initialize
      resdir = File.join __dir__,'..','..','res'
      FileUtils.mkdir_p resdir
      typesfile = File.absolute_path(File.join resdir,'types.lst')
      download(typesfile) unless File.exist? typesfile
      @types = File.readlines typesfile, chomp: true
    end

    def download(path)
      puts 'downloading types database (only needed once)...'
      require 'net/http'
      require 'open-uri'
			require 'progressbar'
      url = 'https://raw.githubusercontent.com/sixtyfive/arabic-types/main/types.lst'
      data = URI.open(url)
      IO.copy_stream data, path
    end

    def percentage_of_tokens_present(string)
      words = string.split
      n_present = words.map{|w| @types.include? w}.count(true)
      100.0 / words.length * n_present
    end

    def self.percentage_of_tokens_present(string)
      new.percentage_of_tokens_present(string)
    end
  end
end

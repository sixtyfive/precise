module Precise

  using CoreExtensions # the more generic ones

  class Transcription
    def initialize(opts = {})
      default_options = {punctuation: true, verbosity: 0}
      @opts = default_options.merge(opts)
      @opts[:verbosity] += 2 if @opts.delete(:verbose) == true
      $dbg += @opts[:verbosity]
    end

    def transcribe(arabic)
      "sorry, transcription of Arabic into Latin characters is not implemented yet"
    end

    def self.transcribe(arabic, opts={})
      new(opts).transcribe(arabic)
    end
  end
end
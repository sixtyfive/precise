module Precise
  class Transcription
    def initialize(opts = {})
      default_options = {punctuation: true, verbosity: 0}
      @opts = default_options.merge(opts)
      @opts[:verbosity] += 2 if @opts.delete(:verbose) == true
      $dbg += @opts[:verbosity]
      @out_chunks = []
    end
  end
end
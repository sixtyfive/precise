require 'pp'
require 'slop'
require 'yaml'
require 'tiny_color'

deps = %w[version debugging error_classes core_extensions transcription transcription_r2a transcription_a2r types_list]
deps.each{|d| require_relative File.join(__dir__,'..','lib','precise',d)}

module Precise
  class CLI
    def initialize
      opts = Slop::Options.new
      opts.banner = "Usage: precise [options] <string(s)>\n"
      opts.separator "    where options can be:\n"
      alif_variants = Precise::Transcription::AlifVariants
      opts.bool "-s", "--show-rules", "print the list of rules which are applied for transcription"
      opts.bool "-c", "--confidence", "also print the percentage of output words appearing in a large corpus of Arabic"
      opts.bool "-A", "--no-alif-variants", "all of #{alif_variants.join("، ")} will be merged into ا"
      opts.bool "-T", "--no-tashkeel", "diacritics (and non printables, such as tatweel) will be removed from output"
      opts.bool "-P", "--no-punctuation", "all punctuation characters will be discarded from output"
      opts.bool "-v", "--verbose", "instruct the backend classes to output debugging and plausibility information"
      opts.bool "-h", "--help", "display this message"
      opts.separator "\n    Transcription direction is determined by presence of characters from the 'Arabic' Unicode block.\n" \
        "    At present, Arabic-to-Roman transcription is only rudimentary."
      opts = Slop::Parser.new(opts)

      begin
        @opts = opts.parse(ARGV)
        usage if @opts[:help] || ARGV.size == 0
        rules if @opts.to_h[:show_rules]
      rescue
        @opts = opts.parse([])
        usage
      end

      options = {verbose: @opts[:verbose]}
      options[:alif_variants] = false if @opts.to_h[:no_alif_variants]
      options[:tashkeel] = false if @opts.to_h[:no_tashkeel]
      options[:punctuation] = false if @opts.to_h[:no_punctuation]

      instr = @opts.arguments.join(' ')
      if instr.match?(/\p{Arabic}/)
        outstr = Precise::Transcription.transcribe(instr.dup, options)
      else
        outstr = Precise::Transcription.reverse(instr.dup, options)
        outstr += " (#{Precise::TypesList::percentage_of_tokens_present(outstr)}%)" if @opts[:confidence]
      end
      puts outstr.pretty_inspect.gsub(/(^"|"$)/, "").strip
    end

    def usage
      warn @opts
      exit
    end

    def rules
      puts Precise::Transcription::R2ATables.map{|k,v| Hash[k.to_s,v.map{|kk,vv| Hash[kk.to_s,vv]}]}.to_yaml.gsub(/---\n/,'')
      exit
    end

    def nopts
      @opts.to_h.values.map { |o| o || nil }.compact.size
    end

    def self.start; new; end
  end
end

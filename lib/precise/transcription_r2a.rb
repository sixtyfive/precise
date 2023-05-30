module Precise

  using CoreExtensions # the more generic ones

  module CoreExtensions # the ones specific to this module
    refine String do
      # default output is "with everything"
      # so once something is set to false, it'll be removed
      def apply_options(opts)
        defaults = {punctuation: true, tashkeel: true, alif_variants: true}
        opts = defaults.merge opts
        s = self.dup

        if !opts[:punctuation]
          s = s.gsub(/[[:punct:]]+/,'')
        end

        if !opts[:tashkeel]
          tashkeel = Precise::Transcription::Tashkeel
          nonprintables = Precise::Transcription::Nonprintables
          extraneous_chars = [tashkeel + nonprintables].join
          s = s.gsub(/[#{extraneous_chars}]/,'')
        end

        if !opts[:alif_variants]
          alif_variants = Precise::Transcription::AlifVariants
          s = s.gsub(/[#{alif_variants}]/,'ا')
        end

        return s.strip
      end
    end
  end

  class Transcription
    using Precise::CoreExtensions

    # Ruby would have been fine with these in the file verbatim (on their own),
    # alas, my editor's syntax highlighting can't cope, so doing it 1990s-style
    Fatha, Kasra, Damma, Shadda = ["\u064e", "\u0650", "\u064f", "\u0651"].each_utf8_encode
    # nonprintables
    R2LM, L2RM, ZWNJ = ["\u200f", "\u200e", "\u200c"].each_utf8_encode
    # typographic modifiers, ligatures, oft-used words
    Tatweel, Allah = ["ـ", "الله‎"]
    # the various forms of alif, ya and waw
    AlifVariants = ['أ', 'إ', 'آ', 'ا', 'ٱ']
    AlifHamzaAbove, AlifHamzaBelow, AlifMadda, Alif, AlifWasla = AlifVariants
    YaHamzaAbove, Ya = ['ئ', 'ي']
    WawHamzaAbove, Waw = ['ؤ', 'و']
    # other character lists
    Tashkeel = ("064B".to_i(16).."065B".to_i(16)).map{|dec| hex=("%04x" % dec); eval("char=\"\\u#{hex}\"; char")}
    Nonprintables = [R2LM, L2RM]

    R2ATables = {
      # Adapted from the Transcription in the Brill PDF's "Note to the Indices":
      # - a dash, depending on its position, denotes the start or end of the word
      # - an array denotes the requirement for a choice to be made from context
      # - any characters that are being replaced by DMG characters have been ommitted
      common: {
        ʾ:     :ء,
        b:     :ب,
        p:     :پ,
        t:     :ت,
        ḥ:     :ح,
        d:     :د,
        r:     :ر,
        z:     :ز,
        s:     :س,
        ṣ:     :ص,
        ḍ:     :ض,
        ṭ:     :ط,
        ẓ:     :ظ,
        ʿ:     :ع,
        f:     :ف,
        q:     :ق,
        k:     :ك,
        g:     :گ,
        l:     :ل,
        m:     :م,
        n:     :ن,
        h:     :ه,
        w:     :و,
        y:     :ي,
        ā:     :ا,
        ū:     :و,
        ī:     :ي,
      },
      vowels: {
        a:     Fatha,
        à:     Fatha, # at word-end only
        u:     Damma,
        i:     Kasra,
      },
      combos: {
        aw:    :َو,
        ay:    :َي
      },
      brockelmann: {
        '-a':  :ة,  # "-" = at word-end
        '-at': :ة,  # "-" = at word-end
        'al-': :ال, # "-" = at word-start
      },
      dmg: {
        ṯ:     :ث,
        ǧ:     :ج,
        č:     :چ,
        ḫ:     :خ,
        ḏ:     :ذ,
        ž:     :ژ,
        š:     :ش,
        ġ:     :غ
      },
      uppercase: {
        A:     :أَ,
        I:     :إِ,
        U:     :أُ,
        Y:     :ي
      },
      farsi: {
        v:     :و, # always? what, e.g. about "Divbandi"?
        e:     [:ه, Fatha] # word-end, mid-word
      },
      turkic: {
        ö:     :و,
        ü:     Damma, # ???
        ı:     Kasra, # ???
        E:     :ا
      },
      indic: {
        ō:    :و # things like "Bh" => "بْ" would go here, too
      },
      romanic: {
        c:    :ث, # or should this rather be a س?
        o:    :و,
        Ė:    :إي,
        x:    :كس
      },
      semitic: {
        ē:    :ﺍ # is that always so?
      },
      finnic: {
        ä:    Fatha # in e.g. Mänglī
      },
      precise: {
        á:    :ى,
        Ā:    :آ, # don't add 'ʾĀ' here - it is considered an error in the input!
        'ʾā': :آ # same but lowercase - alif madda in the middle of the word
      }
    }

    PostR2AWordReplacements = {
      /^(.*[^أ])َلّاه/ => '\1 الله', # names ending in "allah"
      /أَلّاه(\s|$)/ => 'الله\1', # Allah
      /(ب\.|إبن|إِبن)/ => 'بن', # "son of"
      /أَبي/ => 'أبي', # "father of" (gen.)
      /أَبو/ => 'أبو', # "father of" (nom.)
      /بَكر/ => 'بكر', # the name "bakr"
      /عَلي/ => 'علي', # the name "ali"
      /عَبد/ => 'عبد', # the name-part "abd"
      /افندي/ => 'افندی' # ottoman/turkish effendi
      # /([یي]زاده$)/ => ZWNJ+'ی'+ZWNJ+'زاده', # names ending in "-azade" # removed at DK's request
    }

    PostR2AContextReplacements = {
      /((^|\.\s+)بن(\s+))/ => 'ابن\3', # exception: son-of in beginning of sentence
      /(تِ|تُ|تَ)(\s+)/ => 'ة ', # this'll lose the case ending, but that's for the better
      /(ييَ|يَّ)(\s+|$)/ => 'يَّة\2', # nisba
      /داوود/ => 'داود' # not sure if this might actually hold true for all ...wū...?
    }

    PunctSepRgx = /[ \.\-\(\)\?\&=,;:]/
      
    R2A = R2ATables.values.inject(:merge) # just one level is enough now
                   .keys_and_values_to_s  # more convenient to work with

    SunLetters = %w[t ṯ d ḏ r z s š ṣ ḍ ṭ ẓ l n]
    RomanizedShortVowels = %w[a i u]
    RomanizedLongVowels = %w[ā ū ī]
    # "a" here because of ta'marbouta, "á" because of alif maqsoura, "ā" because of word-final alif mamdouda
    RomanizedConsonantals = SunLetters + %w[m l k q f ġ ʿ ḫ ḥ h ǧ b ʾ a á]
    ArabicScriptVowels = %w[ا ي و]
    ArabicScriptConsonants = %w[ا ب ت ث ج ح خ س ش ص ض ط ظ ع غ ف ق ك ل م ن ه ي ئ ة ى أ إ ؤ ئ آ]
      
    LatinChars = R2A.map{|l,a| l unless l.size != 1}.compact
    TranslitChars_lowercase = 'ʾʿḏḥṣḍṭẓāūīṯǧčḫžšġōĖēáäüöü'
    TranslitChars = (TranslitChars_lowercase + TranslitChars_lowercase.upcase).chars.uniq.join

    def this_word(str, idx)
      str[0...idx][/\S*\z/] + (str[idx..-1][/\A[#{TranslitChars}\w]+/] || '')
    end

    def this_word_and_the_next(str, idx)
      # first part: from beginning of string to index position, get all non-whitespace characters
      # second part: from index position to end of string,
      #              get all characters belonging to the word which the index position character belongs to,
      #              as well as the next word if any
      if str.match?(/\s+/)
        str[0...idx][/\S*\z/] + (str[idx..-1][/\A[#{@translit_chars}\w]+\s+[#{@translit_chars}\w]+/i] || '')
      else
        str
      end
    end

    def hamza_before_following(ch, pch, first_letter_of_word = false)
      if first_letter_of_word
        case ch.to_sym
          when :a, :u then AlifHamzaAbove
          when :i then AlifHamzaBelow
          when :ā then AlifMadda
          when :ī then "#{YaHamzaAbove}#{R2A[ch]}"
          when :ū then "#{WawHamzaAbove}#{R2A[ch]}"
        end
      else
        if %w[y ī].include? pch
          # also take into account what PRECEDED the hamza - that might take precedence!
          case ch.to_sym
            when :a then YaHamzaAbove
            when :i then YaHamzaAbove
            when :u then WawHamzaAbove
            when :ī then "#{YaHamzaAbove}#{R2A[ch]}"
            when :ū then "#{WawHamzaAbove}#{R2A[ch]}"
          end
        else
          case ch.to_sym
            when :a then AlifHamzaAbove
            when :i then YaHamzaAbove
            when :u then
              pch == 'ū' ? R2A['ʾ'] : WawHamzaAbove
            when :ī then "#{YaHamzaAbove}#{R2A[ch]}"
            when :ū then "#{WawHamzaAbove}#{R2A[ch]}"
          end
        end
      end
    end

    def hamza_after_preceding(ch, first_letter_of_word = false)
      if first_letter_of_word
        case ch.to_sym
          when :a then AlifHamzaAbove
          when :u then R2A['ā']+Damma+WawHamzaAbove
          when :i then R2A['ā']+YaHamzaAbove
        end
      else
        case ch.to_sym
          when :a then AlifHamzaAbove
          when :i then YaHamzaAbove
          when :u then WawHamzaAbove
          when :ī then YaHamzaAbove
        end
      end
    end

    def alif_for_word_initial_kasra(word)
      # a,i,u = that specific short vowel
      # c = any consonantal
      # s = any short vowel
      # l = any long vowel
      patterns = [
        'iCClC',
        'iCCiCClC',
        'iClCC'
      ]
      # pp word
      shorts = RomanizedShortVowels
      longs = RomanizedLongVowels
      consonants = RomanizedConsonantals
      alif = Alif
      patterns.each do |p|
        # puts "> #{p}"
        next unless word.size == p.size
        match = true
        word.chars.each_with_index do |c,i|
          case p[i]
            when 'C' then match = false unless consonants.include?(c)
            when 's' then match = false unless shorts.include?(c)
            when 'l' then match = false unless longs.include?(c)
          else
            match = false unless c == p[i]
          end
          # puts "after #{c}: #{match} (should have been #{p[i]})"
        end
        (match = false if word.downcase.match?(/^ist/)) # استـ introduces 
        (alif = AlifHamzaBelow; break) if match
      end; puts "\t\tfor #{word}: word-initial #{alif}".light_blue if $dbg > 1
      alif
    end

    def sanitize(str)
      # remove nonprintables such as the ZWNJ
      # FIXME: the erroneous_chars replacement table should have already taken care of this?!
      ["\u200c", "\u200f"].each{|ch| str.gsub! ch, ''}
      # make letters following either ʿ or ʾ lowercase
      lastc=''; str.chars.map{|c| c.downcase! if lastc.match?(/[ʿʾ]/); lastc=c}.join
    end

    # input: valid Precise string
    #   example: (al-)ʿAbbādī Muḥammad Ibn Aḥmad Ibn Muḥammad al-Harawī
    # output: Arabic string
    #   example: العَبّادي مُحَمَّد بن أَحمَد بن مُحَمَّد الهَرَوي
    def reverse(romanized)
      raise Precise::NotATranscriptionError if romanized.nil?

      # sure, it's called "Precise", but it should still be 
      # as tolerant as possible in what it accepts as input...
      romanized = sanitize(romanized)
      arabic = '' # we start with an empty string and go character by character

      puts "- (#{romanized.size}) [#{romanized}]".light_green if $dbg > 1

      # next, turn strings into character arrays
      romanized = romanized.chars
      arabic = arabic.chars
      # to be able to merge 2 romanized characters into 1 arabic character
      skip = false
      # print string like so: ʿ·A·b·b·ā·d·ī· ·M·u·ḥ·a·m·m·a·d· ·I·b·n· ·A·ḥ·m·a·d· ·I·b·n· ...
      puts "- (#{romanized.size}) [#{romanized.join('·')}]".light_green if $dbg > 1

      # loop over the romanized character array, filling the arabic one up as we go
      romanized.each_with_index do |ch,i|
        # a little bit of context
         pch = i == 0 ? nil : romanized[i-1]
         fch = romanized[i+1]
        ffch = romanized[i+2]

        # multi-letter skip-aheads
        if skip
          dbg "\t\tskipping #{ch}"
          if !(pch=='a' && fch=='-') # we're in the middle of "al-" (word-start)
            skip=false; end; next; end

        # symbols to remove from input
        (dbg "\tskipping unprintable symbol"; next) if [ZWNJ].include?(ch)

        # deal with alif madda before "normal" hamza rules follow
        if ("#{ch}#{fch}".match?(/ʾā/) || "#{pch}#{ch}".match?(/^Ā/))
          (dbg "\talif madda #{R2A['ʾā']}"; arabic << R2A['ʾā']; skip=true; next); end
        
        if pch.nil? || pch.match(/\s+/) 
          first_letter_of_word_upcase = (ch.dup.upcase == ch); end
        
        if (fch.nil? || fch.match(/\s+/)) && ch == 'a' && first_letter_of_word_upcase
          ch = '-a'; end
        
        # hamza followed by a short or long vowel
        if ch == 'ʾ' && %w[a i u ā ī ū].include?(fch.to_s.downcase)
          is_first_letter_of_word = (pch.nil? || pch.match(/\s+/))
          (dbg "\t#{ch} with following #{fch}";
           arabic << hamza_before_following(fch, pch, is_first_letter_of_word);
           skip=true unless this_word(romanized.join, i).match?(/(a$|at($|\s))/)
           next); end
        # hamza preceded by a short vowel
        # (beware of a possible alif madda (would be dealt with above, on the next round))
        if fch.to_s == 'ʾ' && !ffch.to_s.match?(/[āĀ]/) && %w[a i u].include?(ch.downcase)
          is_first_letter_of_word = (pch.nil? || pch.match(/\s+/))
          (dbg "\t#{fch} carried on or following preceding #{ch}"
           arabic << hamza_after_preceding(ch, is_first_letter_of_word); skip=true; next); end

        # find the article "al", marked by having a dash appended to it
        (dbg "\tarticle al- #{R2A['al-']}"; arabic << R2A['al-']; skip=true; next) if ("#{ch}#{fch}#{ffch}" == 'al-')

        # unconditionally add spaces, dots and dashes to the output
        (dbg "\tinitial only (#{pch}#{ch})"; arabic << ch; next) if ch=='.' && (fch.nil? || fch.match(/\s+/))
        (dbg "\tnon-letter (#{ch})"; arabic << ch; next) if ch.match(PunctSepRgx) # white space or punctuation

        # a word-initial "a" or "u" must always be preceded by "ʾ"; only "i" can possibly *not* have one

        # deal with word-initial special cases
        if pch.to_s.strip.empty? # either beginning of string or of word
          if %w[a u].include?(ch)  
            (dbg "\tprepending #{ch} with hamza"; arabic << R2A[ch.upcase]; next); end
          if ch == 'i'
            (dbg "\thamza-less alif?"
             context = this_word(romanized.join, i)
             arabic << alif_for_word_initial_kasra(context.split(/^w?al-/).last)
             next); end; end

        # perform tashdeed
        (out=R2A[ch]+Shadda; dbg "\ttashdeed of #{ch} #{out}"; arabic << out; skip = true; next) if R2A[ch] && ch==fch

        # should there be a ta'marbouta or not at the end of the word?
        context1 = this_word(romanized.join,i)
        context2 = this_word_and_the_next(romanized.join,i)
        if context1 == context2 # single word
          if (i == context1.length-2 && "#{ch}#{fch}".match?(/at$/)) \
             || (i == context1.length-1 && "#{ch}#{fch}".match?(/a$/))
             arabic << R2A['-at']+' '; skip=true; next
          end
        else # multiple words
          if (i == context1.length-2 && "#{ch}#{fch}#{ffch}".match?(/at\s/))
            arabic << R2A['-a']+' '; skip = true; next
          elsif (i == context1.length-1 && "#{ch}#{fch}".match?(/a\s/))
            arabic << R2A['-a']+' '; next
          end
        end

        # letter ayn followed by uppercase vowel
        if ch == 'ʿ'
          (skip=true; ar=R2A[ch]) if %w[A I U].include?(fch)
          case fch # ayn+following vowel at beginning of word
            when 'A' then ar+=Fatha
            when 'I' then ar+=Kasra
            when 'U' then ar+=Damma; end; end
        (dbg "\tayn+vowel #{ch}#{fch} #{ar}"; arabic << ar; next) if ar && ar.size==2

        # long "a" at word-end: alif maqsoorah, otherwise normal alif
        # "e" at word-end: letter hah, otherwise just a fatha
        if R2A[ch].class == Array
          choice = (fch.nil? || fch==' ') ? R2A[ch].first : R2A[ch].last
          (dbg "\tcontextual #{ch} #{choice}"; arabic << choice; next); end

        # exact match (pure transliteration, no transcription effort required)
        (dbg "\tfrom table #{ch}→#{R2A[ch]}"; arabic << R2A[ch]; next) if R2A[ch]

        # no luck yet; might be a regular uppercase letter
        (dbg "\tuppercased #{ch} #{R2A[ch.downcase]}"; arabic << R2A[ch.downcase]; next) if R2A[ch.downcase]

        # still no luck; last shot is punctuation
        (dbg "\tinterpunctuation #{ch}"; arabic << ch; next) if ch.match?(/[[:punct:]]/)

        # mark unknown characters as such; the philosophy here being that input to
        # Precise should be pre-processed enough for this to never have to happen…
        warn "Warning: character '#{ch}' is unknown to Precise and will be substituted by placeholder only".yellow
        arabic << '�'
      end

      # character-array to word-array
      arabic = arabic.compact.join.split
      # العأَبّادي محمّد إِبن أَحمد إِبن محمّد للهروي (but with () around "al")
      puts "- (#{arabic.join(' ').size-1}) [#{L2RM+arabic.join(' ')+L2RM}]".light_green if $dbg > 1

      # dragnet replacement of special words, such as changing "ibn" into "bin"
      2.times.each_with_index do |i|
        puts "#{' '*6}(postprocessing round #{i+1})".light_green if $dbg > 1
        PostR2AWordReplacements.each{|rgx,subst|
          arabic.map!{|w|
            puts "#{' '*8}word match: #{L2RM}#{rgx.inspect} #{L2RM}=> #{L2RM}'#{subst}'".green if (w.match(rgx) && $dbg > 1)
            w.gsub(/-/, '') # dashes not needed anymore now
             .gsub(rgx, subst)} }
      end

      # some rules apply only in the context of words, not letters
      puts "- (#{arabic.join(' ').size-1}) [#{L2RM+arabic.join(' ')+L2RM}]".light_green if $dbg > 1
      arabic = arabic.join(' ')
      PostR2AContextReplacements.each{|rgx,subst|
        puts "#{' '*8}context match: #{L2RM}#{rgx.inspect} #{L2RM}=> #{L2RM}'#{subst}'".green if (arabic.match(rgx) && $dbg > 1)
        arabic.gsub!(rgx, subst) }

      return arabic.apply_options(@opts)
    end

    def self.reverse(romanized, opts={})
      new(opts).reverse(romanized)
    end
  end
end

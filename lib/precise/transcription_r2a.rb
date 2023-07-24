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
      numbers: {
        '1':  :١,
        '2':  :٢,
        '3':  :٣,
        '4':  :٤,
        '5':  :٥,
        '6':  :٦,
        '7':  :٧,
        '8':  :٨,
        '9':  :٩,
        '0':  :٠
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
        ē:    :ا # is that always so?
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

    FullWordReplacements = {
      'allāh': 'الله',
      'addīn': 'الدين',
      'lillāh': 'لله',
      'li-llāh': 'لله',
      'ilāha': 'إله',
      'al-raḥmān': 'الرحمن',
      ',': '،'
    }

    PostR2AWordReplacements = 
    {
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

    def hamza_before_following(ch, pch, fch, first_letter_of_word = false)
      if first_letter_of_word
        case ch.to_sym
          when :a, :u then AlifHamzaAbove
          when :i then AlifHamzaBelow
          when :ī then "#{YaHamzaAbove}#{R2A[ch]}"
          when :ū then "#{WawHamzaAbove}#{R2A[ch]}"
        end
      else
        case ch.to_sym
          when :a then
            if fch == 'ī'
              YaHamzaAbove
            elsif pch == 'ā' 
              R2A['ʾ'] 
            elsif pch == 'y' || pch == 'ī'
              YaHamzaAbove
            else
              WawHamzaAbove
            end
          when :i then YaHamzaAbove
          when :u then
            pch == 'ū' ? R2A['ʾ'] : WawHamzaAbove
          when :ī then "#{YaHamzaAbove}#{R2A[ch]}"
          when :ū then "#{WawHamzaAbove}#{R2A[ch]}"
        end
      end
    end

    def hamza_after_preceding(ch, ffch, first_letter_of_word = false)
      if first_letter_of_word
        case ch.to_sym
          when :a then AlifHamzaAbove
          when :u then R2A['ā']+Damma+WawHamzaAbove
          when :i then R2A['ā']+YaHamzaAbove
        end
      else
        case ch.to_sym
          when :a then
            if ffch == 'ū'
              WawHamzaAbove
            elsif ffch == 'ī'
              YaHamzaAbove
            else
              AlifHamzaAbove
            end
          when :y then YaHamzaAbove
          when :i then YaHamzaAbove
          when :u then WawHamzaAbove
          when :w then WawHamzaAbove
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
      # FIXME: the erroneous_chars replacement table should have already taken care of this?! No, because it looked before and behind itself
      ["\u200c", "\u200f"].each{|ch| str.gsub! ch, ''}
      str
    end

    def sanitize_word(str)
      str.gsub!(/^Al\-/,'al-')
      # make letters following either ʿ or ʾ lowercase
      out = str.chars.map.with_index{|c,i| 
        if i > 0 && str.chars[i-1].match?(/[ʿʾ]/)
          c.downcase
        else
          c
        end
      }.join
      return out
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
      arabic = [] # we start with an empty array and go character by character

      puts "- (#{romanized.size}) [#{romanized}]".light_green if $dbg > 1
      words = romanized.split(/([\s\,\(]|addīn|allāh)/)
      # print string like so: ʿ·A·b·b·ā·d·ī· ·M·u·ḥ·a·m·m·a·d· ·I·b·n· ·A·ḥ·m·a·d· ·I·b·n· ...
      puts "- (#{words.size}) [#{words.join('·')}]".light_green if $dbg > 1
      words.each_with_index do |word,word_index|
        first_letter_of_word_upcase = true if word.match?(/^[ʾʿ][AIU]/) 
        sanitized_word = sanitize_word(word)
        downcaseword = sanitized_word.dup.downcase.to_sym
        if FullWordReplacements.keys.include?(downcaseword)
          arabic << ' ' if word_index > 0 && !words[word_index-1].match?(/^\s\($/)
          FullWordReplacements[downcaseword].chars{ |char| arabic << char}
          next
        end
        # neixt, turn word strings into character arrays
        roman_chars = sanitized_word.chars
        wordlength = roman_chars.length
        context = sanitized_word.dup
        first_letter_of_word = roman_chars[0]
        start_index = 0
        end_index = wordlength-1
        article = false
        no_ta_marbouta = false
        # to be able to merge 2 romanized characters into 1 arabic character
        skip = false
        # loop over the romanized character array, filling the arabic one up as we go
        roman_chars.each_with_index do |ch,i|
          # a little bit of context
          ppch = i < 2 ? nil : roman_chars[i-2]
          pch = i == 0 ? nil : roman_chars[i-1]
          fch = roman_chars[i+1]
          ffch = roman_chars[i+2]
   
          # symbols to remove from input
          (dbg "\tskipping unprintable symbol"; next) if [ZWNJ].include?(ch)
          
          is_first_letter_of_word = (i==start_index)
          is_last_letter_of_word = (i==end_index)
          #context2 is not needed at the moment
          #context2 = this_word_and_the_next(romanized.join,i)
          #if the word starts with brackets
          if context.start_with?('al-')||context.start_with?('wal-')||context.start_with?('lil-')
            (article = true; context.gsub!(/^[wl]?[ai]l\-\)?/,''); start_index = sanitized_word.scan(context).map{ |scan| $~.offset(0)[0] }[0]); end
            
          if context.start_with?('bil-') && i == 1
            (article = true; context.gsub!(/^bil\-\)?/,''); start_index = sanitized_word.scan(context).map{ |scan| $~.offset(0)[0] }[0]; arabic << R2A['al-']; skip=true; next); end
          
          if context.start_with?('wa-')||context.start_with?('li-')||context.start_with?('bi-')
            (context.gsub!(/^.{2}\-/,''); start_index = sanitized_word.scan(context).map{ |scan| $~.offset(0)[0] }[0]); end

          if context.end_with?('.')||context.end_with?(')')
            (end_index = wordlength-2; context.gsub!(/\.\)$/,'')); end

          if context.match?(/aʾat?$/) || context.match?(/^.āʾat?$/)
            no_ta_marbouta = true; end
          # multi-letter skip-aheads
          if skip
            dbg "\t\tskipping #{ch}"
            if !(pch=='a' && fch=='-') # we're in the middle of "al-" (word-start)
              skip=false; end; next; end
          
          if context.end_with?('llāh')
            if i+3 == end_index
              arabic << R2A['ā']+R2A['l']+R2A['l']
              skip = true
              next
            elsif i+1 == end_index
              next
            end
          end
          
          #find the article "al", marked by having a dash appended to it
          (dbg "\tarticle al- #{R2A['al-']}"; arabic << R2A['al-']; skip=true; next) if ("#{ch}#{fch}#{ffch}" == 'al-')

          # deal with word-initial special cases
          if is_first_letter_of_word # beginning of string or of word
            if ch == 'a'
              if context.end_with?('ī')
                arabic << Alif
                next
              else
                dbg "\tprepending #{ch} with hamza"
                arabic << R2A['A']
                next 
              end
            elsif ch.dup.downcase == 'ā'
              dbg "\talif madda #{R2A['ʾā']}"
              arabic << R2A['ʾā']
              next
            elsif ch == 'u'
              arabic << R2A['U']
            elsif ch == 'i'
              dbg "\thamza-less alif?"
              arabic << alif_for_word_initial_kasra(context)
              next
            elsif ch.dup.downcase == "ī"
              arabic << R2A['I']
              arabic << R2A[ch.downcase]
              next
            elsif ch.dup.downcase == 'ū'
              arabic << R2A['A']
              arabic << R2A[ch.downcase]
              next
            end
          end
          # deal with alif madda before "normal" hamza rules follow
          if "#{ch}#{fch}" == "ʾā"
            dbg "\talif madda #{R2A['ʾā']}"
            arabic << R2A['ʾā']
            skip=true
            next
          end
          
          # hamza followed by a short or long vowel
          if ch == 'ʾ' && %w[a i u ī ū].include?(fch)
            (dbg "\t#{ch} with following #{fch}";
             arabic << hamza_before_following(fch, pch, ffch, is_first_letter_of_word);
             skip=true unless context.match?(/at?$/);
             next); end
          # hamza preceded by a short vowel
          # (beware of a possible alif madda (would be dealt with above, on the next round))
          if fch.to_s == 'ʾ' && (%w[i u y w].include?(ch)||(ch == 'a' && ffch != 'ā'))
            (dbg "\t#{fch} carried on or following preceding #{ch}"
            arabic << hamza_after_preceding(ch, ffch, is_first_letter_of_word); skip=true; next); end
         
          # unconditionally add spaces, dots and dashes to the output
          (dbg "\tinitial only (#{pch}#{ch})"; arabic << ch; next) if ch=='.' && (fch.nil? || fch.match(/\s+/))
          (dbg "\tnon-letter (#{ch})"; arabic << ch; next) if ch.match(PunctSepRgx) # white space or punctuation 

          #now look again at first letter of word
          if context.match?(/^[ʾʿ]/)
            start_index = sanitized_word.scan(context).map{ |scan| $~.offset(0)[0] }[0]
          end
        
          first_letter_of_word = ch.dup if is_first_letter_of_word
          first_letter_of_word_upcase = (first_letter_of_word == first_letter_of_word.dup.upcase) unless first_letter_of_word_upcase
          # a word-initial "a" or "u" must always be preceded by "ʾ"; only "i" can possibly *not* have one 
          # perform tashdeed
          
          (out=R2A[ch]+Shadda; dbg "\ttashdeed of #{ch} #{out}"; arabic << out; skip = true; next) if R2A[ch] && R2A[ch].class == String && ch==fch
          # should there be a ta'marbouta or not at the end of the word?
          if ch == 'a' && (first_letter_of_word_upcase||article||context.end_with?('iyya')||context.end_with?('īya')||(pch == 'ʾ' && !no_ta_marbouta ))
            if is_last_letter_of_word
              arabic << R2A['-a']+' '; next
            elsif i == wordlength-2 && fch == 't'
              arabic << R2A['-a']; skip=true; next
            end
          end
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

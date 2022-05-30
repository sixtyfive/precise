module Precise
  
  using CoreExtensions # the more generic ones

  class Transcription    
    def transcription
      @out_chunks
        .map{|c| c
          .gsub(/^m$/, 'mīlādī')
          .gsub(/^h$/, 'hijrī')
          .gsub(/^wāltī$/, 'wa-l-lātī')
          .gsub(/^wālḏī$/, 'wa-l-lāḏī')
          .gsub(/^hy$/, 'hiya')
          .gsub(/^ʿlá$/, 'ʿalá')
          .gsub(/^mn$/, 'min')
          .gsub(/^yd$/, 'yad')
          .gsub(/^fy$/, 'fī')
          .gsub(/^lhā$/, 'lahā')}
        .join(' ')
        .gsub('؟','?')
        .gsub('،',',')
        .gsub(/\s+([[:punct:]]+)/,'\1')
        .gsub(/(?!(\s+|^))\(\s+/, ' (')
    end
    
    A2R = A2RTable = {
      "ال": "al-",
      "ء": "ʾ",
      "آ": "ʾā",
      "أ": "ʾa",
      "أُ": "ʾu",
      "إ": "ʾi",
      "ا": "ā",
      "ب": "b",
      "ة": "a",
      "ت": "t",
      "ث": "ṯ",
      "ج": "ǧ",
      "ح": "ḥ",
      "خ": "ḫ",
      "د": "d",
      "ذ": "ḏ",
      "ر": "r",
      "ز": "z",
      "س": "s",
      "ش": "š",
      "ص": "ṣ",
      "ض": "ḍ",
      "ط": "ṭ",
      "ظ": "ẓ",
      "ع": "ʿ",
      "غ": "ġ",
      "ف": "f",
      "ق": "q",
      "ك": "k",
      "ل": "l",
      "م": "m",
      "ن": "n",
      "ه": "h",
      "و": ["ū", "w"],
      "ى": "á",
      "ي": ["ī", "y"],
      "َ": "à",
      "ُ": "u",
      "ِ": "i",
      "پ": "p",
      "چ": "č",
      "ژ": "ž",
      "گ": "g",
      "٠": "0",
      "١": "1",
      "٢": "2",
      "٣": "3",
      "٤": "4",
      "٥": "5",
      "٦": "6",
      "٧": "7",
      "٨": "8",
      "٩": "9",
    }.map{|k,v| [k.to_s, v]}.to_h

    def transcribe(arabic)
      non_word_rgx = /([\s\d[:punct:]]+)/
      in_chunks = arabic.split non_word_rgx
      in_chunks.each.with_index do |chunk,i|
        word = chunk
        (next) if chunk.strip.empty?
        (@out_chunks << chunk.strip; next) if chunk.match? non_word_rgx
        chars = chunk.chars
        skip = 0
        (@out_chunks << '')
        chars.each.with_index do |ch,j|
          (skip-=1; next) if skip>0
          (@out_chunks.last << A2R['ال']; skip+=1; next) if j==0 && word.match?(/^ال/)
          out_char = nil
          # و and ي:
          # first in array is a long vowel,
          # second in array is a consonant
          if A2R[ch].class==Array
            if j==0 || j+1==word.length
              (@out_chunks.last << A2R[ch].last; next)
            else
              out_char = A2R[ch].first
            end
          else
            out_char = A2R[ch]
          end
          (@out_chunks.last << out_char; next) if out_char
        end
      end
    end

    def self.transcribe(arabic, opts={})
      warn "Warning: Romanisation is experimental and incomplete!".yellow
      warn "Especially consider adding short vowels by hand as needed.".yellow
      obj = new(opts)
      obj.transcribe(arabic)
      return obj.transcription
    end
  end
end
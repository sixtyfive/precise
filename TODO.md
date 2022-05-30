Refactor to follow the following pattern:

```ruby

# short, romanised root <=> word list for learners: https://wahiduddin.net/words/arabic_glossary.htm
# commercial root <=> word dict: http://www.arabicroot.com/Home/Introduction
# possibly a good idea to OCR wehr 5 and make a dict from that?

def arabic_roots(opts); ['ʿwl','msʾ'].reject{|r| !r.include? opts[:with_letter]}.compact; end # 

# 2005: http://jeffcoombs.com/isri/Taghva2005b.pdf
# 2006: NN-based: https://ieeexplore.ieee.org/document/4115547
# 2007: https://ieeexplore.ieee.org/document/4230974/
# 2014: https://journals.sagepub.com/doi/abs/10.1177/0165551514526348?journalCode=jisb
# 2016: https://www.sciencedirect.com/science/article/pii/S1319157815001342
# 2015: https://www.sciencedirect.com/science/article/pii/S1319157815000166
# metastudy (also 2015): https://www.sciencedirect.com/science/article/pii/S1319157815000166
# 2017: https://www.accentsjournals.org/PaperDirectory/Journal/IJACR/2018/3/3.pdf
# anything newer???
# some of the above testable at: http://arabic.emi.ac.ma:8080/SafarWeb/faces/safar/morphology/stemmer.xhtml

def extract_root(word); {'ʿāʾila':'ʿwl','masāʾikà':'msʾ'}[word.to_sym]; end

# with the above two in place:

arabic = %w[ʿāʾila masāʾikà].map{|s|
  words = s.split ' '
  words.map{|w|
    w.gsub! /āʾi/, arabic_roots(with_letter: 'ʾ').include?(extract_root(w)) ? 'āSTANDALONE_HAMZAi' : 'āYA_AS_HAMZA_CARRIERi'
    [
      {'YA_AS_HAMZA_CARRIER':'ﺉ', 'STANDALONE_HAMZA':'ﺀ'},
      {'ʿ':'ﻉ', 'ā':'ﺍ', 'i':'ِ◌', 'l':'ﻝ', 'a':'َ◌', 'm':'ﻡ', 's':'ﺱ', 'k':'ﻙ', 'à':'َ◌'}
    ].each{|list| list.each{|k,v| w.gsub! k.to_s, v}}
    w.gsub! /◌$/, 'ﺓ'
  }
  words.join(' ').gsub('◌','')
}

# use actual tests from current code instead; also generate more from existing known-good data!

tests = (arabic == ["ﻉﺎﺌِﻟَﺓ", "ﻢَﺳﺍﺀِﻙَﺓ"])
```

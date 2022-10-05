# frozen_string_literal: true

require "test_helper"
using CoreExtensions

class Precise::TestPrecise < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Precise::VERSION
  end

  REVERSE_TRANSCRIPTION_OPTS = {
    punctuation: false,
    tashkeel: false,
    alif_variants: true,
    verbosity: 0
  }

  SINGLE_WORD_STRINGS = {
    'kura': 'كُرَة',
    'sayyāra': 'سَيَّارَة',
    'makkūk': 'مَكُّوك',
    'ḥāfila': 'حَافِلَة',
    'safīna': 'سَفِينَة',
    'muḥammad': 'مُحَمَّد',
    'aḥmad': 'أَحْمَد',
    'ʾaḥmad': 'أَحْمَد',
    'ʾislām': 'إِسْلَام',
    'al-Islām': 'الإِسْلَام',
    'istiqlāl': 'اِسْتِقْلَال', # independence
    'ʾusāma': 'أُسَامَة',
    'ʾihāb': 'إِهَاب',
    'mūsá': 'مُوسَى',
    'iḍḍuṭarrà': 'َّاِضُّطَر', # sich zwingen
    'laʾāliʾ': 'لَآلِئ', # perlen
    'luʾluʾ': 'لُؤْلُؤ', # perle
    'mutalaʾliʾ': 'مُتَلَأْلِئ', # to shine like a pearl (a person's eyes)
    'takaʾkaʾtum': 'تَكَأْكَأْتُم', # ihr wart feige ("ihr feigtet")
    'iʾtamarà': 'اِئْتَمَر', # er hat den befehl ausgeführt
    'uʾmaru': 'اُؤْمَرُ', # ich bekomme einen befehl
    'hayʾa': 'هَيْئَة',
    'tahayyuʾ': 'تَهَيُّؤ', # bereit sein, etwas zu machen; sich etwas vorstellen
    'musīʾ': 'مُسِيء',
    'fayʾ': 'فَيْء',
    'wuḍūʾukà': 'وُضُوءُكَ',
    'wuḍūʾī': 'وُضُوئِي',
    'ḍawʾī': 'ضَوْئِي',
    'masāʾunā': 'مَسَاؤُنَا',
    'masāʾinā': 'مَسَائِنَا',
    'wuḍūʾ': 'وُضُوء',
    'masāʾ': 'مَسَاء',
    'mufāǧaʾa': 'مُفَاجَأَة',
    'ḫabīʾat': 'خَبِيئَة',
    'ḫabīʾat al-ʾanbiāʾ': 'خَبِيئَة الأَنْبِاء',
    'ḫabīʾa al-ʾanbiāʾ': 'خَبِيئَة الأَنْبِاء',
    'bīʾa': 'بِيئَة',
    # TODO:
    # getting these right would involve knowing with some good certainty what
    # their root letters are, so it's something better left for another time...
    # 'samawʾal': 'سَمَوْءَل',
    # 'masāʾanā': 'مَسَاءَنَا',
  }

  def test_lowercase_single_word_strings
    SINGLE_WORD_STRINGS.each{|romanized,arabic|
    unvowelized_arabic = arabic.gsub(/[#{Precise::Transcription::Tashkeel.join}]/, '')
      reverse_transcription = Precise::Transcription.reverse(romanized.to_s, REVERSE_TRANSCRIPTION_OPTS)
      assert_equal unvowelized_arabic, reverse_transcription
    }
  end

  def test_titlecase_single_word_strings
    SINGLE_WORD_STRINGS.each{|romanized,arabic|
      unvowelized_arabic = arabic.gsub(/[#{Precise::Transcription::Tashkeel.join}]/, '')
      titlecased_romanization = romanized.to_s.precise_titlecase
      reverse_transcription = Precise::Transcription.reverse(titlecased_romanization, REVERSE_TRANSCRIPTION_OPTS)
      assert_equal unvowelized_arabic, reverse_transcription
    }
  end
end

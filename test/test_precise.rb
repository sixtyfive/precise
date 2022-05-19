# frozen_string_literal: true

require "test_helper"

class Precise::TestPrecise < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Precise::VERSION
  end

  def test_single_word_strings
    opts = {punctuation: false, tashkeel: false, alif_variants: true, verbosity: 0}
    {
      'muḥammad': 'محمد',
      'aḥmad': 'أحمد',
      'Aḥmad': 'أحمد',
      'ʾaḥmad': 'أحمد',
      'ʾAḥmad': 'أحمد',
      'ʾislām': 'إسلام',
      'al-Islām': 'الإسلام',
      'istiqlāl': 'استقلال', # independence
      'ʾUsāma': 'أسامة',
      'ʾIhāb': 'إهاب',
      'ʾusāma': 'أسامة',
      'ʾihāb': 'إهاب',
      'mūsá': 'موسى',
      'iḍḍuṭarr': 'اضطر', # sich zwingen - TODO: "a" anfügen!
      'laʾāliʾ': 'لآلئ', # perlen
      'luʾluʾ': 'لؤلؤ', # perle
      'mutalaʾliʾ': 'متلألئ', # to shine like a pearl (a person's eyes)
      'takaʾkaʾtum': 'تكأكأتم', # ihr wart feige ("ihr feigtet")
      'tahayyuʾ': 'تهيؤ', # bereit sein, etwas zu machen; sich etwas vorstellen
      # 'iʾtamar': 'ائتمر', # er hat den befehl ausgeführt - TODO: "a" anfügen! FIXME!
      # 'uʾmaru': 'اؤمر', # ich bekomme einen befehl - FIXME!
    }.each{|romanized,arabic|
      assert_equal \
        arabic, Precise::Transcription.reverse(romanized.to_s, opts)
    }
  end
end
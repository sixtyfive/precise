# frozen_string_literal: true

require "test_helper"

class Precise::TestPrecise < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Precise::VERSION
  end

  def test_single_word_strings
    opts = {punctuation: false, tashkeel: false, alif_variants: true, verbosity: 0}
    {
      'Muḥammad': 'محمد',
      'Aḥmad': 'أحمد'
    }.each{|romanized,arabic|
      assert_equal \
        arabic, Precise::Transcription.reverse(romanized.to_s, opts)
    }
  end
end

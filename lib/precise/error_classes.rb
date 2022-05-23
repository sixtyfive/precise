module ErrorClasses  
  class TranscriptionError < StandardError
    def initialize(msg="unable to transcribe input string", exception_type=:untranscribable)
      @exception_type = exception_type
      super(msg)
    end
    attr_reader :exception_type
  end

  class NotATranscriptionError < StandardError
    def initialize(msg="input string is not a romanisation of Arabic", exception_type=:untranscribable)
      @exception_type = exception_type
      super(msg)
    end
    attr_reader :exception_type
  end
end
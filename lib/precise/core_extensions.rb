module CoreExtensions
  refine String do
    def precise_titlecase
      s = chars
      s.map.with_index{|c,i|
        !%w[a i u].include?(s[0]) && ((i==0 && self[0..1] != 'al') || (i==1 && %w[ʾ ʿ].include?(s[0]))) ? 
          c.upcase :
          c
      }.join
    end
  end

  refine Array do
    def each_utf8_encode
      map{|e| e.to_s.encode('utf-8')}
    end
  end

  refine Hash do
    def keys_and_values_to_s
      map{|k,v| [k.to_s, v.class == Array ? v.map{|e| e.to_s} : v.to_s]}.to_h
    end
  end
end
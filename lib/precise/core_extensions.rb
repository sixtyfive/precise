module CoreExtensions
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
unless self.respond_to?(:dbg); $dbg = 0; def dbg str; puts str if $dbg > 0; end; end
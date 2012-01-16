module WLang
  class Generator < Temple::Generator

    class IdGen
      def initialize; @current = 0;  end
      def next;       @current += 1; end
      def to_s;       @current.to_s; end
    end

    def idgen
      options[:idgen] ? options[:idgen] : (@idgen ||= IdGen.new)
    end
    
    def myid
      options[:myid] || 0
    end
    
    def dialect
      options[:dialect] or raise "Dialect not set"
    end

    def braces
      ["{", "}"]
    end

    def call(x)
      compile(x)
    end
    
    def on_wlang(symbols, *procs)
      if meth = dialect.method_for(symbols)
        procs  = procs.map{|p| call(p)}.join(', ')
        call [:dynamic, "d#{myid}.#{meth}(#{procs})"]
      else
        call [:multi,
               [:static, "#{symbols}#{braces.first}"],
               [:multi,  procs.map(&last)],
               [:static, braces.last] ]
      end
    end

    def on_proc(code)
      id   = idgen.next
      gen  = Generator.new(:buffer => "b#{id}", :idgen => idgen, :myid => id)
      code = gen.call(code)
      "lambda{|d#{id},b#{id}| #{code} }"
    end

    def on_dynamic(code)
      concat(code)
    end
    
  end # class Generator
end # module WLang
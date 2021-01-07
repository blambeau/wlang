module WLang
  class Scope

    attr_reader :subject
    attr_reader :parent

    def initialize(subject)
      @subject = subject
      @parent  = nil
    end

    def self.null
      @null ||= NullScope.new
    end

    def self.coerce(arg)
      case arg
        when Hash       then ObjectScope.new(arg)
        when Scope      then arg
        when SinatraApp then SinatraScope.new(arg)
        when Binding    then BindingScope.new(arg)
        when Proc       then ProcScope.new(arg)
        else
          ObjectScope.new(arg)
      end
    end

    def self.chain(scopes)
      scopes.compact.inject(Scope.null){|p,c| p.push(c)}
    end

    def root
      parent ? parent.root : self
    end

    def push(x)
      append(Scope.coerce(x))
    end

    def pop
      @parent
    end

    def with(x)
      yield(self.push(x))
    end

    def evaluate(expr, dialect, *default, &bl)
      expr = expr.to_s.strip
      unfound = lambda do
        if default.empty?
          bl ? bl.call(expr) : throw(:fail)
        else
          default.first
        end
      end
      if expr.index('.').nil?
        fetch(expr.to_sym, dialect, unfound)
      else
        keys = expr.split('.').map(&:to_sym)
        keys.inject(self){|scope,key|
          found = scope.fetch(key, dialect, unfound)
          Scope.coerce(found)
        }.subject
      end
    end

    def subjects
      arr = []
      visit(:top_down){|s| arr << s.subject}
      arr
    end

    protected

      def visit(mode = :top_down, &visitor)
        visitor.call(self) unless mode == :top_down
        parent.visit(mode, &visitor) if parent
        visitor.call(self) if mode == :top_down
      end

      def append(x)
        x.prepend(self)
      end

      def prepend(x)
        newp = parent ? parent.prepend(x) : x
        dup.with_parent!(newp)
      end

      def with_parent!(p)
        @parent = p
        self
      end

      def safe_parent
        parent || Scope.null
      end

  end # class Scope
end # module WLang
require 'wlang/scope/null_scope'
require 'wlang/scope/object_scope'
require 'wlang/scope/binding_scope'
require 'wlang/scope/proc_scope'
require 'wlang/scope/sinatra_scope'

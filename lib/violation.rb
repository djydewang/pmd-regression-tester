module Pmdtester
  class Violation

    attr_reader :id
    attr_reader :violation

    def initialize(violation, id)
      @violation, @id = violation, id
    end

    def get_line
      @violation.attributes["beginline"].to_i
    end

    def match?(that)
      violation = that.violation
      @violation.attributes["rule"].eql?(violation.attributes["rule"]) &&
          @violation.text.eql?(violation.text)
    end

    def equal?(that)
      self.get_line == that.get_line
    end

    def less?(that)
      self.get_line < that.get_line
    end
  end
end
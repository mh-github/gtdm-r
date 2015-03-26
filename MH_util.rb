module MH_util
    Tuple = Struct.new(:first, :second) do
        def <=>(other)
            return second <=> other.second if first == other.first
            first <=> other.first
        end

        def to_s
            "(#{first}, #{second})"
        end
    end
    
    def my_strip(string, chars)
        chars = Regexp.escape(chars)
        string.gsub(/\A[#{chars}]+|[#{chars}]+\z/, "")
    end
end
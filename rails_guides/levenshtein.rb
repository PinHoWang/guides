module RailsGuides
  module Levenshtein
    # Based on the pseudocode in http://en.wikipedia.org/wiki/Levenshtein_distance
    def self.distance(s1, s2)
      s = str1
      t = str2
      n = s.length
      m = t.length

      return m if (0 == n)
      return n if (0 == m)

      d = (0..m).to_a
      x = nil

      str1.each_char.each_with_index do |char1,i|
        e = i+1

        str2.each_char.each_with_index do |char2,j|
          cost = (char1 == char2) ? 0 : 1
          x = [
               d[j+1] + 1, # insertion
               e + 1,      # deletion
               d[j] + cost # substitution
              ].min
          d[j] = e
          e = x
        end

        d[m] = x
      end

      return x
    end
  end
end

module Pmdtester
  class DiffBuilder

    def initialize
      #TODO
    end

    def diff_violations(base_violations, patch_violations)
      i, j = 0, 0
      diff = Array.new
      while i < base_violations.size && j < patch_violations.size
        if base_violations[i].less?(patch_violations[j])
          diff.push base_violations[i]
          i += 1
        elsif base_violations[i].equal?(patch_violations[j])
          if base_violations[i].match?(patch_violations[j])
            i += 1
            j += 1
          else
            line = base_violations[i].get_line

            base_i = i
            while base_i < base_violations.size && base_violations[base_i].get_line == line
              patch_j = j
              is_different = true
              while patch_j < patch_violations.size && patch_violations[patch_j].get_line == line
                if base_violations[base_i].match?patch_violations[patch_j]
                  is_different = false
                  patch_violations.delete_at(patch_j)
                  break
                end
                patch_j += 1
              end
              if is_different
                diff.push base_violations[base_i]
              end
              base_i += 1
            end

            i = base_i
          end
        else
          diff.push patch_violations[j]
          j += 1
        end
      end

      while i < base_violations.size
        diff.push base_violations[i]
        i += 1
      end

      while j < patch_violations.size
        diff.push patch_violations[j]
        j += 1
      end
      diff
    end

    def analysis_diffs(base_file, patch_file)
      base_xml_file = File.new base_file
      base_xml_doc = Document.new base_xml_file
      patch_xml_file = File.new patch_file
      patch_xml_doc = Document.new patch_xml_file

      diff = Hash.new

      base_xml_doc.elements.each("pmd/file") do |file|
        filename = file.attributes["name"].to_s
        violations = Array.new
        file.elements.each("violation") do |v|
          violations.push Violation.new(v, "base")
        end
        diff.store filename, violations
      end

      patch_xml_doc.elements.each("pmd/file") do |file|
        filename = file.attributes["name"].to_s

        violations = Array.new
        file.elements.each("violation") do |v|
          violations.push(Violation.new(v, "patch"))
        end

        if !diff.has_key?(filename)
          diff.store filename, violations
        elsif (diff[filename] = diff_violations(diff[filename], violations)).empty?
          diff.delete filename
        end
      end

      diff
    end
  end
end
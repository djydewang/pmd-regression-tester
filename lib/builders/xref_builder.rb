module Pmdtester
  class XrefBuilder

    def initialize
      #TODO
    end

    def generate_xref_file(file_name, xref_dir)
      file_xref_dir = xref_dir + file_name.gsub(/[A-Za-z]*\.java/, "/")
      FileUtils::mkdir_p(file_xref_dir) unless File.directory?(file_xref_dir)
      xref_file = File.new(xref_dir + file_name + ".html", "w")

      line_number = 1
      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.body {
            doc.pre {
              IO.foreach(file_name) do |line|
                doc.p {
                  doc.a(:href => "#L#{line_number}") {
                    doc.text line_number.to_s.chomp
                  }
                  doc.text line
                }
                line_number += 1
              end
            }
          }
        }
      end
      xref_file.puts builder.to_html
    end
  end
end
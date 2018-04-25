require 'nokogiri'

module Pmdtester
  class HtmlReportBuilder

    def initialize(project, diff)
      @project = project
      @diff = diff
    end

    def builder_html_report
      project_dir = "reports/diff/#{@project.name}"
      xref_dir = project_dir + "/xref"

      Dir.mkdir xref_dir unless File::directory?(xref_dir)
      Dir.mkdir(project_dir) unless File::directory?(project_dir)
      index = File.new("#{project_dir}/index.html", "w")

      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head {
            doc.title {
              doc.text "pmd xml difference report"
            }
            doc.style(:type => 'text/css', :media => 'all'){
              doc.text "@import url(\"./css/maven-base.css\");@import url(\"./css/maven-theme.css\");"
            }
          }
          doc.body(:class => "compsite") {
            doc.div(:id => "cententBox") {
              doc.div(:id => "section") {
                doc.h2(:a => "Violations:") {
                  doc.text "Violations:"
                }
                a_index = 1
                @diff.each do |key, value|
                  doc.div(:class => "section") {
                    doc.h3 key
                    doc.table(:class => "bodyTable", :border => "0") {
                      doc.tbody {
                        doc.tr {
                          doc.th
                          doc.th "priority"
                          doc.th "Rule"
                          doc.th "Message"
                          doc.th "Line"
                        }
                        generate_xref_file key, xref_dir
                        value.each do |v|
                          doc.tr(:class => v.get_id == "base" ? "a" : "b") {
                            doc.td {
                              doc.a(:name => "A#{a_index}", :href => "#A#{a_index}") {
                                doc.text "#"
                              }
                            }
                            a_index += 1
                            violation = v.get_violation
                            doc.td violation.attributes["priority"]
                            doc.td violation.attributes["rule"]
                            doc.td violation.text
                            line = violation.attributes["beginline"]
                            doc.td {
                              doc.a(:href => "xref#{key}.html#L#{line}") {
                                doc.text line
                              }
                            }
                          }
                        end
                      }
                    }
                  }
                end
              }
            }
          }
        }
      end

      index.puts builder.to_html
      index.close

    end
  end
end
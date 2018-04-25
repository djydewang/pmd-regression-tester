#!/usr/bin/ruby -w

require "fileutils"
require "nokogiri"
require "slop"
require "rexml/document"
include REXML

$projects_list = Array.new
$pwd = Dir.getwd
$cli_options = Slop.parse do |o|
  o.string '-r', '--LocalGitRepo', 'path to the local PMD repository'
  o.string '-b', '--baseBranch', 'name of the base branch in local PMD repository'
  o.string '-p', '--patchBranch', 'name of the patch branch in local PMD repository'
  o.string '-bc', '--baseConfig', 'path to the base PMD configuration file'
  o.string '-pc', '--patchConfig', 'path to the patch PMD configuration file'
  o.string '-l', '--listOfProjects', 'path to the file which contains the list of standard projects'
  o.string '-m', '--mode', "the mode of the tool: 'local', 'online' or 'single'\n" +
                           "\tsingle: Set this option to 'single' if your patch branch contains changes for any option that can't work on master/base branch\n" +
                           "\tonline: Set this option to 'online' if you want to download the PMD report of master/base branch rather than generating it locally\n" +
                           "\tlocal: Default option is 'local'"
  o.on '-v', '--version' do
    puts '1.0.0'
    exit
  end
  o.on '-h', '--help' do
    puts o
    exit
  end
end

def are_vaild_cli_options
  #TODO
  true
end

def get_projects_list
  IO.foreach($cli_options[:listOfProjects]) do |line|
    #skip empty line and comment in projectList file
    if line.to_s.start_with?('#') || line.to_s.start_with?("\n")
      next
    end

    project = line.to_s.split('|')
    #check whether repo type is valid
    if !project[1].eql?('git') && !project[1].eql?('hg')
      puts "warning! Unknow #{project[1]} repository"
      next
    end

    $projects_list.push project
  end
end

def get_pmd_binary_file(branch_name)
  Dir.chdir($cli_options[:LocalGitRepo])
  `git checkout #{branch_name}`
  `./mvnw clean package -Dpmd.test.skip=true -Dpmd.skip=true`
  pmd_version = `./mvnw -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec | tail -1`.chomp
  `unzip -qo pmd-dist/target/pmd-bin-#{pmd_version}.zip -d #{$pwd}`
  Dir.chdir($pwd)
  pmd_version
end

def generate_pmd_report(version, src_root_dir, format, rule_sets, report_file)
  `pmd-bin-#{version}/bin/run.sh pmd -d #{src_root_dir} -f #{format} -R #{rule_sets} -r #{report_file}`
  if $? == 1
    puts "Error! Generating pmd report failed"
  end
end

def generate_pmd_reports(branch_name, branch_config)
  puts "Generating pmd Report started -- branch #{branch_name}"
  version = get_pmd_binary_file branch_name
  $projects_list.each do |project|

    `#{project[1]} clone #{project[2]} repositories/#{project[0]}` unless File::exist?("repositories/#{project[0]}")

    branch_file = branch_name.delete("/")
    Dir.mkdir("reports/#{branch_file}") unless File::directory?("reports/#{branch_file}")

    generate_pmd_report version, "repositories/#{project[0]}", "xml", branch_config, "reports/#{branch_file}/#{project[0]}.xml"
  end
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

def generate_html_report(project, diff)
  project_dir = "reports/diff/#{project[0]}"
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
            diff.each do |key, value|
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

def generate_diff_reports(base_branch, patch_branch)
  $projects_list.each do |project|

    Dir.mkdir("reports/diff") unless File::directory?("reports/diff")

    diff  = analysis_diffs "reports/#{base_branch}/#{project[0]}.xml", "reports/#{patch_branch.delete("/")}/#{project[0]}.xml"
    generate_html_report project, diff
  end
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

class Violation
  def initialize(violation, id)
    @violation, @id = violation, id
  end

  def get_violation
    @violation
  end

  def get_id
    @id
  end

  def get_line
    @violation.attributes["beginline"].to_i
  end

  def match?(violation)
    violation = violation.get_violation
    @violation.attributes["rule"].eql?(violation.attributes["rule"]) &&
        @violation.text.eql?(violation.text)
  end

  def equal?(violation)
    self.get_line == violation.get_line
  end

  def less?(violation)
    self.get_line < violation.get_line
  end
end

get_projects_list
#generate_pmd_reports $cli_options[:baseBranch], $cli_options[:baseConfig]
#generate_pmd_reports $cli_options[:patchBranch], $cli_options[:patchConfig]
#generate_diff_reports $cli_options[:baseBranch], $cli_options[:patchBranch]

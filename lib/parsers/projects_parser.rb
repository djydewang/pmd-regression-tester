require_relative '../project'

Module Pmdtester
class ProjectsParser

  @projects = Array.new
  attr_reader projects

  def initialize(list_file)
    IO.foreach list_file do |line|
      #skip empty line and comment in projectList file
      if line.to_s.start_with?('#') || line.to_s.start_with?("\n")
        next
      end

      @projects.push Project.new(line.to_s.delete( " ", "\n"))

    end
  end
end
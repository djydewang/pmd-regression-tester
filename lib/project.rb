module Pmdtester
  class Project

    attr_reader :name
    attr_reader :repo_type
    attr_reader :repo_uri
    attr_reader :commit_id
    attr_reader :exclude_pattern

    def initialize(project)
      @name = project[0]
      @repo_type = project[1]
      @repo_uri = project[2]
      @commit_id = project[3]
      @exclude_pattern = project[4]
    end
  end
end

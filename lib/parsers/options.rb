module Pmdtester
  class Options

    attr_reader :local_git_repo
    attr_reader :base_branch
    attr_reader :patch_branch
    attr_reader :base_config
    attr_reader :patch_config
    attr_reader :project_list
    attr_reader :mode

    def initialize(argv)
      options = parse(argv)
      @local_git_repo = options[:LocalGitRepo]
      @base_branch = options[:baseBranch]
      @patch_branch = options[:patchBranch]
      @base_config = options[:baseConfig]
      @patch_branch = options[:patchConfig]
      @project_list = options[:listOfProjects]
      @mode = options[:mode]
    end

    private

    def parse(argv)
      Slop.parse argv do |o|
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
    end
  end
end
#!/usr/bin/ruby

require "slop"

$pwd = Dir.getwd
$cliOptions = Slop.parse do |o|
  o.string '-r', '--LocalGitRepo', 'path to the local PMD repository', required: true
  o.string '-b', '--baseBranch', 'name of the base branch in local PMD repository'
  o.string '-p', '--patchBranch', 'name of the patch branch in local PMD repository', required: true
  o.string '-bc', '--baseConfig', 'path to the base PMD configuration file'
  o.string '-pc', '--patchConfig', 'path to the patch PMD configuration file', required: true
  o.string '-l', '--listOfProjects', 'path to the file which contains the list of standard projects', required: true
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

def areVaildCliOptions()
  #TODO
  true
end

def generatePmdReport(version, srcRootDir, format, rulesets, reportFile)
  `pmd-bin-#{version}/bin/run.sh pmd -d #{srcRootDir} -f #{format} -R #{rulesets} -r #{reportFile}`
  puts $?
  if ($? != 0)
    puts "Error! Generating pmd report failed"
  end
end

def generateDiffReport(baseBranch, patchBranch)
  IO.foreach($cliOptions[:listOfProjects]) do |line|
    #skip empty line and comment in projectList file
    if (line.to_s.start_with?('#') || line.to_s.start_with?("\n"))
      next
    end

    project = line.to_s.split('|')
    #check whether repo type is valid
    if (!project[1].eql?('git') && !project[1].eql?('hg'))
      next
    end

    if (!File::directory?("reports/diff"))
      Dir.mkdir("reports/diff")
    end
    `diff reports/#{baseBranch}/#{project[0]}.txt reports/#{patchBranch.delete("/")}/#{project[0]}.txt > reports/diff/#{project[0]}.txt`
  end
end

def generatePmdReports(branchName, branchConfig)
  puts "Generating pmd Report started -- branch #{branchName}"
  version = getPmdBinaryFile branchName
  IO.foreach($cliOptions[:listOfProjects]) do |line|
    #skip empty line and comment in projectList file
    if (line.to_s.start_with?('#') || line.to_s.start_with?("\n"))
      next
    end

    project = line.to_s.split('|')
    #check whether repo type is valid
    if (!project[1].eql?('git') && !project[1].eql?('hg'))
      puts "warning! Unknow #{project[1]} repository"
      next
    end

    if (!File::exist?("repositories/#{project[0]}"))
      `#{project[1]} clone #{project[2]} repositories/#{project[0]}`
    end

    branchFile = branchName.delete("/")
    if (!File::directory?("reports/#{branchFile}"))
      Dir.mkdir("reports/#{branchFile}")
    end
    generatePmdReport version, "repositories/#{project[0]}", "text", branchConfig, "reports/#{branchFile}/#{project[0]}.txt"
  end
end

def getPmdBinaryFile(branchName)
  Dir.chdir($cliOptions[:LocalGitRepo])
  `git checkout #{branchName}`
  `./mvnw clean verify -Dpmd.skip=true`
  pmdVersion = `./mvnw -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec | tail -1`.chomp
  `unzip -qo pmd-dist/target/pmd-bin-#{pmdVersion}.zip -d #{$pwd}`
  Dir.chdir($pwd)
  pmdVersion
end

generatePmdReports $cliOptions[:baseBranch], $cliOptions[:baseConfig]
generatePmdReports $cliOptions[:patchBranch], $cliOptions[:patchConfig]
generateDiffReport $cliOptions[:baseBranch], $cliOptions[:patchBranch]

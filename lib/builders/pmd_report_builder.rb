module Pmdteser
  class PmdReportBuilder

    def initialize
      #TODO
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
  end
end
#!/bin/bash
# Program:
#	Program will generate the diff report according to The configuration file in config directory.
# Author Binguo Bao

pwd=$PWD
#The directory used to store downloaded projects.
mkdir ../repositories

#The directory used to store the diff reports.
mkdir ../reports

#Demo to get repositories
function getRepositories() {
	if [ ! -d $1 ]; then
		$2 clone $3
	fi
}

#Demo to generate pmd reports
function generateReport() {
	./mvnw clean verify -Dmaven.pmd.skip=true
	VERSION=$(./mvnw -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec | tail -1)
	cd pmd-dist/target
	unzip -oq pmd-bin-${VERSION}.zip
	./pmd-bin-${VERSION}/bin/run.sh pmd -d $pwd/../repositories/spring-framework -f text -R $pwd/../config/all-java.xml -r $pwd/../reports/$1.txt
	cd ../../
}

cd ../repositories
getRepositories spring-framework git https://github.com/spring-projects/spring-framework
getRepositories pmd git https://github.com/pmd/pmd

#Demo to get pmd reports
cd pmd
git checkout master
generateReport report-m
git checkout pmd_releases/6.1.0
generateReport report-p
diff $pwd/../reports/report-m.txt $pwd/../reports/report-p.txt > $pwd/../reports/diff.txt


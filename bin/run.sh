#!/bin/bash
# Program:
#	Program will generate the diff report according to The configuration file in config directory.
# Author Binguo Bao

pwd=$PWD
#The directory used to store downloaded projects.
if [ ! -d ../repositories ]; then
	mkdir ../repositories
fi

#The directory used to store the diff reports.
if [ ! -d ../reports ]; then
	mkdir ../reports
fi

#Demo to get repositories
function getRepositories() {
	if [ ! -d $1 ]; then
		$2 clone $3
	fi
}

function generateReport() {
	./mvnw clean install -Dpmd.skip=ture
	VERSION=$(./mvnw -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec | tail -1)
	cd pmd-dist/target
	unzip -oq pmd-bin-${VERSION}.zip
	./pmd-bin-${VERSION}/bin/run.sh pmd -d $pwd/../repositories/spring-security -f html -R $pwd/../config/all-java.xml -r $pwd/../reports/$1.html
	cd ../../
}

cd ../repositories
getRepositories spring-security git https://github.com/spring-projects/spring-security
getRepositories pmd git https://github.com/pmd/pmd

#Demo to get pmd reports
cd pmd
git checkout HEAD
generateReport report-m
git checkout HEAD^^
generateReport report-p
diff $pwd/../reports/report-m.html ../reports/report-p.html > $pwd/../report/diff.html

#Demo to get repositories
function getRepositories() {
	if [ ! -d $1 ]; then
		$2 clone $3
	fi
}


# pmd-regression-tester
A regression testing tool ensure that new problems and unexpected behaviors will not be introduced to PMD project after fixing an issue , and new rules can work as expected. 
# The example to run the tool
`ruby run.rb -r YOUR_LOCAL_PMD_REPO -b master -bc config/all-java.xml -p pmd_releases/6.1.0 -pc config/all-java.xml -l config/projectsList.txt`

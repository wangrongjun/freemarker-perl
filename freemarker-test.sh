chmod +x freemarker.pl

sed -i 's|\r||g' test-*.txt

# 从管道接收模板内容，并且通过参数来定义模板中需要替换的变量集合
#   说明1：模板中定义的变量名需要符合正在表达式：[a-zA-Z0-9_-]+
#   说明2：if指令的变量，只有值为"true"的情况下，if指令才会判断为真，其他任何值，都会视为false
#   说明3：数组变量名是以[]作为后缀，[]内可以指定分隔符，默认分隔符为逗号
PARAMS='name=wrj age=26 marry=true single=false hobbies[|]=run|swim job=software-engineer es-servers[]=es-1,es-2,es-3'
cat test-1-template.txt | ./freemarker.pl --vars " ${PARAMS} " >test-1-result-actual.txt
if diff test-1-result.txt test-1-result-actual.txt >/dev/null; then
  echo 'INFO: test-1 succeed!'
  rm -f test-1-result-actual.txt
else
  cat test-1-result-actual.txt
  echo 'ERROR: test-1 fail, you can compare test-1-result.txt and test-1-result-actual.txt'
  exit 1
fi

PARAMS='name=wrj age=26 marry=true single=false hobbies[|]=run|swim job=software-engineer es-servers[]=es-1,es-2,es-3'
cat test-2-template.txt | ./freemarker.pl --vars " ${PARAMS} " --sign '%' >test-2-result-actual.txt
if diff test-2-result.txt test-2-result-actual.txt >/dev/null; then
  echo 'INFO: test-2 succeed!'
  rm -f test-2-result-actual.txt
else
  cat test-2-result-actual.txt
  echo 'ERROR: test-2 fail, you can compare test-2-result.txt and test-2-result-actual.txt'
  exit 1
fi

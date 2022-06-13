chmod +x freemarker.pl

cat >freemarker-test.txt <<'EOF'
1. My name is ${name}.
2. My job is ${job}.
3. I <#if marry>have</#if><#if !marry>don't have</#if> a wife, I'm <#if marry>not</#if> a single dog.
4. My hobbies is
   <#for i, hobby in hobbies>
   - ${i}: ${hobby}
   </#for>
5. My numbers is <#for number in numbers>${number},</#for>
EOF

# 从管道接收模板内容，并且通过参数来定义模板中需要替换的变量集合
#   说明1：if指令的变量，只有值为"true"的情况下，if指令才会判断为真，其他任何值，都会视为false
#   说明2：数组变量名是以[]作为后缀，[]内可以指定分隔符，默认分隔符为逗号
cat freemarker-test.txt | ./freemarker.pl name=wrj age=26 marry=true \
  hobbies[]='run,swim' job="software engineer" numbers['|']='3|6|9'

rm -f freemarker-test.txt

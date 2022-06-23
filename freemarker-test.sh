chmod +x freemarker.pl

cat >freemarker-test.txt <<'EOF'
1. My name is ${name}
2. My job is ${job}
3. I <#if marry>have</#if><#if !marry>don't have</#if> a wife, I'm <#if marry>not </#if>a single dog
4. I <#if !single>have</#if><#if single>don't have</#if> a wife, I'm <#if !single>not </#if>a single dog
5. My hobbies is
   <#for i, hobby in hobbies>
   - ${i+1}: ${hobby}
   </#for>
6. My es servers is [<#for es-server in es-servers><#if !$isFirst()>, </#if>"${es-server}"</#for>]
7. My es servers is [<#for es-server in es-servers>"${es-server}"<#if !$isLast()>, </#if></#for>]
8. My es servers is ["$join(es-servers, '", "')"]
9. My es server count is $size(es-servers)
10. My age is ${age * 1.1}
11. age variable is show as \${age}
12. <#if name=="wrj">name=="wrj"</#if>
13. <#if name=="qjy">name=="qjy"</#if>
14. <#if name!="wrj">name!="wrj"</#if>
15. <#if name!="qjy">name!="qjy"</#if>
EOF

# 从管道接收模板内容，并且通过参数来定义模板中需要替换的变量集合
#   说明1：模板中定义的变量名需要符合正在表达式：[a-zA-Z0-9_-]+
#   说明2：if指令的变量，只有值为"true"的情况下，if指令才会判断为真，其他任何值，都会视为false
#   说明3：数组变量名是以[]作为后缀，[]内可以指定分隔符，默认分隔符为逗号
PARAMS="name=wrj age=26 marry=true single=false hobbies[|]=run|swim job=software-engineer es-servers[]=es-1,es-2,es-3"
cat freemarker-test.txt | ./freemarker.pl ${PARAMS}

rm -f freemarker-test.txt

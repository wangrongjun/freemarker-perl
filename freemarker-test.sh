cat >freemarker-test.txt <<'EOF'
1. My name is ${name}.
2. My job is ${job}.
3. I <#if marry>have</#if><#if !marry>don't have</#if> a wife, I'm <#if marry>not</#if> a single dog.
4. My hobbies is
   <#for i, hobby in hobbies>
   - ${i}: ${hobby}
   </#for>
5. My numbers is <#for i, number in numbers>${number},</#for>
EOF
cat freemarker-test.txt | ./freemarker.pl name=wrj age=26 marry=true hobbies[]='run,swim' job="software engineer" numbers['|']='3|6|9'
rm -f freemarker-test.txt

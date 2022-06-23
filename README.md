# 简介

`FreeMarker-Perl`是一款**模板引擎**：即一种基于模板和要改变的数据，来生成输出文本(配置文件，源代码等)的工具。

`FreeMarker-Perl`主要用于运维部署脚本中，把配置模板文件输出为实际的配置文件，供部署时使用。

该框架是参考Java平台上已有的`FreeMarker模板引擎`，使用`Perl`语言实现基本的功能，`CentOS-7`默认自带`Perl`。

基本的功能包括：

1. 变量替换，比如模板是`my name is ${name}`，变量集合是`name=wrj`，那么通过模板引擎替换变量生成的文本为`my name is wrj`
2. 条件判断，通过`<#if>`指令实现，详情见下面的例子
3. 循环，通过`<#for>`指令实现，详情见下面的例子

Github地址：[GitHub - wangrongjun/freemarker-perl: FreeMarker for Perl](https://github.com/wangrongjun/freemarker-perl)

# 背景

在日常的运维工作中，需要编写许多的系统部署脚本，其中不同的环境，或者不同的节点，都可能需要不同的配置项。在部署脚本中就体现为需要准备不同的配置文件。

但是，不同环境/不同节点下的配置文件，绝大部分内容都是相同的，仅仅是个别配置项的值不一致。如果为每个环境/节点都创建一个配置文件，会有很多冗余，不利于维护。

因此决定编写配置文件模板，然后使用模板引擎来解释。通过研究，Java的FreeMarker能满足需求。但是使用FreeMarker就需要准备Java运行时环境，很不方便。

于是研究如何能不需要准备任何环境就能使用模板引擎，后来发现公司的Linux服务器（centos:7.6）默认自带Perl-5，而且Perl对正则表达式的支持比较好。

最后决定，使用Perl来开发模板引擎，以实现Java平台上FreeMarker的模板引擎功能。

# 例子

> 先git-clone源码，得到`freemarker.pl`，然后在`CentOS-7.6服务器`或者`本地Windows电脑的GitBash`执行：

```shell
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
#   说明2：if指令的判断表达式可以是一个变量，也可以是一个包含==或者!=的比较公式。如果是变量，只有值为"true"的情况下，会判断为真，其他任何值，都会视为false
#   说明3：数组变量名是以[]作为后缀，[]内可以指定分隔符，默认分隔符为逗号
PARAMS="name=wrj age=26 marry=true single=false hobbies[|]=run|swim job=software-engineer es-servers[]=es-1,es-2,es-3"
cat freemarker-test.txt | ./freemarker.pl ${PARAMS}

rm -f freemarker-test.txt

```

> 上面命令执行后，模板转换后的输出内容如下：

```
1. My name is wrj
2. My job is software-engineer
3. I have a wife, I'm not a single dog
4. I have a wife, I'm not a single dog
5. My hobbies is
   - 1: run
   - 2: swim
6. My es servers is ["es-1", "es-2", "es-3"]
7. My es servers is ["es-1", "es-2", "es-3"]
8. My es servers is ["es-1", "es-2", "es-3"]
9. My es server count is 3
10. My age is 28.6
11. age variable is show as ${age}
12. name=="wrj"
13.
14.
14. name!="qjy"

```

从输出结果可以看出：

1. 模板中可以使用表达式，比如`${i+1}`，`${age * 1.1}`
2. 循环里的if指令，可以使用`$isFirst()`和`$isLast()`内置函数来判断当前元素是否第一个或者最后一个
3. 可以使用`$join(array, '<separator>')`内置函数实现循环的效果，其中第一个参数是数组变量，第二个参数是分隔符
4. 如果不想被替换变量，可以在$前面加上反斜杠，变成：`\${xxx}`

# 后续支持的功能

1. [完成]变量支持表达式运算，比如`${i+1}`
2. if指令支持表达式运算，比如`<#if a==b+c>`
3. 实现常用的内置函数
    + `floor(i / 2)` - 向下取整
    + [完成]`size(array)` - 获取数组变量的长度
    + [完成]`isFirst()` - 遍历数组时判断当前的元素是否为第一个元素
    + [完成]`isLast()` - 遍历数组时判断当前的元素是否为最后一个元素
    + [完成]`join(array, '<separator>')` - 把数组join成一个字符串，其中第一个参数是数组变量，第二个参数是分隔符
4. 允许通过指定yaml/json文件来提供变量集合
5. 目前还不支持指令嵌套，即for指令里面有if指令，if指令里面有for指令，if指令里面有if指令。后续会支持

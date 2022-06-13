# 简介

`FreeMarker-Perl`是一款**模板引擎**：即一种基于模板和要改变的数据，来生成输出文本(配置文件，源代码等)的工具。

`FreeMarker-Perl`主要用于运维部署脚本中，把配置模板文件输出为实际的配置文件，供部署时使用。

该框架是参考Java平台上已有的`FreeMarker模板引擎`，使用`Perl`语言实现基本的功能，`CentOS-7`默认自带`Perl`。

基本的功能包括：

1. 变量替换，比如模板是`my name is ${name}`，变量集合是`name=wrj`，那么通过模板引擎替换变量生成的文本为`my name is wrj`
2. 条件判断，通过`<#if>`指令实现，详情见下面的例子
3. 循环，通过`<#for>`指令实现，详情见下面的例子

# 背景

在日常的运维工作中，需要编写许多的系统部署脚本，其中不同的环境，或者不同的节点，都可能需要不同的配置项。在部署脚本中就体现为需要准备不同的配置文件。

但是，不同环境/不同节点下的配置文件，绝大部分内容都是相同的，仅仅是个别配置项的值不一致。如果为每个环境/节点都创建一个配置文件，会有很多冗余，不利于维护。

因此决定编写配置文件模板，然后使用模板引擎来解释。通过研究，Java的FreeMarker能满足需求。但是使用FreeMarker就需要准备Java运行时环境，很不方便。

于是研究如何能不需要准备任何环境就能使用模板引擎，后来发现公司的Linux服务器（centos:7.6.1810）默认自带Perl-5，而且Perl对正则表达式的支持比较好。

最后决定，使用Perl来开发模板引擎，以实现Java平台上FreeMarker的模板引擎功能。

# 例子

> 先git-clone源码，得到`freemarker.pl`，然后在`CentOS-7.6服务器`或者`本地Windows电脑的GitBash`执行：

```shell
chmod +x freemarker.pl

cat >freemarker-test.txt <<'EOF'
1. My name is ${name}
2. My job is ${job}
3. I <#if marry>have</#if><#if !marry>don't have</#if> a wife, I'm <#if marry>not</#if> a single dog
4. My hobbies is
   <#for i, hobby in hobbies>
   - ${i}: ${hobby}
   </#for>
5. My es servers is [<#for es-server in es-servers>"${es-server}", </#for>]
6. My age is ${age}
EOF

# 从管道接收模板内容，并且通过参数来定义模板中需要替换的变量集合
#   说明1：模板中定义的变量名需要符合正在表达式：[a-zA-Z0-9_-]+
#   说明2：if指令的变量，只有值为"true"的情况下，if指令才会判断为真，其他任何值，都会视为false
#   说明3：数组变量名是以[]作为后缀，[]内可以指定分隔符，默认分隔符为逗号
cat freemarker-test.txt | ./freemarker.pl name=wrj age=26 marry=true \
  hobbies['|']='run|swim' job="software engineer" es-servers[]='es-1,es-2,es-3'
```

> 上面命令执行后，模板转换后的输出内容如下：

```
1. My name is wrj
2. My job is software engineer
3. I have a wife, I'm not a single dog
4. My hobbies is
   - 0: run
   - 1: swim
5. My es servers is ["es-1", "es-2", "es-3", ]
6. My age is 26
```

# 后续支持的功能

1. `${}`和`<#if>`支持表达式运算，比如`${i+1}`和`<#if a==b+c>`
2. 实现常用的内置函数，比如实现`len(array)`来支持获取数组变量的长度，`isFirst()`和`isLast()`来遍历数组时判断当前的元素是否为第一个/最后一个元素
3. 允许通过指定yaml/json文件来提供变量集合
4. 目前还不支持指令嵌套，即for指令里面有if指令，if指令里面有for指令，if指令里面有if指令。后续会支持

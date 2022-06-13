# 简介

FreeMarker-Perl 是一款**模板引擎**：即一种基于模板和要改变的数据，并用来生成输出文本(配置文件，源代码等)的工具

该模板引擎主要用于运维部署脚本中，把配置模板文件输出为实际的配置文件，供部署时使用

该框架是参考Java平台上已有的FreeMarker模板引擎，使用Perl语言实现基本的功能，centos-7服务器默认自带Perl

基本的功能包括：变量替换，条件判断，循环

# 背景

在日常的运维工作中，需要编写许多的系统部署脚本，其中不同的环境，或者不同的节点，都可能需要不同的配置项。在部署脚本中就体现为需要准备不同的配置文件。

但是，不同环境/不同节点下的配置文件，绝大部分内容都是相同的，仅仅是个别配置项的值不一致。如果为每个环境/节点都创建一个配置文件，会有很多冗余，不利于维护

因此决定使用编写配置文件模板，然后使用模板引擎来解释。通过研究，Java的FreeMarker能满足需求。但是使用FreeMarker就需要准备Java运行时环境，很不方便

于是研究如何能不需要准备任何环境就能使用模板引擎，后来发现公司的linux服务器（centos:7.6.1810）默认自带Perl-5，而且perl对正则表达式的支持比较好

最后决定，使用perl来开发模板引擎，以实现Java平台上FreeMarker的类似功能

# 基本使用

先git-clone源码，得到`freemarker.pl`，然后在`CentOS-7.6服务器`或者`本地Windows电脑的GitBash`上执行如下命令：

```shell
chmod +x freemarker.pl

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
```

> 上面脚本的输出内容如下：

```
1. My name is wrj.
2. My job is software engineer.
3. I have a wife, I'm not a single dog.
4. My hobbies is
   - 0: run
   - 1: swim
5. My numbers is 3,6,9,
```

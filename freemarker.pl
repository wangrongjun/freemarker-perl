#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long qw(GetOptions);

# 注意：需要先执行：chmod u+x demo.pl，否则会报错没权限执行脚本

# 定义接收参数的变量和默认值
my $vars = '';  # 替换模板的属性列表
my $file = '';  # 模板文件
my $sign = '$'; # 变量标识符，默认是美元符，会把${xxx}当做变量
my $signRegex;  # 变量标识符，会拼接为正则表达式的一部分，因此如果是特殊字符（例如$），需要加上反斜杠进行转义
my $help;

GetOptions(
    "vars=s" => \$vars,
    "file=s" => \$file,
    "sign=s" => \$sign,
    "help"   => \$help,
) or die("Error in command line arguments\n");
if ($sign =~ /^[\$\[\]\{\}]$/) {
    $signRegex = "\\$sign";
}
else {
    $signRegex = $sign;
}

my $helpDoc = <<'EOF';
Usage:
  -v,--vars: replace vars in template, such as: 'name="robin wang" age=26 hobbies[]=run,swim'
  -f,--file: template file
  -s,--sign: variables sign in template, default is $, mean to replace ${xxx} in template"
  -h,--help: show help doc
EOF

if ($help || !$vars) {
    print($helpDoc)
}
else {
    main();
}

sub main {
    # 1.从输入流获取yaml内容
    my $yamlText = '';
    while (<STDIN>) {
        $yamlText = "$yamlText$_"
    }
    # 去掉windows的\r回车符
    $yamlText =~ s/\r//g;

    # 2.从命令行参数获取替换属性
    my %variables = get_variables_from_argv();

    # 3.处理for（需要同时处理for里面的if，内置函数和变量，因此必须把for循环的处理放在第一步）
    $yamlText = convert_for($yamlText, %variables);

    # 4.处理内置函数
    $yamlText = convert_func($yamlText, %variables);

    # 5.处理if TODO 条件语句支持表达式运算，比如1+2==3，size(arr) == 0
    $yamlText = convert_if($yamlText, %variables);

    # 6.处理变量 TODO 支持表达式运算
    $yamlText = convert_variable($yamlText, \%variables);

    # 7.去掉转义符
    $yamlText =~ s/\\${signRegex}\{/${sign}{/g;

    print $yamlText;
}

sub get_variables_from_argv {
    my %variables;
    $vars = trim($vars);
    my @list = split(/[ ]+/, $vars);
    for (@list) {
        /(.+?)=(.*)/;
        my $key = $1;
        my $value = $2;
        my @values;
        if ($key =~ /(.+?)\[(.*?)\]/) {
            # 如果key的末尾是[]，说明是数组，需要解析value
            # 默认是使用逗号,作为分隔符
            $key = $1;
            my $splitText = ",";
            if ($2 ne "") {
                $splitText = $2;
            }
            if ($splitText eq "|" || $splitText eq ".") {
                $splitText = "\\$splitText";
            }
            @values = split($splitText, $value);
        }
        # print("key=$key, value=$value, values=@values\n");
        if (@values > 0) {
            $variables{$key} = \@values;
        }
        else {
            $variables{$key} = $value;
        }
    }
    return %variables;
}

sub convert_variable {
    my ($yamlText, @variables_list) = @_;
    while ($yamlText =~ /(?<!\\)${signRegex}\{([^}]+?)\}/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;
        my $express = $1;
        # print("start convert express '$express'\n");
        my $replaceValue = calculate_express($express, @variables_list);
        $yamlText = join(
            '',
            substr($yamlText, 0, $matchStringStart),
            $replaceValue,
            substr($yamlText, $matchStringEnd, length($yamlText) - $matchStringEnd),
        );
    }
    # $yamlText =~ s/\$-skip-sign-\{/\${/g;
    return $yamlText;
}

sub convert_if {
    my ($yamlText, %variables) = @_;
    my $varNameRegex = "[a-zA-Z0-9_-]+";
    while ($yamlText =~ /(\n[ ]*)?<#if ([!]?)(${varNameRegex}?)(([!|=])="(.+?)")?>((.|\n)*?)(\n[ ]*)?<\/#if>/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;

        my $not = $2;
        my $key = $3;
        my $equalSign = $5;
        my $equalValue = $6;
        my $content = $7;
        # print("not=$not, key=$key, content=$content\n");
        my $ifFlag = "true";
        if ($key eq "true" || $key eq "false") {
            $ifFlag = $key;
        }
        elsif (!exists($variables{$key})) {
            print(STDERR "Error 1: variable '$key' not defined\n");
            exit(1);
        }
        else {
            # 处理判断表达式有 == 或者 != 的情况
            if (defined($equalValue)) {
                if ($equalSign eq "=") {
                    if ($variables{$key} eq $equalValue) {
                        $ifFlag = "true";
                    }
                    else {
                        $ifFlag = "false";
                    }
                }
                else {
                    if ($variables{$key} eq $equalValue) {
                        $ifFlag = "false";
                    }
                    else {
                        $ifFlag = "true";
                    }
                }
            }
            # 处理判断表达式只有一个变量的情况
            else { # 处理判断表达式只有一个变量的情况
                $ifFlag = $variables{$key};
            }
        }
        # 处理非逻辑
        if ($not eq "!") {
            if ($ifFlag eq "true") {
                $ifFlag = "false";
            }
            else {
                $ifFlag = "true";
            }
        }

        my $matchStringNew = $ifFlag eq "true" ? $content : "";
        $yamlText = join(
            '',
            substr($yamlText, 0, $matchStringStart),
            $matchStringNew,
            substr($yamlText, $matchStringEnd, length($yamlText) - $matchStringEnd),
        );
    }
    return $yamlText;
}

sub convert_for {
    my ($yamlText, %variables) = @_;
    # (?<=\n)是零宽断言，实现把<#for>之前的空格和换行符去掉
    my $varNameRegex = "[a-zA-Z0-9_-]+";
    my $forStartRegex = "((?<=\\n)[ ]*)?<#for ((${varNameRegex})[ ]*,[ ]*)?(${varNameRegex}) in (${varNameRegex})>[\\n]?";
    my $forEndRegex = "((?<=\\n)[ ]*)?</#for>[ ]*[\\n]?";
    # (?s)使得[.]可以匹配任意字符，包括换行符
    my $forRegex = "(?s)${forStartRegex}(.*?)${forEndRegex}";
    # print("forRegex=$forRegex\n");
    while ($yamlText =~ /$forRegex/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;

        my $indexVarName = $3;    # 数组索引变量名，从0开始
        my $dataVarName = $4;     # 数组元素的变量名
        my $dataListVarName = $5; # 数组列表的变量名
        my $content = $6;         # 被for标签包裹的内容
        $content =~ s/^\n//;      # Perl的正则表达式好像有bug，无法排除content开头的换行符，只能手动去除

        # 判断数组列表的变量名是否有定义
        if (!exists($variables{$dataListVarName})) {
            print(STDERR "Error 2: variable '$dataListVarName' not defined\n");
            exit(1);
        }

        my $result = "";
        my @dataList = @{$variables{$dataListVarName}};
        for (my $i = 0; $i < @dataList; $i++) {
            my $temp = "$content";

            # 处理变量
            my %variables_temp;
            # 必须做一下判断，否则一旦for标签内没使用index变量，会报错：Use of uninitialized value $indexVarName
            if (defined($indexVarName) && $indexVarName) {
                %variables_temp = ("$indexVarName" => "$i", "$dataVarName" => "$dataList[$i]");
            }
            else {
                %variables_temp = ("$dataVarName" => "$dataList[$i]");
            }

            $temp = convert_variable($temp, \%variables_temp, \%variables);

            # 处理内置函数：isFirst() 和 isLast()
            my $isFirst = $i == 0 ? "true" : "false";
            my $isLast = $i == @dataList - 1 ? "true" : "false";
            $temp =~ s/${signRegex}isFirst\(\)/$isFirst/g;
            $temp =~ s/${signRegex}isLast\(\)/$isLast/g;

            $result = "$result$temp";
        }

        $yamlText = join(
            '',
            substr($yamlText, 0, $matchStringStart),
            $result,
            substr($yamlText, $matchStringEnd, length($yamlText) - $matchStringEnd),
        );
    }
    return $yamlText;
}

sub convert_func {
    my ($yamlText, %variables) = @_;

    # 内置函数join：把数组组装成一个字符串，可以自定义分隔符
    # 例子：$join(es-servers, ',')
    while ($yamlText =~ /${signRegex}join\(([a-zA-Z0-9_-]+?)[ ]*,[ ]*'(.+?)'[ ]*\)/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;

        my $arrayVarName = $1;
        my $separator = $2;
        if (!exists($variables{$arrayVarName})) {
            print(STDERR "Error 3: variable '$arrayVarName' not defined\n");
            exit(1);
        }
        my $matchStringNew = join($separator, @{$variables{$arrayVarName}});
        $yamlText = join(
            '',
            substr($yamlText, 0, $matchStringStart),
            $matchStringNew,
            substr($yamlText, $matchStringEnd, length($yamlText) - $matchStringEnd),
        );
    }

    # 内置函数size：获取数组长度
    # 例子：$size(list)
    while ($yamlText =~ /${signRegex}size\(([a-zA-Z0-9_-]+)\)/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;

        my $arrayVarName = $1;
        if (!exists($variables{$arrayVarName})) {
            print(STDERR "Error 4: variable '$arrayVarName' not defined\n");
            exit(1);
        }
        my @list = @{$variables{$arrayVarName}};
        my $size = @list;
        my $matchStringNew = "$size";
        $yamlText = join(
            '',
            substr($yamlText, 0, $matchStringStart),
            $matchStringNew,
            substr($yamlText, $matchStringEnd, length($yamlText) - $matchStringEnd),
        );
    }

    return $yamlText;
}

sub calculate_express {
    my ($express, @variables_list) = @_;
    $express = trim($express);
    my $itemRegex = '[a-z|A-Z|0-9|_|-|\.]+';
    if ($express =~ /^($itemRegex)[ ]*==[ ]*($itemRegex)$/) {
        # TODO 处理 == 比较符
        my $left_item = $1;
        my $right_item = $2;
    }
    elsif ($express =~ /^($itemRegex)[ ]*!=[ ]*($itemRegex)$/) {
        # TODO 处理 != 比较符
        my $left_item = $1;
        my $right_item = $2;
    }
    elsif ($express =~ /^($itemRegex)[ ]*([+|-|*|\/])[ ]*($itemRegex)$/) {
        # 处理 加减乘除
        my $left_item = $1;
        my $sign = $2;
        my $right_item = $3;
        if ($left_item =~ /[a-zA-Z]/) {
            my $value = find_value_from_hash_list($left_item, @variables_list);
            if ($value eq "not exist") {
                print(STDERR "Error: key '$left_item' not exist\n");
                exit(1);
            }
            $left_item = $value;
        }
        if ($right_item =~ /[a-zA-Z]/) {
            my $value = find_value_from_hash_list($right_item, @variables_list);
            if ($value eq "not exist") {
                print(STDERR "Error: key '$right_item' not exist\n");
                exit(1);
            }
            $right_item = $value;
        }
        return eval("$left_item $sign $right_item")
    }
    else {
        my $value = find_value_from_hash_list($express, @variables_list);
        if ($value eq "not exist") {
            print(STDERR "Error: key '$express' not exist\n");
            exit(1);
        }
        return $value;
    }
}

sub trim {
    my $string = $_[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

# 指定一个key，按顺序从多个hash对象中寻找对应的value。如果key不存在，会返回字符串：'not exist'
sub find_value_from_hash_list {
    my ($key, @hash_list) = @_;
    for my $hash_ref (@hash_list) {
        my %hash = %{$hash_ref};
        if (exists($hash{$key})) {
            return $hash{$key};
        }
    }
    return 'not exist';
}

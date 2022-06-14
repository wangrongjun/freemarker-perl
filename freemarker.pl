#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

# 注意：需要先执行：chmod u+x demo.pl，否则会报错没权限执行脚本

main();

sub main {
    # 1.从输入流获取yaml内容
    my $yamlText = '';
    while (<STDIN>) {
        $yamlText = "$yamlText$_"
    }

    # 2.从命令行参数获取替换属性
    my %variables = get_variables();

    # 3.处理for（需要同时处理for里面的if，内置函数和变量，因此必须把for循环的处理放在第一步）
    $yamlText = convert_for($yamlText, %variables);

    # 4.处理if TODO 条件语句支持表达式运算
    $yamlText = convert_if($yamlText, %variables);

    # 5.处理变量 TODO 支持表达式运算
    $yamlText = convert_variable($yamlText, %variables);

    # TODO 6.处理内置函数
    # TODO   len：用于得到数组的长度
    # TODO   isFirst()：当前是否为第一个元素，用于for指令里面的if指令中
    # TODO   isLast()：当前是否为最后一个元素，用于for指令里面的if指令中
    $yamlText = convert_func($yamlText, %variables);

    print $yamlText;
}

sub get_variables {
    my %variables;
    for (@ARGV) {
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
    my ($yamlText, %variables) = @_;
    while ($yamlText =~ /\$\{([a-zA-Z0-9_]+?)\}/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;
        my $matchStringNew = $matchString;
        my $key = $1;
        if (exists($variables{$key})) {
            $matchStringNew = $variables{$key};
        }
        else {
            # 如果key不存在，那就先把${xxx}改为一个别的内容，避免while死循环
            $matchStringNew =~ s/\$\{/\$-skip-sign-{/;
        }
        $yamlText = join(
            '',
            substr($yamlText, 0, $matchStringStart),
            $matchStringNew,
            substr($yamlText, $matchStringEnd, length($yamlText) - $matchStringEnd),
        );
    }
    $yamlText =~ s/\$-skip-sign-\{/\${/g;
    return $yamlText;
}

sub convert_if {
    my ($yamlText, %variables) = @_;
    while ($yamlText =~ /<#if ([!]?)([a-zA-Z0-9_-]+?)>((.|\n)*?)<\/#if>/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;

        my $not = $1;
        my $key = $2;
        my $content = $3;
        # print("not=$not, key=$key, content=$content\n");
        my $ifFlag = 1;
        if ($key eq "true" || $key eq "false") {
            $ifFlag = $key eq "true" ? 1 : 0;
        }
        elsif (!exists($variables{$key})) {
            print("Error: variable '$key' not defined");
            exit(1);
        }
        $ifFlag = $not eq "!" ? !$ifFlag : $ifFlag;
        my $matchStringNew = $ifFlag ? $content : "";

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
    while ($yamlText =~ /((?<=\n)[ ]*)?<#for (([a-zA-Z0-9_-]+?)[ ]*,[ ]*)?([a-zA-Z0-9_-]+?) in ([a-zA-Z0-9_-]+?)>[\n]?((.|\n)*?)((?<=\n)[ ]*)?<\/#for>[ ]*[\n]?/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;

        my $indexVarName = $3;    # 数组索引变量名，从0开始
        my $dataVarName = $4;     # 数组元素的变量名
        my $dataListVarName = $5; # 数组列表的变量名
        my $content = $6;         # 被for标签包裹的内容

        # 判断数组列表的变量名是否有定义
        if (!exists($variables{$dataListVarName})) {
            print("Error: variable '$dataListVarName' not defined");
            exit(1);
        }

        my $result = "";
        my @dataList = @{$variables{$dataListVarName}};
        for (my $i = 0; $i < @dataList; $i++) {
            my $temp = "$content";

            # 必须做一下判断，否则报错：Use of uninitialized value $indexVarName
            if (defined($indexVarName) && $indexVarName) {
                $temp =~ s/\$\{$indexVarName\}/$i/g;
            }
            $temp =~ s/\$\{$dataVarName\}/$dataList[$i]/g;

            my $isFirst = $i == 0 ? "true" : "false";
            my $isLast = $i == @dataList - 1 ? "true" : "false";
            $temp =~ s/\$isFirst\(\)/$isFirst/g;
            $temp =~ s/\$isLast\(\)/$isLast/g;

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
    #             例子：$join(es-servers, ',')
    while ($yamlText =~ /\$join\(([a-zA-Z0-9_-]+?)[ ]*,[ ]*'(.+?)'[ ]*\)/) {
        my $matchStringStart = $-[0];
        my $matchStringEnd = $+[0];
        my $matchString = $&;

        my $arrayVarName = $1;
        my $separator = $2;
        if (!exists($variables{$arrayVarName})) {
            print("Error: variable '$arrayVarName' not defined");
            exit(1);
        }
        my $matchStringNew = join($separator, @{$variables{$arrayVarName}});
        print("matchStringNew='$matchStringNew'\n");
        $yamlText = join(
            '',
            substr($yamlText, 0, $matchStringStart),
            $matchStringNew,
            substr($yamlText, $matchStringEnd, length($yamlText) - $matchStringEnd),
        );
    }
    return $yamlText;
}

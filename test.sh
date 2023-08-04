#!/bin/bash

assert() {
    # expected の "\n" を改行コードをとして解釈させる
    expected=`echo -e "$1"`
    input="$2"

    echo "$input" > tmp.rb
    ruby minrubyc.rb tmp.rb > tmp.s
    gcc tmp.s libminruby.c -o tmp
    actual=`./tmp`

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}

# 条件分岐
assert 42 'if (0 == 0); p(42); else p(43); end'
assert 43 'if (0 == 1); p(42); else p(43); end'
assert 44 'a = 44; if (a == 44); p a; end'
assert 45 'a = 40; if (a == 40); b = 5;  p a + b; end'

# 比較演算
# 真の場合は1、偽の場合は0を返す
assert 1 'p(1 == 1)'
assert 0 'p(1 == 2)'
assert 0 'p(1 != 1)'
assert 1 'p(1 != 2)'
assert 1 'p(1 < 2)'
assert 0 'p(1 < 1)'
assert 1 'p(1 <= 2)'
assert 1 'p(1 <= 1)'
assert 0 'p(1 <= 0)'
assert 1 'p(2 > 1)'
assert 0 'p(1 > 1)'
assert 1 'p(2 >= 1)'
assert 1 'p(1 >= 1)'
assert 0 'p(0 >= 1)'

# 変数
assert "10\n20\n30\n" "a = 10; b = 20; c = 30; p a; p b; p c"

# 複文
assert "10\n20\n" "p 10; p 20"

# 四則演算
assert "305" "p((10+20*30)/2)"
assert "5" "p 30/6"
assert "72" "p 8*9"
assert "20" "p 30-10"
assert "30" "p 10+20"

# 整数リテラル
assert "-10" "p(-10)"
assert "4649" "p 4649"

echo OK

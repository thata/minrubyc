#!/bin/bash

assert() {
    expected="$1"
    input="$2"

    echo "$input" > tmp.rb
    ruby minrubyc.rb tmp.rb > tmp.s
    gcc -o tmp tmp.s libminruby.c
    actual=`./tmp`

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}

assert 4649 'p 4649'
assert 40 'p 30 + 20 - 10'
assert 200 'p 10 * 20'
assert 33 'p 99 / 3'
assert 30 'a = 10; b = 20; p a + b'

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

echo OK
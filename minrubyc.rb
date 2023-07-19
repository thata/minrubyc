require "minruby"

def gen(tree)
  if tree[0] == "lit"
    puts "\tmov w0, ##{tree[1]}"
  elsif %w(+ - * /).include?(tree[0])
    arg1 = tree[1]
    arg2 = tree[2]

    # スタックを確保
    puts "\tsub sp, sp, #32"

    # arg1 を評価
    gen(arg1)
    puts "\tstr w0, [sp, #16]"

    # arg2 を評価
    gen(arg2)
    puts "\tstr w0, [sp, #0]"

    # 計算する
    puts "\tldr w8, [sp, #16]"
    puts "\tldr w9, [sp, #0]"
    if tree[0] == "+"
      puts "\tadd w0, w8, w9"
    elsif tree[0] == "-"
      puts "\tsub w0, w8, w9"
    elsif tree[0] == "*"
      puts "\tmul w0, w8, w9"
    elsif tree[0] == "/"
      puts "\tsdiv w0, w8, w9"
    end

    # スタックを解放
    puts "\tadd sp, sp, #32"
  else
    raise "invalid AST: #{tree}"
  end
end

tree = minruby_parse(ARGV[0])

puts "\t.text"
puts "\t.align 2"
puts "\t.globl _main"
puts "_main:"
puts "\tsub sp, sp, #16"
puts "\tstp x29, x30, [sp, #0]"

gen(tree)

# 入力した整数をプリントする
puts "\tbl _print_int"

puts "\tmov w0, #0"
puts "\tldp x29, x30, [sp, #0]"
puts "\tadd sp, sp, #16"
puts "\tret"

require "minruby"

def gen(tree)
  if tree[0] == "lit"
    puts "\tmov x0, ##{tree[1]}"
  elsif %w(+ - * /).include?(tree[0])
    op = tree[0]
    expr1 = tree[1]
    expr2 = tree[2]

    # 評価結果一時保持用のスタック領域を確保
    puts "\tsub sp, sp, #16"

    # 左辺を評価した結果をスタックへ積む
    gen(expr1)
    puts "\tstr x0, [sp, #0]"

    # 右辺を評価した結果をスタックへ積む
    gen(expr2)
    puts "\tstr x0, [sp, #8]"

    # 演算
    puts "\tldr x1, [sp, #8]"
    puts "\tldr x0, [sp, #0]"

    case op
    when "+"
      puts "\tadd x0, x0, x1"
    when "-"
      puts "\tsub x0, x0, x1"
    when "*"
      puts "\tmul x0, x0, x1"
    when "/"
      puts "\tsdiv x0, x0, x1"
    else
      raise "invalid operator: #{op}"
    end

    # スタックを破棄
    puts "\tadd sp, sp, #16"
  else
    raise "invalid AST: #{tree}"
  end
end

tree = minruby_parse(ARGF.read)

puts "\t.text"
puts "\t.align 2"
puts "\t.globl _main"
puts "_main:"
puts "\tsub sp, sp, #16"
puts "\tstp fp, lr, [sp, #0]"

gen(tree)

# 入力した整数をプリントする
puts "\tbl _p"

puts "\tmov w0, #0"
puts "\tldp fp, lr, [sp, #0]"
puts "\tadd sp, sp, #16"
puts "\tret"

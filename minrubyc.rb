require "minruby"

tree = minruby_parse(ARGF.read)

puts "\t.text"
puts "\t.align 2"
puts "\t.globl _main"
puts "_main:"
puts "\tsub sp, sp, #16"
puts "\tstp fp, lr, [sp, #0]"

if tree[0] == "lit"
  puts "\tmov w0, ##{tree[1]}"
else
  raise "invalid AST: #{tree}"
end

# 入力した整数をプリントする
puts "\tbl _p"

puts "\tmov w0, #0"
puts "\tldp fp, lr, [sp, #0]"
puts "\tadd sp, sp, #16"
puts "\tret"

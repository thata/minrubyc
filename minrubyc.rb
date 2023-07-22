require "minruby"

def gen(tree, env)
  if tree[0] == "lit"
    puts "\tmov w0, ##{tree[1]}"
  elsif %w(+ - * / == != < <= > >=).include?(tree[0])
    arg1 = tree[1]
    arg2 = tree[2]

    # スタックを確保
    puts "\tsub sp, sp, #32"

    # arg1 を評価
    gen(arg1, env)
    puts "\tstr w0, [sp, #16]"

    # arg2 を評価
    gen(arg2, env)
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
    elsif tree[0] == "=="
      puts "\tcmp w8, w9"
      puts "\tcset w0, eq"
    elsif tree[0] == "!="
      puts "\tcmp w8, w9"
      puts "\tcset w0, ne"
    elsif tree[0] == "<"
      puts "\tcmp w8, w9"
      puts "\tcset w0, lt"
    elsif tree[0] == "<="
      puts "\tcmp w8, w9"
      puts "\tcset w0, le"
    elsif tree[0] == ">"
      puts "\tcmp w8, w9"
      puts "\tcset w0, gt"
    elsif tree[0] == ">="
      puts "\tcmp w8, w9"
      puts "\tcset w0, ge"
    else
      raise "invalid operator: #{tree[0]}"
    end

    # スタックを解放
    puts "\tadd sp, sp, #32"
  elsif tree[0] == "stmts"
    tree[1..].each do |statement|
      gen(statement, env)
    end
  elsif tree[0] == "func_call" && tree[1] == "p"
    # p 関数（現時点では整数のみプリント可能）
    gen(tree[2], env)
    puts "\tbl _print_int"
  elsif tree[0] == "var_assign"
    puts "\t; 変数 #{tree[1]} に代入"
    gen(tree[2], env)
    puts "\tstr w0, [fp, ##{env[tree[1]]}]"
  elsif tree[0] == "var_ref"
    puts "\t; 変数 #{tree[1]} を参照"
    puts "\tldr w0, [fp, ##{env[tree[1]]}]"
  elsif tree[0] == "if"
    # 条件式を評価
    gen(tree[1], env)
    # 真の場合は tree[2] を実行
    puts "\tcmp w0, #0"
    puts "\tbeq .Lelse0"
    gen(tree[2], env)
    puts "\tb .Lend0"
    puts ".Lelse0:"
    # 偽の場合は tree[3] を実行
    gen(tree[3], env)
    puts ".Lend0:"
  else
    raise "invalid AST: #{tree}"
  end
end

def var_assigns(hash, tree)
  if tree[0] == "var_assign"
    hash[tree[1]] = hash.size * 16
  elsif tree[0] == "stmts"
    tree[1..].each do |statement|
      var_assigns(hash, statement)
    end
  end
  hash
end

tree = minruby_parse(ARGF.read)

# ローカル変数のインデックスを計算
env = var_assigns({}, tree)

puts "\t.text"
puts "\t.align 2"
puts "\t.globl _main"
puts "_main:"
puts "\tsub sp, sp, #{16 + env.size * 16}"
puts "\tstp x29, x30, [sp, ##{env.size * 16}]"
puts "\tmov x29, sp"

gen(tree, env)

puts "\tmov w0, #0"
puts "\tldp x29, x30, [sp, ##{env.size * 16}]"
puts "\tadd sp, sp, #{16 + env.size * 16}"
puts "\tret"

require "minruby"

# tree 内の変数名一覧
def var_names(arr, tree)
  if tree[0] == "var_assign"
    arr.include?(tree[1]) ? arr : arr + [tree[1]]
  elsif tree[0] == "stmts"
    tmp_arr = arr
    tree[1..].each do |statement|
      tmp_arr = tmp_arr + var_names(tmp_arr, statement)
    end
    tmp_arr
  else
    arr
  end
end

# スタックフレーム上の変数のアドレスをスタックポインタ（sp）からのオフセットとして返す
# 例：
#   ひとつ目の変数のアドレス = スタックポインタ + 16
#   ふたつ目の変数のアドレス = スタックポインタ + 24
#   ふたつ目の変数のアドレス = スタックポインタ + 32
#   ...
def var_offset(var, env)
  # 変数1つにつき8バイトの領域が必要
  env.index(var) * 8 + 16
end

def gen(tree, env)
  if tree[0] == "lit"
    puts "\tmov x0, ##{tree[1]}"
  elsif %w(+ - * / == != < <= > >=).include?(tree[0])
    op = tree[0]
    expr1 = tree[1]
    expr2 = tree[2]

    # 評価結果一時保持用のスタック領域を確保
    puts "\tsub sp, sp, #16"

    # 左辺を評価した結果をスタックへ積む
    gen(expr1, env)
    puts "\tstr x0, [sp, #0]"

    # 右辺を評価した結果をスタックへ積む
    gen(expr2, env)
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
    when "=="
      puts "\tcmp x0, x1"
      puts "\tcset x0, eq"
    when "!="
      puts "\tcmp x0, x1"
      puts "\tcset x0, ne"
    when "<"
      puts "\tcmp x0, x1"
      puts "\tcset x0, lt"
    when "<="
      puts "\tcmp x0, x1"
      puts "\tcset x0, le"
    when ">"
      puts "\tcmp x0, x1"
      puts "\tcset x0, gt"
    when ">="
      puts "\tcmp x0, x1"
      puts "\tcset x0, ge"
    else
      raise "invalid operator: #{op}"
    end

    # スタックを破棄
    puts "\tadd sp, sp, #16"
  elsif tree[0] == "func_call" && tree[1] == "p"
    expr = tree[2]
    gen(expr, env)
    puts "\tbl _p"
  elsif tree[0] == "stmts"
    tree[1..].each do |stmt|
      gen(stmt, env)
    end
  elsif tree[0] == "var_assign"
    name, expr = tree[1], tree[2]

    # 評価した値をスタック上のローカル変数領域へ格納
    gen(expr, env)
    puts "\tstr x0, [sp, ##{var_offset(name, env)}]"
  elsif tree[0] == "var_ref"
    # スタック上のローカル変数領域からx0へ値をロード
    name = tree[1]
    puts "\tldr x0, [sp, ##{var_offset(name, env)}]"
  else
    raise "invalid AST: #{tree}"
  end
end

tree = minruby_parse(ARGF.read)
env = var_names([], tree)

puts "\t.text"
puts "\t.align 2"
puts "\t.globl _main"
puts "_main:"
puts "\tsub sp, sp, ##{16 + env.size * 8}"
puts "\tstp fp, lr, [sp, #0]"

gen(tree, env)

puts "\tmov w0, #0"
puts "\tldp fp, lr, [sp, #0]"
puts "\tadd sp, sp, ##{16 + env.size * 8}"
puts "\tret"

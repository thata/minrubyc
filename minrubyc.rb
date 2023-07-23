require "minruby"

PARAM_REGISTERS = %w(w0 w1 w2 w3 w4 w5 w6 w7)
WORK_REGISTERS = %w(w19 w20 w21 w22 w23 w24 w25 w26)

# 条件分岐のラベルを一意にするためのID
$label_id = 0

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
  elsif tree[0] == "func_def"
    # 上で定義済みなのでここでは何もしない
  elsif tree[0] == "func_call"
    # WORK_REGISTERS の値をスタックに退避
    puts "\tsub sp, sp, ##{WORK_REGISTERS.size * 4}"
    WORK_REGISTERS.each_with_index do |reg, i|
      puts "\tstr #{reg}, [sp, ##{i * 4}]"
    end

    # args の評価結果を x19, x20, ... に格納
    args = tree[2..]

    # NOTE: 実装を楽にするため、渡せる引数の数は8個までとする
    raise "too many arguments (given #{args.size}, expected 8)" if args.size > 8

    # 引数の評価結果を一時的に WORK_REGISTERS に格納
    args.each_with_index do |arg, i|
      gen(arg, env)
      puts "\tmov #{WORK_REGISTERS[i]}, w0"
    end

    # WORK_REGISTERS に格納した引数を PARAM_REGISTERS へ移動
    args.each_with_index do |arg, i|
      puts "\tmov #{PARAM_REGISTERS[i]}, #{WORK_REGISTERS[i]}"
    end

    # 関数呼び出し
    puts "\tbl _#{tree[1]}"

    # WORK_REGISTERS の値をスタックから復元
    WORK_REGISTERS.each_with_index do |reg, i|
      puts "\tldr #{reg}, [sp, ##{i * 4}]"
    end
    puts "\tadd sp, sp, ##{WORK_REGISTERS.size * 4}"
  elsif tree[0] == "var_assign"
    puts "\t; 変数 #{tree[1]} に代入"
    gen(tree[2], env)
    puts "\tstr w0, [fp, ##{env[tree[1]]}]"
  elsif tree[0] == "var_ref"
    puts "\t; 変数 #{tree[1]} を参照"
    puts "\tldr w0, [fp, ##{env[tree[1]]}]"
  elsif tree[0] == "if"
    label_id = $label_id
    $label_id = $label_id + 1

    # 条件式を評価
    gen(tree[1], env)
    # 真の場合は tree[2] を評価
    puts "\tcmp w0, #0"
    puts "\tbeq .L_cond_else#{label_id}"
    gen(tree[2], env)
    puts "\tb .L_cond_end#{label_id}"
    puts ".L_cond_else#{label_id}:"
    # 偽の場合は tree[3] を評価（else が無いこともある）
    if tree[3]
      gen(tree[3], env)
    end
    puts ".L_cond_end#{label_id}:"

    # ラベルIDをインクリメント
  elsif tree[0] == "while"
    label_id = $label_id
    $label_id = $label_id + 1

    puts ".L_while_begin#{label_id}:"
    # 条件式が真の間は tree[2] を評価し続ける
    gen(tree[1], env)
    puts "\tcmp w0, #0"
    puts "\tbeq .L_while_end#{label_id}"
    gen(tree[2], env)
    puts "\tb .L_while_begin#{label_id}"
    puts ".L_while_end#{label_id}:"
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

def func_defs(hash, tree)
  if tree[0] == "func_def"
    # 関数名をキーにして [関数名, 引数, 関数本体] を格納
    hash[tree[1]] = tree[1..]
  elsif tree[0] == "stmts"
    tree[1..].each do |statement|
      func_defs(hash, statement)
    end
  end
  hash
end

tree = minruby_parse(ARGF.read)
# pp tree

# ローカル変数を構文木より抽出し、各ローカル変数のスタック上の位置を算出
env = var_assigns({}, tree)

# ユーザー定義関数を構文木より抽出
func_defs = func_defs({}, tree)

puts "\t.text"
puts "\t.align 2"

# ユーザー定義関数をアセンブリとして出力
func_defs.each do |key, func_def|
  name, args, body = func_def

  # 引数とローカル変数のスタック上の位置を算出
  env = args.each_with_index.map { |arg, i|
    [arg, i * 16]
  }.to_h
  env = var_assigns(env, body)

  puts "\t.globl _#{name}"
  puts "_#{name}:"

  # fp と lr をスタックへ退避
  puts "\tsub sp, sp, #{16 + env.size * 16}"
  puts "\tstp x29, x30, [sp, ##{env.size * 16}]"
  puts "\tmov x29, sp"

  # args をスタックへ退避
  args.each_with_index do |arg, i|
    puts "\t; 引数 #{arg} をスタックへ退避"
    puts "\tstr w#{i}, [x29, ##{env[arg]}]"
  end

  gen(body, env)

  # fp と lr をスタックから復元
  puts "\tldp x29, x30, [sp, ##{env.size * 16}]"
  puts "\tadd sp, sp, #{16 + env.size * 16}"

  puts "\tret"
end

# メイン関数
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

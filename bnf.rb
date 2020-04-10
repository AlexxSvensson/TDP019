require './rdparse.rb'
require './Nodes.rb'
require 'pry'

class Bnf
  attr_reader :variables
  def initialize
    @logicParser = Parser.new("logic") do
      token(/[<>+\-\/*=]=/) {|m| m}
      token(/\s+/)
      token(/\d+\.\d+/) {|d| d.to_f}
      token(/\d+/) {|d| d.to_i}
      token(/["A-Za-z\d]+/) {|m| m }
      token(/./) {|t| t}

      #Regler

      start :root do
        match(:statement_list){|a| a}
      end

      rule :statement_list do
        match(:statement_list, :valid) {|statement_list, valid|Statement_list_node.new(statement_list, valid)}
        match(:valid) {|valid| Valid_node.new(valid)}
      end

      rule :valid do
        #match(:print)
        #match(:func)
        match(:check)
        match(:loop)
        match(:declaration)
        match(:assign)
        match(/[a-z]/){|a|Get_variable_node.new(a)}
      end

      rule :print do
        match('print', String){|_, str| Print_node.new(str)}
      end

      rule :loop do
        match('while', :expr, :bracket) {|_, expr, bracket| While_node.new(expr, bracket)}
        match('for', :name, ',', :int,',', :int, :bracket){|_, var, _, from, _, to, bracket| For_node.new(var, from, to, bracket)}
      end

      rule :check do
        match('if', :expr, :bracket, :check_else) {|_, expr, bracket, check_else| If_node.new(expr, bracket, check_else)}
        match('if', :expr, :bracket) {|_, expr, bracket| If_node.new(expr, bracket, nil)}
      end

      rule :check_else do
        match('elsif', :expr, :bracket, :check_else){|_, expr, bracket, check_else| If_node.new(expr, bracket, check_else)}
        match('elsif', :expr, :bracket){|_, expr, bracket| If_node.new(expr, bracket, nil)}
        match('else', :bracket){|_, bracket| Else_node.new(bracket)}
      end

      rule :define_func do
        match('def', :name, :paramater)
      end

      rule :bracket do
        match('{', :statement_list, '}')  do |_, statement_list, _|
          Bracket_node.new(statement_list)
        end
      end

      rule :expr do
        match(:expr, 'and', :expr)  {|a, _, b| And_node.new(a, b) }
        match(:expr, 'or', :expr) {|a, _, b| Or_node.new(a, b) }
        match('not', :expr) {|_, a| Not_node.new(a) }
        match(:boolean)
        match(:compare)
      end

      rule :func do
        match('func', :name, '(', :parameter, ')', :bracket)
      end

      rule :paramater do
        match('(', ':parameter',':var', ')'){|_, parameter, var, _|}
        match(':parameter',':var'){|parameter, var|}
        match('(', ':var', ')'){|_, parameter, var, _|}
        match(':var'){|parameter, var|}
      end

      rule :declaration do
        match(:data_type, :name, '=', :var){|dt, name, _, value|Declaration_node.new(dt, name, value)}
        match(:data_type, :name){|dt, name|Declaration_node_default.new(dt, name)}
      end

      rule :assign do
        match(:our_var, :assign_operator, :var){|name, op, value|Assign_node.new(name, op, value)}
      end

      rule:data_type do
        match('integer')
        match('float')
        match('string')
        match('boolean')
      end

      rule :name do
        match(String)
      end


      rule :var do
        match(:number_term)
        match(:string)
        match(:expr)
        #match(:char)
        match(:our_var) {|a| Get_variable_node.new(a)}
      end

      rule :our_var do
        match(/[A-Za-z\d]+/)
      end

      rule :number_term do
        match(:number_factor, '+', :number_factor) {|a, _, b| Addition_node.new(a, b)}
        match(:number_factor, '-', :number_factor) {|a, _, b| Subtraction_node.new(a, b)}
        match(:number_factor)
      end

      rule :number_factor do
        match(:number, '*', :number) {|a, _, b| Multiplication_node.new(a, b)}
        match(:number, '/', :number) {|a, _, b| Division_node.new(a, b)}
        match(:number)
      end

      rule :number do
          match('(', :number_term, ')') {|_, term, _| Number_term_node.new(term)}
          match(:int) {|a| Number_node.new(a)}
          match(:float) {|a| Number_node.new(a)}
      end

      rule :int do
        match(Integer)
      end

      rule :float do
        match(Float)
      end

      rule :boolean do
        match('true') {Boolean_node.new(true)}
        match('false') {Boolean_node.new(false)}
      end

      rule :string do
        # match(/"/, String, /"/) {|_, str, _| String_node.new(str)}
        match(/"[A-Za-z\d]*"/) {|str| String_node.new(str)}
      end

      rule :compare do
        match('(', :var, :compare_operator, :var,')'){|_, a, op, b, _|Compare_node.new(a, op, b)}
        match(:our_var, :compare_operator, :var){|a, op, b|Compare_node.new(a, op, b)}
        end

      rule :assign_operator do
        match('=')
        match('+=')
        match('-=')
        match('*=')
        match('/=')
      end


      rule :compare_operator do
        match('<')
        match('>')
        match('==')
        match('<=')
        match('>=')
        match('!=')
      end
    end
  end

  def done(str)
    ["quit","exit","bye",""].include?(str.chomp)
  end

  def evaluate()
    file = File.open("test1.txt")
    str = file.read
    log
    if done(str) then
      puts "Bye."
    else
      root_node = @logicParser.parse str
      puts "=> #{root_node.evalu}"
    end
  end

  def log(state = false)
    if state
      @logicParser.logger.level = Logger::DEBUG
    else
      @logicParser.logger.level = Logger::WARN
    end
  end

end

l = Bnf.new
l.evaluate()

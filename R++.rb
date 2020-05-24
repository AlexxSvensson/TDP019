require './rdparse.rb'
require './Nodes_new.rb'

class Bnf
  attr_reader :variables
  def initialize
    var_name_regex = /[a-zA-Z\d_]+\b(?<!\bif|elsif|else|while|for|true|
                      loop_list|input|false|print|func|and|or|
                      not|integer|float|string|list|boolean)/
    @logicParser = Parser.new("logic") do
      token(/#([^#]*?)\/#/)
      token(/[-]?\d+\.\d+/) {|d| d.to_f}
      token(/-?\d+/) {|d| d.to_i}
      token(/[<>+\-\/*!=]=/) {|m| m}
      token(/"([^"]*?)"/) {|m| m }
      token(/[a-zA-Z\d_-]+/) {|m| m }
      token(/\s+/)
      token(/./) {|t| t}

      #Regler
      start :root do
        match(:statement_list){|a| a}
      end

      rule :statement_list do
        match(:valid, :statement_list){|valid, statement_list| \
          Statement_list_node.new(valid, statement_list)}
        match(:valid) {|valid| Valid_node.new(valid)}
      end

      rule :valid do
        match(:return)
        match(:check)
        match(:loop)
        match(:print)
        match(:define_func)
        match(:functions)
        match(:declaration)
        match(:assign)
      end

      rule :return do
        match('return', :functions){|_, var| Return_node.new(var)}
        match('return', :get_list_element){|_, var| Return_node.new(var)}
        match('return', :var){|_, var| Return_node.new(var)}
      end

      rule :print do
        match('print', '(', :functions, ')'){|_, _, var, _| Print_node.new(var)}
        match('print', '(', :get_list_element, ')'){\
                                        |_, _, var, _| Print_node.new(var)}
        match('print', '(', :var, ')'){|_, _, var, _| Print_node.new(var)}
      end

      rule :input do
        match('input', '(', ')') {Input_node.new("string")}
        match('input', '(', 'string', ')') {Input_node.new("string")}
        match('input', '(', 'integer', ')') {Input_node.new("integer")}
        match('input', '(', 'float', ')') {Input_node.new("float")}
        match('input', '(', 'boolean', ')') {Input_node.new("boolean")}
      end

      rule :loop do
        match('while', '(', :expr, ')', :bracket) {|_, _, expr, _, bracket| \
              While_node.new(expr, bracket)}
        match('for','(',:name,',',:number_term,',',:number_term,')',:bracket){ \
              |_, _, var, _, from, _, to, _, bracket| \
              For_node.new(var, from, to, bracket)}
        match('loop_list', '(', :list, ',', :name, ')', :bracket){\
              |_, _, list, _, name, _, bracket| \
              List_loop_node.new(list, name, bracket)}
      end

      rule :check do
        match('if', '(', :expr, ')', :bracket, :check_else) {\
              |_, _, expr, _, bracket, check_else| \
              If_node.new(expr, bracket, check_else)}
        match('if', '(', :expr, ')', :bracket) {|_, _,expr, _, bracket| \
              If_node.new(expr, bracket, nil)}
      end

      rule :check_else do
        match('elsif', '(', :expr, ')', :bracket, :check_else){\
          |_, _, expr, _, brcket, chck_els| If_node.new(expr, brcket, chck_els)}
        match('elsif', '(', :expr, ')', :bracket){|_, _, expr, _, bracket| \
              If_node.new(expr, bracket, nil)}
        match('else', :bracket){|_, bracket| Else_node.new(bracket)}
      end

      rule :define_func do
        match('func', :name, '(', :parameter_list, ')', :bracket){\
              |_, name, _, para_list, _, brcket| \
              Add_func_node.new(name,Parameter_list_node.new(para_list),brcket)}
        match('func', :name, '(', ')', :bracket){|_, name, _, _, bracket| \
              Add_func_node.new(name, [], bracket)}
      end

      rule :call_func do
        match(:name, '(', :arg_list, ')'){|name, _, arg_list, _| \
              Call_func_node.new(name, Arg_list_node.new(arg_list))}
        match(:name, '(', ')'){|name, _, _| \
              Call_func_node.new(name, Arg_list_node.new([]))}
      end

      rule :member_function do
          match(:var, '.', :name, '(', :arg_list, ')') {\
                |var, _, func_name,_ ,args,_| \
                Member_func_node.new(var, func_name, Arg_list_node.new(args))}
          match(:var, '.', :name, '(', ')'){|var, _, func_name| \
                Member_func_node.new(var, func_name, false)}
      end

      rule :functions do
        match(:member_function)
        match(:call_func)
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
        match(:declared_var)
      end

      rule :arg_list do
        match(:arg_list, ',', :var) do |arg_list, _, var|
          if arg_list.instance_of?(Array)
            arg_list << var
            arg_list
          elsif var.class.name == "Array"
            var.insert(0, list)
            var
          else
            [arg_list, var]
          end
        end
        match(:var) {|var| var}
      end

      rule :parameter_list do
        match(:parameter_list, ',', :parameter) do |param_list, _, param|
          if param_list.instance_of?(Array)
            param_list << param
            param_list
          else
            [param_list, param]
          end
        end
        match(:parameter) {|param| param}
      end

      rule :parameter do
        match(:data_type, :name) {|data_type, name| \
              Parameter_node.new(data_type, name)}
        match('&', :data_type, :name) {|_, data_type, name| \
              Parameter_reference_node.new(data_type, name)}
      end

      rule :declaration do
        match(:data_type, :name, '=', :input){|dt, name, _, value| \
              Declaration_node.new(dt, name, value)}
        match(:data_type, :name, '=', :functions){|dt, name, _, value| \
              Declaration_node.new(dt, name, value)}
        match(:data_type, :name, '=', :var){|dt, name, _, value| \
              Declaration_node.new(dt, name, value)}
        match(:data_type, :name){|dt, name| \
              Declaration_node_default.new(dt, name)}
      end

      rule :assign do
        match(:get_list_element, :assign_operator, :input){|name, op, value| \
              Assign_node.new(name, op, value)}
        match(:get_list_element,:assign_operator,:functions){|name, op, value|\
              Assign_node.new(name, op, value)}
        match(:get_list_element, :assign_operator, :var){|name, op, value|\
              Assign_node.new(name, op, value)}
        match(:name, :assign_operator, :input){|name, op, value|\
              Assign_node.new(name, op, value)}
        match(:name, :assign_operator, :functions){|name, op, value|\
              Assign_node.new(name, op, value)}
        match(:name, :assign_operator, :var){|name, op, value| \
              Assign_node.new(name, op, value)}
      end

      rule:data_type do
        match('integer')
        match('float')
        match('string')
        match('boolean')
        match('list', '<', :data_type, '>') {|_, _, data_type, _| \
              "#{data_type} list"}
      end

      rule :name do
        match(var_name_regex)
      end


      rule :var do
        match(:get_list_element)
        match(:string)
        match(:number_term)
        match(:list)
        match(:expr)
        match(:declared_var)
      end

      rule :declared_var do
        match(var_name_regex) {|a| Get_variable_node.new(a)}
      end

      rule :get_list_element do
        match(:name, '[', :int, ']') {|name, _, index, _| \
              Get_list_element_node.new(name, index)}
        match(:name, '[', :declared_var, ']') {|name, _, index, _| \
              Get_list_element_node.new(name, index)}
      end


      rule :number_term do
        match(:number_factor, '+', :number_factor) {|a, _, b| \
              Addition_node.new(a, b)}
        match(:number_factor, '-', :number_factor) {|a, _, b| \
              Subtraction_node.new(a, b)}
        match(:number_term, '+', :number_factor) {|a, _, b| \
              Addition_node.new(a, b)}
        match(:number_term, '-', :number_factor) {|a, _, b| \
              Subtraction_node.new(a, b)}
        match(:number_factor)
      end

      rule :number_factor do
        match(:number, '*', :number) {|a, _, b| Multiplication_node.new(a, b)}
        match(:number, '/', :number) {|a, _, b| Division_node.new(a, b)}
        match(:number_factor, '*', :number) {|a, _, b| \
              Multiplication_node.new(a, b)}
        match(:number_factor, '/', :number) {|a, _, b| Division_node.new(a, b)}
        match(:number)
      end

      rule :number do
        match('(', :number_term, ')') {|_, term, _| Number_term_node.new(term)}
        match(:int) {|a| Number_node.new(a)}
        match(:float) {|a| Number_node.new(a)}
        match(:declared_var)
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
        match(/"([^"]*?)"/) {|str| String_node.new(str)}
      end


      rule :list do
        match('[', :list_element, ']') {|_, var_list, _|List_node.new(var_list)}
        match(:declared_var)
      end

      rule :list_element do
        match(:list_element, ',', :var) do |list, _, var|
          if list.instance_of?(Array)
            list << var
            list
          elsif var.class.name == "Array"
            var.insert(0, list)
            var
          else
            [list, var]
          end
        end
        match(:var){|var| var}
      end

      rule :compare do
        match(:get_list_element, :compare_operator, :var){|a, op, b| \
              Compare_node.new(a, op, b)}
        match(:declared_var, :compare_operator, :var){|a, op, b| \
              Compare_node.new(a, op, b)}
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


  def evaluate()
    if ARGV.length != 1
      raise "Wrong number of arguments."
    end
    file = File.open(ARGV[0])
    str = file.read
    log

    root_node = @logicParser.parse str
    root_node.evalu
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

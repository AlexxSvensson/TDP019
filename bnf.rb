require './rdparse.rb'
require 'pry'

class Logic
  attr_reader :variables
  def initialize

    @logicParser = Parser.new("logic") do
      # Håller i variabler
      @variables = {}
      token(/[+\-\/*]=/) {|m| m}
      token(/\s+/) #Gör inget med whitespace-tecken
      token(/\d+\.\d+/) {|d| d.to_f}
      token(/\d+/) {|d| d.to_i}
      token(/["A-Za-z\d]+/) {|m| m } #För strängar
      token(/./) {|t| t} #fångar paranteser

      #Regler
      start :statement_list do
        match(:statement_list, '\n', :valid)
        match(:valid)
      end

      start :valid do
        match(:declaration)
        match(:assign)
        match(String) {|a| p @variables[a]}
        match(:loop)
        match(:expr)
        match(:check)
        match(:func)
      end

      rule :loop do
        match('while', :expr, '{', :statement_list, '}')
        match('for', :var, :int, :int, '{', :statement_list, '}')
      end

      rule :check do
        match('if', :boolean, '{', :statement_list, '}', :check)
        match('if', :boolean, '{', :statement_list, '}')
        match('elsif', :boolean, '{', :statement_list, '}', :check)
        match('elsif', :boolean, '{', :statement_list, '}')
        match('else', '{', :statement_list, '}')
      end

      rule :expr do
        match('(', :expr, 'or', :expr, ')') {|_, _, a, b, _| a or b }
        match(:expr, 'or', :expr) {|_, _, a, b, _| a or b }
        match('(', :expr, 'and', :expr, ')')  {|_, _, a, b, _| a and b }
        match(:expr, 'and', :expr)  {|_, _, a, b, _| a and b }
        match('(', 'not', :expr, ')') {|_, _, a,  _| not a }
        match('not', :expr) {|_, _, a,  _| not a }
        match(:compare)
      end

      rule :func do
        match('func', :name, '(', :parameter, ')', '{', :statement_list, '}')
      end

      rule :paramater do
        match(':parameter', ',', ':var')
        match(':var')
      end

      rule :declaration do
        match(:data_type, :name, '=', :var) do
          |dt, name, _, value|
          if dt == "integer" and value.instance_of?(Integer)
            @variables[name] = value
          elsif dt == "float" and value.instance_of?(Float)
            @variables[name] = value
          elsif dt == "string" and value.instance_of?(String)
            @variables[name] = value
          elsif dt == "boolean" and (value.instance_of?(TrueClass) or value.instance_of?(FalseClass))
            @variables[name] = value
          else
            p "du gjorde fel"
          end
        end
        match(:data_type, :name) do
          |dt, name|
          if dt == "integer"
            @variables[name] = 0
          elsif dt == "float"
            @variables[name] = 0.0
          elsif dt == "string"
            @variables[name] = ""
          elsif dt == "boolean"
            @variables[name] = false
          else
            p "du gjorde fel"
          end
        end
      end

      rule :assign do
        match(:our_var, :assign_operator, :var) do
          |name, ao, value|
          if ao == "="
            @variables[name] = value
          elsif ao == "+="
            @variables[name] += value
          elsif ao == "-="
            @variables[name] -= value
          elsif ao == "*="
            @variables[name] *= value
          elsif ao == "/="
            @variables[name] /= value
          end
        end
        #match(:var)
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
        match(:boolean)
        #match(:char)
        match(:our_var) {|a| @variables[a]}
      end

      rule :our_var do
        match(String)
      end

      rule :number_term do
        match(:number_factor, '+', :number_factor) {|a, _, b| a+b}
        match(:number_factor, '-', :number_factor) {|a, _, b| a-b}
        match(:number_factor)
      end

      rule :number_factor do
        match(:number, '*', :number) {|a, _, b| a*b}
        match(:number, '/', :number) {|a, _, b| a/b}
        match(:number)
      end

      rule :number do
          match('(', :number_term, ')')
          match(:int)
          match(:float)
      end

      rule :int do
        #match(:int, :operator, Integer)
        match(Integer)
      end

      rule :float do
        #match(:float, :operator, :number)
        match(Float)
      end

      rule :boolean do
        match('true') {true}
        match('false') {false}
        #match(:expr)
      end

      rule :string do
        match('"', String, '"')
        match(/"[A-Za-z\d]+"/)
      end



      rule :compare do
        match(:var, :compare_operator, :var)
      end

      rule :operator do
        match('+')
        match('-')
        match('*')
        match('/')
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

  def evaluate
    print "[logic] "
    str = gets
    if done(str) then
      puts "Bye."
    else
      puts "=> #{@logicParser.parse str}"
      evaluate
    end
  end

  def evaluate_test(str) #evaluate för test
    if done(str) then
      return 0
    else
      return @logicParser.parse str
    end
  end

  def log(state = true)
    if state
      @logicParser.logger.level = Logger::DEBUG
    else
      @logicParser.logger.level = Logger::WARN
    end
  end
end

l = Logic.new
l.evaluate

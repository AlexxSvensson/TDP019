require './rdparse.rb'

class Logic

  def initialize

    @logicParser = Parser.new("logic") do
      # Håller i variabler
      @dict = Hash.new

      token(/\s+/) #Gör inget med whitespace-tecken
      token(/[A-Za-z\d]+/) {|m| m } #För strängar
      token(/./) {|t| t} #fångar paranteser

      #Regler
      start :statement_list do
        match(:statement_list, '\n', :valid)
        match(:valid)
      end

      start :valid do
        match(:declaration)
        match(:assign)
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
        match('if', :expr, '{', :statement_list, '}' :check)
        match('elsif', :expr, '{', :statement_list, '}', :check)
        match('else', '{', :statement_list '}')
      end

      rule :expr do
        match('(', :expr, 'or', :expr, ')') {|_, _, a, b, _| a or b }
        match(':expr, 'and', :expr')  {|_, _, a, b, _| a and b }
        match('not', :expr, ')') {|_, _, a,  _| not a }
        match(:compare)
        match(:boolean)
      end

      rule :func do
        match('func', 'string', '(', :parameter, ')', '{', :statement_list, '}')
      end

      rule :paramater do
        match(':parameter', ':var')
        match(':var')
      end

      rule :var do
        match(:boolean)
        match(:String)
        match(:number_term)
        match(:char)
      end

      rule :number_term do
        match(:number_factor, '+', :number_factor)
        match(:number_factor, '-', :number_factor)
        match(:number_factor)
      end

      rule :number_factor do
        match(:number, '*', :number)
        match(:number, '/', :number)
        match(:number)
      end

      rule :number do
          match('(', :number_term, ')')
          match(:int)
          match(:float)
      end

      rule :int do
        match(:int, :operator, Integer)
        match(Integer)
      end

      rule :float do
        match(:float, :operator, :number)
        match(Float)
      end

      rule :boolean do
        match(:expr)
        match('true')
        match('false')
      end

      rule :string do
        match(string)
      end

      rule :declaration do
        match(:något, (String))
        match(:något, (String), '=', :var)
      end

      rule :assign do
        match(:var, ':assign_operator', :var)
        match(:var,
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

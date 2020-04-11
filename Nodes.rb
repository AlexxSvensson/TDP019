$variables = [{}]
$current_scope = 0
$functions = {}

def increase_scope()
  $current_scope += 1
  $variables << {}
  print "\n" + "utökar scope till #{$current_scope}" + "\n"
end

def decrease_scope()
  $current_scope -= 1
  $variables.pop
  print "\n" + "minskar scope till #{$current_scope}" + "\n"
end

def check_var_exist(name)
  for x in 0..$current_scope
    scope = $current_scope - x
    if $variables[scope].key?(name)
      return true
    end
  end
  return false
end

def get_var_scope(name)
  for x in 0..$current_scope
    scope = $current_scope - x
    if $variables[scope].key?(name)
      return scope
    end
  end
  return nil
end

class Add_func_node
  def initialize(name, parameter, bracket)
    @name = name
    @parameter = paramater
    @bracket = bracket.eval
  end
  def evalu()
    @functions[@name] = [@parameter, @bracket]
  end
end

class Statement_list_node
  def initialize(statement_list, valid)
    @statement_list = statement_list
    @valid = valid
  end
  def evalu()
    @statement_list.evalu
    @valid.evalu
  end
end

class Valid_node
  def initialize(valid)
    @valid = valid
  end
  def evalu()
    @valid.evalu
  end
end

class If_node
  def initialize(expr, bracket, check_else)
    @expr = expr
    @bracket = bracket
    @check_else = check_else
  end
  def evalu()
    increase_scope
    if @expr.evalu
      @bracket.evalu
    elsif @check_else != nil
      @check_else.evalu
    end
    decrease_scope
  end
end

class Else_node
  def initialize(bracket)
    @bracket = bracket
  end
  def evalu()
    increase_scope
    @bracket.evalu
    decrease_scope
  end
end

class While_node
  def initialize(expr, bracket)
    @expr = expr
    @bracket = bracket
  end
  def evalu()
    increase_scope
    while @expr.evalu
      @bracket.evalu
      #evalu
    end
    decrease_scope
  end
end

class For_node
  def initialize(var, from, to, bracket)
    @var = var
    @from = from
    @to = to
    @bracket = bracket
  end
  def evalu()
    increase_scope
    for temp in @from..@to do
      $variables[$current_scope][@var] = temp
      @bracket.evalu
    end
    decrease_scope
  end
end

class Bracket_node
  def initialize(statement_list)
    @statement_list = statement_list
  end
  def evalu()
    @statement_list.evalu
  end
end

class Print_node
  def initialize(str)
    @str = str
  end
  def evalu()
    print str
  end
end

class Get_variable_node
  def initialize(name)
    @name = name
  end

  def evalu()
    if check_var_exist(@name)
      p $variables[get_var_scope(@name)][@name]
      $variables[get_var_scope(@name)][@name]
    else
      "Variabel finns ej"
    end
  end
end

class Assign_node
  def initialize(name, op, value)
    @name = name
    @op = op
    @value = value.evalu
  end
  def evalu()
    if check_var_exist(@name)
      scope = get_var_scope(@name)
      eval "$variables[scope][@name] #{@op} #{@value}"
    end
  end
end

class Declaration_node
  def initialize(type, name, value)
    @type = type
    @name = name
    @value = value
  end
  def evalu()
    @value = @value.evalu
    if !$variables[$current_scope].key?(@name)
      if @type == "integer" and @value.instance_of?(Integer)
        $variables[$current_scope][@name] = @value
      elsif @type == "float" and @value.instance_of?(Float)
        $variables[$current_scope][@name] = @value
      elsif @type == "string" and @value.instance_of?(String)
        $variables[$current_scope][@name] = @value
      elsif @type == "boolean" and (@value.instance_of?(TrueClass) or @value.instance_of?(FalseClass))
        $variables[$current_scope][@name] = @value
      end
    end
  end
end

class Declaration_node_default
  def initialize(type, name)
    @type = type
    @name = name
  end

  def evalu()
    var_exist = $variables[$current_scope].key?(@name)
    if !var_exist
      if @type == "integer"
        $variables[$current_scope][@name] = 0
      elsif @type == "float"
        $variables[$current_scope][@name] = 0.0
      elsif @type == "string"
        $variables[$current_scope][@name] = ""
      elsif @type == "boolean"
        $variables[$current_scope][@name] = false
      end
    end
  end
end

class Compare_node
  def initialize(a, op, b)
    @a = a
    @op = op
    @b = b.evalu
  end

  def evalu()
    eval "$variables[0][@a] #{@op} #{@b}"
  end
end

class Boolean_node
  def initialize(a)
    @a = a
  end

  def evalu()
    @a
  end
end

class String_node
  def initialize(a)
    @a = a.delete_prefix('"').delete_suffix('"')
  end
  def evalu()

    @a
  end
end

class Number_term_node
  def initialize(term)
    @term = term
  end
  def evalu()
    @term.evalu
  end
end

class Number_node
  def initialize(a)
    @a = a
  end

  def evalu()
    @a
  end
end

class Addition_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    @a.evalu + @b.evalu
  end
end

class Subtraction_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    @a.evalu - @b.evalu
  end
end

class Multiplication_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    @a.evalu * @b.evalu
  end
end

class Division_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    @a.evalu / @b.evalu
  end
end

class And_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    @a.evalu and @b.evalu
  end
end

class Or_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    @a.evalu or @b.evalu
  end
end

class Not_node
  def initialize(a)
    @a = a
  end

  def evalu()
    not @a.evalu
  end
end

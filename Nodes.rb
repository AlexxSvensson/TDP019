require './functions.rb'

$variables = [{}]
$current_scope = 0
$functions = {}

#Increaes current scope by 1
def increase_scope()
  $current_scope += 1
  $variables << {}
end
#Decreases current scope by 1
def decrease_scope()
  $current_scope -= 1
  $variables.pop
end

#Returns integer representing the highest scope where
# variable name can be found, or nil if not found
def get_var_scope(name)
  for x in 0..$current_scope
    scope = $current_scope - x
    if $variables[scope].key?(name)
      return scope
    end
  end
  return nil
end

#Checks if value is a node
def check_if_node(value)
  if value.class.method_defined? :evalu
    return true
  end
  return false
end

#Checks if variable name exists
def check_var_exist(name)
  if $current_scope == 0 and $variables[0].key?(name)
    return true
  end
  for x in 0..$current_scope
    scope = $current_scope - x
    if $variables[scope].key?(name)
      return true
    end
  end
  return false
end


#Returns string representation of obj's type
def convert_type_to_str(obj)
  type = obj.class.name
  if type == "Integer"
    return "integer"
  elsif type == "Float"
    return "float"
  elsif type == "String"
    return "string"
  elsif type == "TrueClass" or type == "FalseClass"
    return "boolean"
  elsif type == "Array"
    temp = obj[0]
    temp = convert_type_to_str(temp)
    return "#{temp} list"
  end
end

#Returns true if the type of value is the same as type
def control_type(type, value)
  if check_if_node(value)
    value = value.evalu
  end
  if value.instance_of?(Array)
    return control_list_type(type, value)
  end
  if type == convert_type_to_str(value)
    return true
  end
  return false
end

#Returns true if all elements in values is the same as type
def control_list_type(type, values)
  type = type[0...type.rindex(' ')]

  for value in values
    if type != convert_type_to_str(value)
      return false
    end
  end
  return true
end


class Call_func_node
  def initialize(name, arg_list)
    @name = name
    @arg_list = arg_list
  end
  def evalu()
    if !$functions.key?(@name)
      raise "Function #{@name} does not exist."
    end
    ref_params = []
    param_list = $functions[@name][0]

    #Evaluate param_list if it's a Paramater_list_node
    if !param_list.instance_of?(Array)
      param_list = param_list.evalu
    end

    counter = 0

    #Control that provided arguments match expected arguments
    for param in param_list
      if !control_type(param.evalu[0],  @arg_list.evalu[counter])
        raise "Function #{@name} called with wrong arguments."
      end
      counter += 1
    end

    increase_scope

    counter = 0
    for param in param_list
      parameter = param.evalu
      #Save variables sent in as references
      if parameter[2] and \
        @arg_list.evalu[counter].instance_of?(Get_variable_node)
        ref_params << [@arg_list.evalu[counter].get_name, parameter[1]]
      end
      #Declare variables
      Declaration_node.new(parameter[0], parameter[1],\
                              @arg_list.evalu[counter]).evalu
      counter += 1
    end

    ret_value = $functions[@name][1].evalu

    ret_value = \
    (ret_value.instance_of?(Return_node)) ? ret_value.evalu_value() : ret_value


    for params in ref_params
      params[1] = Get_variable_node.new(params[1]).evalu
    end

    decrease_scope
    #Assign new value to variables
    for params in ref_params
      Assign_node.new(params[0], "=", params[1]).evalu
    end


    return ret_value
  end
end


class Add_func_node
  def initialize(name, param_list, bracket)
    @name = name
    @param_list = param_list
    @bracket = bracket
  end
  def evalu()
    if $functions.key?(@name)
      raise "A function called #{@name} already declared."
    elsif $current_scope != 0
      raise "Functions can only be declared in the main scope."
    end
    $functions[@name] = [@param_list, @bracket]
  end
end


class Member_func_node
  def initialize(var, func_name, arg_list)
    @var = var
    @func_name = func_name
    @arg_list = arg_list
  end
  def evalu()
    var = @var
    args = []

    if @arg_list != false
      for arg in @arg_list.evalu
        if check_if_node(arg)
          arg = arg.evalu
        end
        args << arg
      end
    end
    if check_if_node(@var)
      var = @var.evalu
    end
    type = var.class.name
    if type == "Integer" or type == "Float"
      if @func_name == "is_even" and type == "Integer"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return is_even(var)
      elsif @func_name == "pow" and type == "Integer"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return pow(var, args[0])
      elsif @func_name == "to_strng"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return to_strng(var)
      elsif @func_name == "absolute_value"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return absolute_value(var)
      elsif @func_name == "square_root"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return square_root(var)
      elsif @func_name == "round" and type == "Float"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return round(var, args[0])
      end
    elsif type == "String"
      if @func_name == "length"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return length(var)
      elsif @func_name == "lower"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return lower(var)
      elsif @func_name == "upper"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return upper(var)
      elsif @func_name == "replace"
        if args.length != 2
          raise "Wrong number of arguments, expected 2, #{args.length} given."
        end
        return replace(var, args[0], args[1])
      elsif @func_name == "split"
        if args == false
          return split(var, " ")
        else
          if args.length != 1
            raise "Wrong number of arguments, expected 1, #{args.length} given."
          end
          return split(var, args[0])
        end
      end
    elsif type == "Array"
      if @func_name == "length"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return list_length(var)
      elsif @func_name == "at"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return at(var, args[0])
      elsif @func_name == "reverse"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return reverse(var)
      elsif @func_name == "sort"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return sort(var)
      elsif @func_name == "has_element"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return has_element(var, args[0])
      elsif @func_name == "clear"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return clear(var)
      elsif @func_name == "rotate"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return rotate(var, args[0])
      elsif @func_name == "pop"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return pop(var)
      elsif @func_name == "delete_object"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return delete_object(var, args[0])
      elsif @func_name == "delete_index"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        return delete_index(var, args[0])
      elsif @func_name == "push_back"
        if args.length != 1
          raise "Wrong number of arguments, expected 1, #{args.length} given."
        end
        Assign_node.new(@var.get_name, '+=', [args[0]]).evalu
      end
    elsif type == "TrueClass" or type == "FalseClass"
      if @func_name == "to_strng"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return to_strng(var)
      elsif @func_name == "inverse"
        if args.length != 0
          raise "Wrong number of arguments, expected 0, #{args.length} given."
        end
        return inverse(var)
      end
    end
  end
end

#Not in use.
class Member_func_node2
  def initialize(var, func_name, arg_list)
    @var = var
    @func_name = func_name
    @arg_list = arg_list
  end
  def evalu()
    if @arg_list != false
      str = "("
      for node in @arg_list.evalu
        str += node.evalu.to_s
        str += ','
      end
      str = str.delete_suffix(',')
      str += ')'
      func_name = @func_name + str
      eval "#{@var.evalu}.#{func_name}"
    else
      eval "#{@var.evalu}.#{@func_name}"
    end
  end
end

class Arg_list_node
  def initialize(arg_list)
    @arg_list = (arg_list.class == Array) ? arg_list : [arg_list]
  end
  def evalu()
    return @arg_list
  end
end


class Parameter_list_node
  def initialize(param_list)
    @param_list = (param_list.class == Array) ? param_list : [param_list]
  end
  def evalu()
    return @param_list
  end
end

class Parameter_node
  def initialize(data_type, name)
    @data_type = data_type
    @name = name
  end
  def evalu()
    return [@data_type, @name, false]
  end
end

class Parameter_reference_node
  def initialize(data_type, name)
    @data_type = data_type
    @name = name
  end
  def evalu()
    return [@data_type, @name, true]
  end
end

class Statement_list_node
  def initialize(valid, statement_list)
    @statement_list = statement_list
    @valid = valid
  end
  def evalu()
    ret = @valid.evalu
    if ret.instance_of?(Return_node)
      return ret
    end

    ret = @statement_list.evalu

    return ret
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
    ret = nil
    if @expr.evalu
      ret = @bracket.evalu
    elsif @check_else != nil
      ret = @check_else.evalu
    end
    if ret.instance_of?(Return_node)
      ret.evalu_value()
    end
    decrease_scope
    return ret
  end
end

class Else_node
  def initialize(bracket)
    @bracket = bracket
  end
  def evalu()
    increase_scope
    ret = @bracket.evalu

    if ret.instance_of?(Return_node)
      ret.evalu_value()
    end

    decrease_scope
    return ret
  end
end

class While_node
  def initialize(expr, bracket)
    @expr = expr
    @bracket = bracket
  end
  def evalu()
    ret = nil
    increase_scope
    while @expr.evalu
      ret = @bracket.evalu
      if ret.instance_of?(Return_node)
        ret.evalu_value()
        break
      end
    end
    decrease_scope
    return ret
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
    ret = nil
    increase_scope
    for temp in @from.evalu..@to.evalu do
      $variables[$current_scope][@var] = [temp, "integer"]
      ret = @bracket.evalu
      if ret.instance_of?(Return_node)
        ret.evalu_value()
        break
      end
    end
    decrease_scope
    return ret
  end
end

class List_loop_node
  def initialize(list, name, bracket)
    @list = list
    @name = name
    @bracket = bracket
  end
  def evalu()
    ret = nil
    increase_scope
    type = convert_type_to_str(@list.evalu[0])
    Declaration_node_default.new(type, @name).evalu

    for x in @list.evalu
      Assign_node.new(@name,"=", x).evalu
      ret = @bracket.evalu
      if ret.instance_of?(Return_node)
        ret.evalu_value()
        break
      end
    end
    decrease_scope
    return ret
  end
end

class Bracket_node
  def initialize(statement_list)
    @statement_list = statement_list
  end
  def evalu()
    a = @statement_list.evalu
    return a
  end
end

class Print_node
  def initialize(var)
    @var = var
  end
  def evalu()
    var = @var.evalu
    if var.instance_of?(String)
      var = var.delete_prefix('"').delete_suffix('"')
    end
    p var
  end
end

class Input_node
  def initialize(type)
    @type = type
  end
  def evalu()
    str = $stdin.gets.chomp
    if @type == "integer"
      str = str.to_i
    elsif @type == "float"
      str = str.to_f
    elsif @type == "boolean"
      if str == "true"
        str = true
      elsif str == "false"
        str = false
      end
    end
    return str
  end
end


class Get_variable_node
  def initialize(name)
    @name = name
  end

  def evalu()
    if check_var_exist(@name)
      $variables[get_var_scope(@name)][@name][0]
    else
      raise "Variable #{@name} not found."
    end
  end

  def get_name()
    return @name
  end
end

class Assign_node
  def initialize(name, op, value)
    @name = name
    @op = op
    @value = value
  end
  def evalu()
    if @name.instance_of?(Get_list_element_node) and \
      !check_var_exist(@name.get_name)
      raise "Variable #{@name.get_name()} does not exist."
    elsif !@name.instance_of?(Get_list_element_node) and \
      !check_var_exist(@name)
      raise "Variable #{@name} does not exist."
    end
    value = check_if_node(@value) ? @value.evalu : @value
    if @name.instance_of?(Get_list_element_node)
      scope = get_var_scope(@name.get_name())
      if control_type($variables[scope][@name.get_name()][1].split()[0], value)
        eval "$variables[scope][@name.get_name()][0][@name.get_index()]\
              #{@op} value"
      else
        raise "The value you are trying to assign to
              #{@name.get_name()} at index #{@name.get_index()} \
              is of wrong type."
      end
    elsif control_type($variables[get_var_scope(@name)][@name][1], value)
      scope = get_var_scope(@name)
      eval "$variables[scope][@name][0] #{@op} value"
    else
      raise "The value assigned to #{@name} is of wrong type, expected
      #{$variables[get_var_scope(@name)][@name][1]}, found #{value.class.name}."
    end
  end
end

class Return_node
  def initialize(var)
    @var = var
  end
  def evalu()
    return self
  end

  def evalu_value()
    return check_if_node(@var) ? @var.evalu : @var
  end
end

class Declaration_node
  def initialize(type, name, value)
    @type = type
    @name = name
    @value = value
  end
  def evalu()

    value = @value.evalu

    if !$variables[$current_scope].key?(@name)
      if value.instance_of?(Array)
        if control_list_type(@type, value)
          $variables[$current_scope][@name] = [value, @type]
        else
          raise "One or more of the values assigned to #{@name} is of wrong type."
        end
      elsif @type == "integer" and value.instance_of?(Integer)
        $variables[$current_scope][@name] = [value, @type]
      elsif @type == "float" and value.instance_of?(Float)
        $variables[$current_scope][@name] = [value, @type]
      elsif @type == "string" and value.instance_of?(String)
        $variables[$current_scope][@name] = [value, @type]
      elsif @type == "boolean" and
            (value.instance_of?(TrueClass) or value.instance_of?(FalseClass))
        $variables[$current_scope][@name] = [value, @type]
      else
        raise "The value assigned to #{@name} is of wrong type,
               expected #{@type}, found #{value.class.name}."
      end
    else
      raise "A variable called #{@name} already exists."
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
        $variables[$current_scope][@name] = [0, @type]
      elsif @type == "float"
        $variables[$current_scope][@name] = [0.0, @type]
      elsif @type == "string"
        $variables[$current_scope][@name] = ["", @type]
      elsif @type == "boolean"
        $variables[$current_scope][@name] = [false, @type]
      elsif @type.split[1] == "list"
         $variables[$current_scope][@name] = [[], @type]
      else
        raise "Something went wrong when trying to create variable #{@name}."
      end
    else
      raise "A variable called #{@name} already exists."
    end
  end
end

class Compare_node
  def initialize(a, op, b)
    @a = a
    @op = op
    @b = b
  end
  def evalu()
    eval "#{@a.evalu} #{@op} #{@b.evalu}"
  end
end

class List_node
  def initialize(var_list)
    @var_list = (var_list.instance_of?(Array)) ? var_list : [var_list]
  end
  def evalu()
    temp_list = []
    for var in @var_list
      if check_if_node(var)
        var = var.evalu
      end
      temp_list << var
    end
    @var_list = temp_list
    return @var_list
  end
end

class Get_list_element_node
  def initialize(name, index)
    @name = name
    @index = index
  end

  def evalu()
    index = check_if_node(@index) ? @index.evalu : @index
    if $variables[get_var_scope(@name)][@name][0].length-1 < index
      raise "Index #{index} in #{@name} is out of range."
    end
    if check_var_exist(@name)
      return $variables[get_var_scope(@name)][@name][0][index]
    else
      raise "No list called #{@name.get_name()} exists."
    end
  end
  def get_name()
    return @name
  end
  def get_index()
    index = check_if_node(@index) ? @index.evalu : @index
    return index
  end
end


class Boolean_node
  def initialize(a)
    @a = a
  end

  def evalu()
    return @a
  end
end

class String_node
  def initialize(a)
    @a = a
  end
  def evalu()
    return @a
  end
end

class Number_term_node
  def initialize(term)
    @term = term
  end
  def evalu()
    return @term.evalu
  end
end

class Number_node
  def initialize(a)
    @a = a
  end

  def evalu()
    return @a
  end
end

class Addition_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    return (@a.evalu + @b.evalu)
  end
end

class Subtraction_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def evalu()
    return (@a.evalu - @b.evalu)
  end
end

class Multiplication_node
  def initialize(a, b)
    @a = a
    @b = b
  end
  def evalu()
    return (@a.evalu * @b.evalu)
  end
end

class Division_node
  def initialize(a, b)
    @a = a
    @b = b
  end
  def evalu()
    return (@a.evalu / @b.evalu)
  end
end

class And_node
  def initialize(a, b)
    @a = a
    @b = b
  end
  def evalu()
    return (@a.evalu and @b.evalu)
  end
end

class Or_node
  def initialize(a, b)
    @a = a
    @b = b
  end
  def evalu()
    return (@a.evalu or @b.evalu)
  end
end

class Not_node
  def initialize(a)
    @a = a
  end
  def evalu()
    return (not @a.evalu)
  end
end

####int/float
def square_root(n)
  return Integer.sqrt(n)
end

def is_even(var)
  return var.even?()
end

def pow(var, exp)
  return var.pow(exp)
end

def to_strng(var)
  return var.to_s
end

def absolute_value(var)
  return var.abs
end

def round(var, n)
  if var.instance_of?(Integer)
    return var
  end
  return var.round(n)
end


####String
def length(s)
  return s.delete_prefix('"').delete_suffix('"').length
end

def lower(s)
  return s.downcase
end

def upper(s)
  return s.upcase
end

def replace(s, x, y)
  return s.sub(x.delete_prefix('"').delete_suffix('"'), y.delete_prefix('"').delete_suffix('"'))
end

def split(s, x)
  return s.split(x.delete_prefix('"').delete_suffix('"'))
end


####List
def list_length(l)
  return l.length
end

def at(l, n)
  return l.at(n)
end

def reverse(l)
  return l.reverse
end

def sort(l)
  return l.sort
end

def has_element(l, n)
  return l.include?(n)
end

def clear(l)
  return l.clear
end

def rotate(l, x)
  return l.rotate(x)
end

def pop(l)
  return l.pop
end

def delete_object(l, x)
  l.delete(x)
  return l
end

def delete_index(l, x)
  l.delete_at(x)
  return l
end

#(push_back implementerad i Member_func_node)

########bool

def to_strng(var)
  return var.to_s
end

def inverse(var)
  if var == true
    var = false
    return var
  elsif var == false
    var = true
    return var
  end
end

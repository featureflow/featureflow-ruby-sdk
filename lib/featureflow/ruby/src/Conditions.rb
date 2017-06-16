
def equals(a, b)
  a.eql? b
end

def contains(a, b)
  a.include? b
end

def startsWith(a, b)
  a.start_with? b
end

def endsWith(a, b)
  a.end_with? b
end

def matches(a, b)
  a.match? Regexp.new(b)
end

def in(a, b)
  b.include? a
end

def notIn(a, b)
  not b.include? a
end

def greaterThan(a, b)
  a > b
end

def greaterThanOrEqual(a, b)
  a >= b
end

def lessThan(a, b)
  a < b
end

def lessThanOrEqual(a, b)
  a <= b
end

def before(a, b)
  a < b
end

def after(a, b)
  a > b
end

class Conditions
  def self.test(op, a, b)
    b = b[0] unless %w(in notIn).include? op
    begin
      send(op, a, b)
    rescue
      false
    end
  end
end

# const operators = {

#     before: (a, b) => {
#     return a < b;
# },
#     after: (a, b) => {
#     return a > b;
# }
# };
#
# const notFound = () => {
#     return false;
# };
#
# export function test(op, a, b){
#   b = ['in','notIn'].indexOf(op) >= 0 ? b : b[0];
#   return (operators[op] || notFound)(a, b);
# }
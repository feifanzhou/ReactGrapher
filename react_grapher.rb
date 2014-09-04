def process_file_in_directory(filename, dir)
  dir[0] == '/' ? "#{ dir }/#{ filename }" : "./#{ dir }/#{ filename }"
end

def component_name_from_declaration(line)
  line[0...line.index('=')].strip
end
def component_name_from_render(line)
  name = line[0...line.index('(')].strip
  line.include?('children:') ? name[9...name.length].strip : name
end

def get_component_names(filename)
  components = {}
  File.foreach(filename) do |line|
    next unless line.include? 'React.createClass'
    name = component_name_from_declaration(line)
    components[name] = []
  end
  return components
end

def generate_components_map(filename, components)
  current_list = []
  current_name = ''
  is_in_render = false
  File.foreach(filename) do |line|
    if line.include? 'React.createClass'
      components[current_name] = current_list if current_name.length > 0 && components.has_key?(current_name)
      current_list = []
      current_name = component_name_from_declaration(line)
      is_in_render = false
    end
    is_in_render = true if line.include? 'render:'
    next unless is_in_render
    next unless line.include? '('
    component_name = component_name_from_render(line)
    current_list << component_name if components.has_key?(component_name)
  end
  components[current_name] = current_list if current_name.length > 0 && components.has_key?(current_name)
  return components
end

source = ARGV[0]
# Build hash of component names
if File.file? source
  components = get_component_names source
else
  components = {}
  files = Dir.entries(source).select { |f| !File.directory? f }
  files.each do |f|
    next unless f.include? '.js'
    comps = get_component_names process_file_in_directory(f, source)
    components.merge! comps
  end
end

# Get component children of each parent component
if File.file? source
  components = generate_components_map(source, components)
else
  files = Dir.entries(source).select { |f| !File.directory? f }
  files.each do |f|
    next unless f.include? '.js'
    comps = generate_components_map(process_file_in_directory(f, source), components)
    comps.each do |k, v|
      components.has_key?(k) ? components[k] = components[k] + v : components[k] = v
    end
  end
end
# Remove duplicates
components.each { |k, v| components[k] = v.uniq }

# Create DOT file output
output = "digraph G {\n"
components.each do |k, v|
  if v.length > 0
    children = (v.length < 2) ? "\"#{ v[0] }\"" : "{ \"#{ v.join('"; "') }\"}"
    output += "  \"#{ k }\" -> #{ children };\n"
  else
    output += "  \"#{ k }\";\n"
  end
end
output += '}'
File.open('_dot.dot', 'w') { |f| f.write(output) }

# Run Graphviz
output_name = ARGV[1] || 'ReactGraph.pdf'
output_format = (File.extname output_name)[1..-1]
if output_format.length < 1
  output_format = 'pdf'
  output_name = "#{ output_name }.pdf"
end
system( "dot -T#{ output_format } _dot.dot -o #{ output_name }" )

# Cleanup
File.delete('_dot.dot')
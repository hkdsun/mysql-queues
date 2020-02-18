class Node
attr_accessor :edges, :jobs, :id

def initialize(id, arrivals_per_tick)
  @id = id
  @jobs = 0.0
  @tick = 0
  @edges = []
  @arrivals_per_tick = arrivals_per_tick
end

def tick
  @tick += 1
  @jobs += @arrivals_per_tick

  if @edges.any?
    # only supports two edges
    probability, _ = @edges[0][0]
    index = nil

    [@jobs.floor, 10].min.times do
      if Kernel.rand <= probability
        index = 0
      else
        index = 1
      end

      @edges[index][1].jobs += 1.0
      # puts "Tick #{@tick}, node: #{@id}, pushed to: #{@edges[index][1].id}"
      @jobs -= 1
    end
  end
end

def print
  visual = "@" * [jobs, 42].min
  puts "#{visual}[ #{@id} ]"
end
end

one = Node.new('1', 10)
two = Node.new('2', 1)
three = Node.new('3', 1)
sink = Node.new('sink', 0)

one.edges << [0.8, two]
one.edges << [0.2, three]

two.edges << [0.8, sink]
two.edges << [0.2, three]

three.edges << [1.0, one]

def printer(one, two, three, sink)
ascii = <<~HEREDOC
\e[H\e[2J
                                                   
                ---1---->+------------+          
                         |  Server 2  ---0.8-----> #{"%03d" % sink.jobs}
         |----0.8------->|  #{"%03d" % two.jobs}       |          
         |               +------------+          
         |                         |             
  +------+-----+                   | 0.2           
5.2|  Server 1  ---0.2----+         |             
--->  #{"%03d" % one.jobs}       |         |         |             
  +------^-----+         |         |             
         |               |---------|--+          
         |               |  Server 3  |          
         +--1.0----------|  #{"%03d" % three.jobs}       |
                    1--->+------------+
HEREDOC
sleep 0.01
puts ascii
end

1000.times do |i|
one.tick
printer(one, two, three, sink)
two.tick
printer(one, two, three, sink)
three.tick
printer(one, two, three, sink)
end

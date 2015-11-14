require './pqueue.rb'

=begin
Example code for hierarchical clustering
=end

def getMedian(alist)
    # get median value of list alist
    tmp = alist.dup
    tmp.sort!
    alen = tmp.length
    if (alen % 2) == 1
        return tmp[alen / 2]
    else
        return (tmp[alen / 2] + tmp[(alen / 2) - 1]) / 2
    end
end
    
def normalizeColumn(column)
    # Normalize column using Modified Standard Score
    median = getMedian(column)
    arr = []
    column.each { |x| arr << (x - median).abs }
    asd = arr.inject(:+) / column.length
    result = column.map {|x| (x - median) / asd}
end

class HClusterer
=begin
    this clusterer assumes that the first column of the data is a label
    not used in the clustering. The other columns contain numeric data
=end
    
    def initialize(filename)
        file = open(filename)
        @data = {}
        @counter = 0
        @queue = PQueue.new
        lines = file.readlines
        file.close()
        header = lines[0].split(",")
        @cols = header.length
        @data = []
        header.length.times {@data << [] }

        lines[1..lines.length-1].each do |line|
            cells = line.split(",")
            toggle = 0
            0.upto @cols-1 do |cell|
                if toggle == 0
                   @data[cell] << cells[cell]
                   toggle = 1
                else
                    @data[cell] << cells[cell].to_f
                end
            end
        end

        # now normalize number columns (that is, skip the first column)
        1.upto(@cols-1) {|i| @data[i] = normalizeColumn(@data[i])}

        ###
        ###  I have read in the data and normalized the 
        ###  columns. Now for each element i in the data, I am going to
        ###     1. compute the Euclidean Distance from element i to all the 
        ###        other elements.  This data will be placed in neighbors,
        ###        which is a Python dictionary. Let's say i = 1, and I am 
        ###        computing the distance to the neighbor j and let's say j 
        ###        is 2. The neighbors dictionary for i will look like
        ###        {2: ((1,2), 1.23),  3: ((1, 3), 2.3)... }
        ###
        ###     2. find the closest neighbor
        ###
        ###     3. place the element on a priority queue, called simply queue,
        ###        based on the distance to the nearest neighbor (and a counter
        ###        used to break ties.

        # now push distances on queue        
        rows = @data[0].length
        0.upto rows-1 do |i|
            minDistance = 99999
            nearestNeighbor = 0
            neighbors = {}
             0.upto rows-1 do |j|
                if i != j
                    dist = distance(i, j)
                    if i < j
                        pair = [i,j]
                    else
                        pair = [j,i]
                    end
                    neighbors[j] = [pair, dist]
                    if dist < minDistance
                        minDistance = dist
                        nearestNeighbor = j
                        nearestNum = j
                    end
                end
            end
            # create nearest Pair
            if i < nearestNeighbor
                nearestPair = [i, nearestNeighbor]
            else
                nearestPair = [nearestNeighbor, i]
            end
                
            # put instance on priority queue    
            @queue.push ([minDistance, @counter, [[@data[0][i]], nearestPair, neighbors]])
            @counter += 1
        end
    end
    
    def distance(i, j)
        sumSquares = 0
        1.upto(@cols-1) {|k| sumSquares += (@data[k][i] - @data[k][j])**2}
        return Math.sqrt(sumSquares)
    end
            
    def cluster
		done = false
        while not done
            topOne = @queue.pop
            nearestPair = topOne[2][1]
            if not @queue.empty?
                nextOne = @queue.pop
                nearPair = nextOne[2][1]
                tmp = []
                ##
                ##  I have just popped two elements off the queue,
                ##  topOne and nextOne. I need to check whether nextOne
                ##  is topOne's nearest neighbor and vice versa.
                ##  If not, I will pop another element off the queue
                ##  until I find topOne's nearest neighbor. That is what
                ##  this while loop does.
                ##

                while nearPair != nearestPair
                    tmp << [nextOne[0], @counter, nextOne[2]]
                    @counter += 1
                    nextOne = @queue.pop
                    nearPair = nextOne[2][1]
                end
                ##
                ## this for loop pushes the elements I popped off in the
                ## above while loop.
                ##                 
                tmp.each do |item|
                    @queue.push (item)
                end
                     
                if topOne[2][0].length == 1
                    item1 = topOne[2][0][0]
                else
                    item1 = topOne[2][0]
                end
                if nextOne[2][0].length == 1
                    item2 = nextOne[2][0][0]
                else
                    item2 = nextOne[2][0]
                end
                ##  curCluster is, perhaps obviously, the new cluster
                ##  which combines cluster item1 with cluster item2.
                ## curCluster = (item1, item2)
                curCluster = [item1, item2]

                ## Now I am doing two things. First, finding the nearest
                ## neighbor to this new cluster. Second, building a new
                ## neighbors list by merging the neighbors lists of item1
                ## and item2. If the distance between item1 and element 23
                ## is 2 and the distance betweeen item2 and element 23 is 4
                ## the distance between element 23 and the new cluster will
                ## be 2 (i.e., the shortest distance).
                ##
                minDistance = 99999
                nearestPair = ()
                nearestNeighbor = ''
                merged = {}
                nNeighbors = nextOne[2][2]
                topOne[2][2].each do |key, value|
                    if nNeighbors.has_key? key
                        if nNeighbors[key][1] < value[1]
                             dist =  nNeighbors[key]
                        else
                            dist = value
                        end
                        if dist[1] < minDistance
                             minDistance =  dist[1]
                             nearestPair = dist[0]
                             nearestNeighbor = key
                        end
                        merged[key] = dist
                    end
                end
                    
                if merged == {}
                    return curCluster
                else
                    @queue.push([minDistance, @counter, [curCluster, nearestPair, merged]]) 
                    @counter += 1
                end
            end                   
        end               
     end                    
end

def printDendrogram(t, sep=3)
=begin    
    Print dendrogram of a binary tree.  Each tree node is represented by a
    length-2 tuple. printDendrogram is written and provided by David Eppstein
    2002. Accessed on 14 April 2014:
    http://code.activestate.com/recipes/139422-dendrogram-drawing/ """
=end
	
    isPair = lambda do |t|
        return t.class == Array && t.length == 2
    end
    
    maxHeight = lambda do |t|
        if isPair.call(t)
            h = [maxHeight.call(t[0]), maxHeight.call(t[1])].max
        else
            h = t.to_s.length
        end
        return h + sep
    end

    activeLevels = {}
    
    traverse = lambda do |t, h, isFirst|
        if isPair.call(t)
            traverse.call(t[0], h-sep, 1)
            s = [" "]*(h-sep)
            s << "|"
        else
            s = t.chars
            s << (" ")
        end
        
        while s.length < h
            s << ("-")
        end
        
        if (isFirst >= 0)
            s << ("+")
            if isFirst > 0
                activeLevels[h] = 1
            else
                activeLevels.delete(h)
            end
        end
        
        a = activeLevels.keys
        a.sort!
        a.each do |l|
            if s.length < l
                while s.length < l
                    s << (" ")
                end
                s << ("|")
            end    

        end
        puts s.join("")
        
        if isPair.call(t)
            traverse.call(t[1], h-sep, 0)
        end
    end
    traverse.call(t, maxHeight.call(t), -1)
end

filename = 'dogs.csv'

hg = HClusterer.new(filename)
cluster = hg.cluster()
printDendrogram(cluster)


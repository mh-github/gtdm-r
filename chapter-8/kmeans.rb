
=begin
Implementation of the K-means algorithm
for the book A Programmer's Guide to Data Mining"
http://www.guidetodatamining.com

=end

def getMedian(alist)
    # get median of list
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
    # normalize the values of a column using Modified Standard Score
    # that is (each value - median) / (absolute standard deviation)
    median = getMedian(column)
    arr = []
    column.each {|x| arr << (x - median).abs}
    asd = arr.inject(:+) / column.length
    result = []
    column.each {|x| result << (x - median) / asd}
    return result
end

class KClusterer
=begin
    Implementation of kMeans Clustering
    This clusterer assumes that the first column of the data is a label
    not used in the clustering. The other columns contain numeric data
=end
    
    def initialize(filename, k)
=begin
        k is the number of clusters to make
        This init method:
           1. reads the data from the file named filename
           2. stores that data by column in @data
           3. normalizes the data using Modified Standard Score
           4. randomly selects the initial centroids
           5. assigns points to clusters associated with those centroids
=end
        file = open(filename)
        @data = {}
        @k = k
        @counter = 0
        @iterationNumber = 0
        # used to keep track of % of points that change cluster membership
        # in an iteration
        @pointsChanged = 0
        # Sum of Squared Error
        @sse = 0
        #
        # read data from file
        #
        lines = file.readlines
        file.close()
        header = lines[0].split(",")
        @cols = header.length
        @data = []
        0.upto header.length-1 do |i|
            @data << []
        end
        # we are storing the data by column.
        # For example, @data[0] is the data from column 0.
        # @data[0][10] is the column 0 value of item 10.
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
                    
        @datasize = @data[1].length
        @memberOf = []
        0.upto @data[1].length-1 do |x| 
            @memberOf << -1
        end
        #
        # now normalize number columns
        #
        1.upto @cols-1 do |i|
            @data[i] = normalizeColumn(@data[i])
        end
        # select random centroids from existing points
        srand
        @centroids = []
        tmpRangeArr = []
        0.upto @data[0].length - 1 do |i|
            tmpRangeArr << i
        end
        tmpRangeArr.sample(@k).each do |r|
            tmp = []
            1.upto @data.length-1 do |i| 
                tmp << @data[i][r]
            end
            @centroids << tmp
        end
        assignPointsToCluster()
    end      

    def updateCentroids
=begin
        Using the points in the clusters, determine the centroid
        (mean point) of each cluster
=end    
        members = []
        0.upto @centroids.length-1 do |i|
            members << @memberOf.count(i)
        end
        tmpCentroids = []
        0.upto @centroids.length-1 do |centroid|
            tmpCentroid = []
            1.upto @data.length-1 do |k|
                total = 0
                0.upto @data[0].length-1 do |i|
                    if @memberOf[i] == centroid
                        total += @data[k][i]
                    end
                end
                tmpCentroid << total.to_f/members[centroid]
            end
            tmpCentroids << tmpCentroid
        end
        @centroids = tmpCentroids
    end
            
    def assignPointToCluster(i)
        # assign point to cluster based on distance from centroids
        min = 999999
        clusterNum = -1
        0.upto @k-1 do |centroid|
            dist = euclideanDistance(i, centroid)
            if dist < min
                min = dist
                clusterNum = centroid
            end
        end
        # here is where I will keep track of changing points
        if clusterNum != @memberOf[i]
            @pointsChanged += 1
        end
        # add square of distance to running sum of squared error
        @sse += min**2
        return clusterNum
    end

    def assignPointsToCluster
        # assign each data point to a cluster
        @pointsChanged = 0
        @sse = 0
        tmpArr = []
        0.upto @data[1].length-1 do |i|
            tmpArr << assignPointToCluster(i)
        end
        @memberOf = tmpArr
    end
        
    def euclideanDistance(i, j)
        # compute distance of point i from centroid j
        sumSquares = 0
        1.upto @cols-1 do |k|
            sumSquares += (@data[k][i] - @centroids[j][k-1])**2
        end
        return Math.sqrt(sumSquares)
    end

    def kCluster
=begin
        the method that actually performs the clustering
        As you can see this method repeatedly
            updates the centroids by computing the mean point of each cluster
            re-assign the points to clusters based on these new centroids
        until the number of points that change cluster membership is less than 1%.
=end
        done = false
 
        while not done
            @iterationNumber += 1
            updateCentroids()
            assignPointsToCluster()
            #
            # we are done if fewer than 1% of the points change clusters
            #
            if (@pointsChanged.to_f / @memberOf.length) <  0.01
                done = true
            end
        end
        print("Final SSE: %f\n" % @sse)
    end

    def showMembers
        # Display the results
        0.upto @centroids.length-1 do |centroid|
             print "\n\nClass %i\n========\n" % centroid
             ## tmpArr = []
             0.upto @data[0].length-1 do |i|
                if @memberOf[i] == centroid
                    ## tmpArr << @data[0][i]
                    puts @data[0][i]
                end
             end
        end
    end
end
        
##
## RUN THE K-MEANS CLUSTERER ON THE DOG DATA USING K = 3
###
# change the path in the following to match where dogs.csv is on your machine
km = KClusterer.new('dogs.csv', 3)
km.kCluster()
km.showMembers()

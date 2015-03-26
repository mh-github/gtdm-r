#  
# 
#  Nearest Neighbor Classifier for Pima dataset
#
#
#  Code file for the book Programmer's Guide to Data Mining
#  http://guidetodatamining.com
#
#  Ron Zacharski
#
$LOAD_PATH << '..'

require 'MH_util'
require 'Enumerable'

## import random

class Classifier

    def initialize(bucketPrefix, testBucketNumber, dataFormat, k)
=begin
        a classifier will be built from files with the bucketPrefix
        excluding the file with textBucketNumber. dataFormat is a string that
        describes how to interpret each line of the data files. For example,
        for the mpg data the format is:

        "class	num	num	num	num	num	comment"
=end
   
        @medianAndDeviation = []
        @k = k
        # reading the data in from the file
 
        @format = dataFormat.strip.split("\t")
        @data = []
        # for each of the buckets numbered 1 through 10:
        1.upto 10 do |i|
            # if it is not the bucket we should ignore, read in the data
            if i != testBucketNumber
                filename = "%s-%02i" % [bucketPrefix, i]
                f = File.open(filename)
                lines = f.readlines()
                f.close()
                lines[1..lines.length].each do |line|
                    fields = line.strip.split("\t")
                    ignore = []
                    vector = []
                    classification = "" # how is the python code working with out this
                    0.upto fields.length do |i|
                        if @format[i] == 'num'
                            vector << fields[i].to_f
                        elsif @format[i] == 'comment'
                            ignore << fields[i].to_f
                        elsif @format[i] == 'class'
                            classification = fields[i]
                        end
                    end
                    @data << [classification, vector, ignore]
                end
            end
        end
                    
        @rawData = @data.dup
        # get length of instance vector
        @vlen = @data[0][1].length
        # now normalize the data
        0.upto @vlen-1 do |i|
            normalizeColumn(i)
        end
    end

    ##################################################
    ###
    ###  CODE TO COMPUTE THE MODIFIED STANDARD SCORE

    def getMedian(alist)
        # return median of alist
        if alist == []
            return []
        end
        blist = alist.sort
        length = alist.length
        if length % 2 == 1
            # length of list is odd so return middle element
            return blist[( ((length + 1)/2) -1).to_i]
        else
            # length of list is even so compute midpoint
            v1 = blist[(length / 2).to_i]
            v2 = blist[((length / 2)-1).to_i]
            return (v1 + v2) / 2.0
        end
    end
        
    def getAbsoluteStandardDeviation(alist, median)
        # given alist and median return absolute standard deviation
        sum = 0
        alist.each do |item|
            sum += (item - median).abs
        end
        return sum / alist.length
    end

    def normalizeColumn(columnNumber)
       # given a column number, normalize that column in @data
       # first extract values to list
       col = @data.each.map {|v| v[1][columnNumber]}
       median = getMedian(col)
       asd = getAbsoluteStandardDeviation(col, median)
       #print("Median: %f   ASD = %f" % (median, asd))
       @medianAndDeviation << [median, asd]
       @data.each do |v|
           v[1][columnNumber] = (v[1][columnNumber] - median) / asd
       end
   end

    def normalizeVector(v)
        # We have stored the median and asd for each column.
        # We now use them to normalize vector v
        vector = v.dup
        0.upto vector.length-1 do |i|
            (median, asd) = @medianAndDeviation[i]
            vector[i] = (vector[i] - median) / asd
        end
        return vector
    end
    
    ###
    ### END NORMALIZATION
    ##################################################

    def testBucket(bucketPrefix, bucketNumber)
=begin    
    Evaluate the classifier with data from the file
        bucketPrefix-bucketNumber
=end
        
        filename = "%s-%02i" % [bucketPrefix, bucketNumber]
        f = File.open(filename)
        lines = f.readlines()
        totals = {}
        f.close()
        lines.each do |line|
            data = line.strip.split("\t")
            vector = []
            classInColumn = -1
            0.upto @format.length-1 do |i|
                  if @format[i] == 'num'
                      vector << data[i].to_f
                  elsif @format[i] == 'class'
                      classInColumn = i
                  end
            end
            theRealClass = data[classInColumn]
            classifiedAs = classify(vector)
            totals[theRealClass] = {} if not totals.has_key? theRealClass
            totals[theRealClass][classifiedAs] = 0 if not totals[theRealClass].has_key? classifiedAs
            totals[theRealClass][classifiedAs] += 1
        end
        return totals
    end

    def manhattan(vector1, vector2)
        # Computes the Manhattan distance.
        return vector1.map.with_index{|v, i| (v - vector2[i]).abs}.inject(:+)
    end

    def knn(itemVector)
=begin returns the predicted class of itemVector using k
        Nearest Neighbors
=end
        # changed from min to heapq.nsmallest to get the
        # k closest neighbors
        distances = []
        @data.each do |item|
            distances << [manhattan(itemVector, item[1]), item]
        end
        neighbors = distances.min_n(@k)
        
        # each neighbor gets a vote
        results = {}
        neighbors.each do |neighbor|
            theClass = neighbor[1][0]
            results[theClass] = 0 if not results.has_key? theClass
            results[theClass] += 1
        end
        resultList = []
        results.to_a.each do |i|
            resultList << MH_util::Tuple.new(i[1], i[0])
        end
        resultList.sort!.reverse!
        
        #get all the classes that have the maximum votes
        maxVotes = resultList[0][0]
        possibleAnswers = []
        resultList.each do |i|
            possibleAnswers << i.second if i.first == maxVotes
        end
        
        # randomly select one of the classes that received the max votes
        answer = possibleAnswers.sample
        return( answer)
    end
    
    def classify(itemVector)
        # Return class we think item Vector is in
        # k represents how many nearest neighbors to use
        return (knn(normalizeVector(itemVector)))                             
    end
end
       
def tenfold(bucketPrefix, dataFormat, k)
    results = {}
    1.upto 10 do |i|
        c = Classifier.new(bucketPrefix, i, dataFormat, k)
        t = c.testBucket(bucketPrefix, i)
        t.each do |key, value|
            results[key] = {} if not results.has_key? key
            value.each do |ckey, cvalue|
                results[key][ckey] = 0 if not results[key].has_key? ckey
                results[key][ckey] += cvalue
            end
        end
    end
                
    # now print results
    categories = results.keys.dup
    categories.sort!
    print(   "\n       Classified as: \n")
    header =    "        "
    subheader = "      +"
    categories.each do |category|
        header += "% 2s   " % category
        subheader += "-----+"
    end
    print (header) + "\n"
    print (subheader) + "\n"
    total = 0.0
    correct = 0.0
    categories.each do |category|
        row = " %s    |" % category 
        categories.each do |c2|
            if results[category].has_key? c2
                count = results[category][c2]
            else
                count = 0
            end
            row += " %3i |" % count
            total += count
            if c2 == category
                correct += count
            end
        end
        print row + "\n"
    end
    print subheader + "\n"
    print("\n%5.3f percent correct\n" %((correct * 100) / total))
    print("total of %i instances" % total)
end

print("SMALL DATA SET")
tenfold("pimaSmall/pimaSmall",
        "num	num	num	num	num	num	num	num	class", 3)
print("\n\nLARGE DATA SET")

tenfold("pima/pima",
        "num	num	num	num	num	num	num	num	class", 3)

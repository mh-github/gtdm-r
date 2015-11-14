#! /usr/bin/env ruby
#
#  Nearest Neighbor Classifier 
#
#
#  Code file for the book Programmer's Guide to Data Mining
#  http://guidetodatamining.com
#
#  Ron Zacharski
#


##   I am trying to make the classifier more general purpose
##   by reading the data from a file.
##   Each line of the file contains tab separated fields.
##   The first line of the file describes how those fields (columns) should
##   be interpreted. The descriptors in the fields of the first line are:
##
##        comment   -  this field should be interpreted as a comment
##        class     -  this field describes the class of the field
##        num       -  this field describes an integer attribute that should 
##                     be included in the computation.
##
##        more to be described as needed
## 
##
##    So, for example, if our file describes athletes and is of the form:
##    Shavonte Zellous   basketball  70  155
##    The first line might be:
##    comment   class  num   num
##
##    Meaning the first column (name of the player) should be considered a comment; 
##    the next column represents the class of the entry (the sport); 
##    and the next 2 represent attributes to use in the calculations.
##
##    The classifer reads this file into the list called data.
##    The format of each entry in that list is a tuple
##  
##    (class, normalized attribute-list, comment-list)
##
##    so, for example
##
##   [('basketball', [1.28, 1.71], ['Brittainey Raven']),
##    ('basketball', [0.89, 1.47], ['Shavonte Zellous']),
##    ('gymnastics', [-1.68, -0.75], ['Shawn Johnson']),
##    ('gymnastics', [-2.27, -1.2], ['Ksenia Semenova']),
##    ('track', [0.09, -0.06], ['Blake Russell'])]
##
   
            
class Classifier
    attr_reader :data, :format

    def initialize(filename)

        @medianAndDeviation = []
        
        # reading the data in from the file
        lines = File.readlines(filename)
        @format = lines[0].strip.split("\t")
        @data = []

        lines[1..lines.length-1].each do |line|
            fields = line.strip.split("\t")
            ignore = []
            vector = []
            classification = "" # how is the python code working with out this
            0.upto fields.length-1 do |i|
                if @format[i] == 'num'
                    vector << fields[i].to_f
                elsif @format[i] == 'comment'
                    ignore << fields[i]
                elsif @format[i] == 'class'
                    classification = fields[i]
                end
            end
            @data << [classification, vector, ignore]
        end
        @rawData = @data.dup
        # get length of instance vector
        @vlen = @data[0][1].length
        # now normalize the data
        0.upto(@vlen-1) {|i| normalizeColumn(i)}
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
        col = @data.map {|v| v[1][columnNumber]}
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

    def manhattan(vector1, vector2)
        # Computes the Manhattan distance.
        return vector1.map.with_index{|v, i| (v - vector2[i]).abs}.inject(:+)
    end

    def nearestNeighbor(itemVector)
        # return nearest neighbor to itemVector
        distances = []
        @data.each do |item|
            distances << [manhattan(itemVector, item[1]), item]
        end
        return distances.min
    end
    
    def classify(itemVector)
        # Return class we think item Vector is in
        return nearestNeighbor(normalizeVector(itemVector))[1][0]
    end
end
 
def test(training_filename, test_filename)
    # Test the classifier on a test set of data
    classifier = Classifier.new(training_filename)
    lines = File.readlines(test_filename)

    numCorrect = 0.0
    lines.each do |line|
        data = line.strip.split("\t")
        vector = []
        classInColumn = -1
        0.upto classifier.format.length-1 do |i|
              if classifier.format[i] == 'num'
                  vector << data[i].to_f
              elsif classifier.format[i] == 'class'
                  classInColumn = i
              end
        end
        theClass = classifier.classify(vector)
        prefix = '-'
        if theClass == data[classInColumn]
            # it is correct
            numCorrect += 1
            prefix = '+'
        end
        print "%s  %12s  %s\n" % [prefix, theClass, line]
    end
    print "%4.2f%% correct\n" % [numCorrect * 100/ lines.length]
end

##
##  Here are examples of how the classifier is used on different data sets
##  in the book.
#  test('athletesTrainingSet.txt', 'athletesTestSet.txt')
#  test("irisTrainingSet.data", "irisTestSet.data")
test("mpgTrainingSet.txt", "mpgTestSet.txt")

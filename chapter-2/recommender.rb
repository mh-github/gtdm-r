#! /usr/bin/env ruby
require '../mh_util.rb'

users = {"Angelica" => {"Blues Traveler" => 3.5, "Broken Bells" => 2.0,
                        "Norah Jones" => 4.5, "Phoenix" => 5.0,
                        "Slightly Stoopid" => 1.5,
                        "The Strokes" => 2.5, "Vampire Weekend" => 2.0},
         
         "Bill"     => {"Blues Traveler" => 2.0, "Broken Bells" => 3.5,
                        "Deadmau5" => 4.0, "Phoenix" => 2.0,
                        "Slightly Stoopid" => 3.5, "Vampire Weekend" => 3.0},
         
         "Chan"     => {"Blues Traveler" => 5.0, "Broken Bells" => 1.0,
                        "Deadmau5" => 1.0, "Norah Jones" => 3.0, "Phoenix" => 5,
                        "Slightly Stoopid" => 1.0},
         
         "Dan"      => {"Blues Traveler" => 3.0, "Broken Bells" => 4.0,
                        "Deadmau5" => 4.5, "Phoenix" => 3.0,
                        "Slightly Stoopid" => 4.5, "The Strokes" => 4.0,
                        "Vampire Weekend" => 2.0},
         
         "Hailey"   => {"Broken Bells" => 4.0, "Deadmau5" => 1.0,
                        "Norah Jones" => 4.0, "The Strokes" => 4.0,
                        "Vampire Weekend" => 1.0},
         
         "Jordyn"   => {"Broken Bells" => 4.5, "Deadmau5" => 4.0,
                        "Norah Jones" => 5.0, "Phoenix" => 5.0,
                        "Slightly Stoopid" => 4.5, "The Strokes" => 4.0,
                        "Vampire Weekend" => 4.0},
         
         "Sam"      => {"Blues Traveler" => 5.0, "Broken Bells" => 2.0,
                        "Norah Jones" => 3.0, "Phoenix" => 5.0,
                        "Slightly Stoopid" => 4.0, "The Strokes" => 5.0},
         
         "Veronica" => {"Blues Traveler" => 3.0, "Norah Jones" => 5.0,
                        "Phoenix" => 4.0, "Slightly Stoopid" => 2.5,
                        "The Strokes" => 3.0}
}

class Recommender

    def initialize(data, k=1, metric='pearson', n=5)
=begin       
        initialize recommender
        currently, if data is dictionary the recommender is initialized
        to it.
        For all other data types of data, no initialization occurs
        k is the k value for k nearest neighbor
        metric is which distance formula to use
        n is the maximum number of recommendations to make
=end
        @k = k
        @n = n
        @username2id = {}
        @userid2name = {}
        @productid2name = {}
        # for some reason I want to save the name of the metric
        @metric = metric
        if @metric == 'pearson'
            @fn = @pearson
        end
        #
        # if data is dictionary set recommender data to it
        #
        if data.class == Hash
            @data = data
        end
    end

    def convertProductID2name(id)
        # Given product id number return product name
        if @productid2name.has_key? id
            return @productid2name[id]
        else
            return id
        end
    end

    def userRatings(id, n)
        # Return n top ratings for user with id
        print ("Ratings for " + @userid2name[id]) + "\n"
        ratings = @data[id]
        puts ratings.length
        ratings = ratings.to_a
        ratings.map do |element|
            element[0] = convertProductID2name(element[0])
        end
        # finally sort and return
        ratings.sort_by! {|element| -element[1]}
        ratings = ratings[0..n-1]
        ratings.each {|rating| print ("%s\t%i\n" % [rating[0], rating[1]])}
    end
       
    def loadBookDB(path='')
=begin 
        loads the BX book dataset. Path is where the BX files are
        located
=end
        @data = {}
        i = 0
        #
        # First load book ratings into self.data
        #
        f = File.open(path + "BX-Book-Ratings.csv", "r:utf-8")
        f.each_line do |line|
            i += 1
            #separate line into fields
            fields = line.split(';')
            user = fields[0].delete('"')
            book = fields[1].delete('"')
            rating = fields[2].strip.delete('"').to_i
            if @data.has_key? user
                currentRatings = @data[user]
            else
                currentRatings = {}
            end
            currentRatings[book] = rating
            @data[user] = currentRatings
        end
        f.close()
        #
        # Now load books into self.productid2name
        # Books contains isbn, title, and author among other fields
        #
        f = File.open(path + "BX-Books.csv", "r:utf-8")
        f.each_line do |line|
            i += 1
            #separate line into fields
            fields = line.split(';')
            isbn = fields[0].delete('"')
            title = fields[1].delete('"')
            author = fields[2].strip.delete('"')
            title = title + ' by ' + author
            @productid2name[isbn] = title
        end
        f.close()
        #
        #  Now load user info into both self.userid2name and
        #  self.username2id
        #
        f = File.open(path + "BX-Users.csv", "r:utf-8")
        f.each_line do |line|
            i += 1
            #separate line into fields
            fields = line.split(';')
            userid = fields[0].delete('"')
            location = fields[1].delete('"')
            if fields.length > 3
                age = fields[2].strip.delete('"')
            else
                age = 'NULL'
            end
            if age != 'NULL'
                value = location + '  (age: ' + age + ')'
            else
                value = location
            end
            @userid2name[userid] = value
            @username2id[location] = userid
        end
        f.close()
        print "%i\n" % i
    end            
        
    def pearson(rating1, rating2)
        sum_xy = 0
        sum_x = 0
        sum_y = 0
        sum_x2 = 0
        sum_y2 = 0
        n = 0

        rating1.each do |key, value|
            if rating2.has_key? key
                n += 1
                x = rating1[key]
                y = rating2[key]
                sum_xy += x * y
                sum_x += x
                sum_y += y
                sum_x2 += x ** 2
                sum_y2 += y ** 2
            end
        end
        if n == 0
            return 0
        end
        # now compute denominator
        denominator = Math.sqrt(sum_x2 - sum_x**2 / n) \
                      * Math.sqrt(sum_y2 - sum_y**2 / n)
        if denominator == 0
            return 0
        else
            return (sum_xy - (sum_x * sum_y) / n) / denominator
        end
    end

    def computeNearestNeighbor(username)
=begin
        creates a sorted list of users based on their distance to
        username
=end  
        distances = []
        @data.each do |instance, value|
            if instance != username
                # todo how to invoke pearson method via fn
                distance = pearson(@data[username], @data[instance])
                distances << MH_util::Tuple.new(instance, distance)
            end
        end
        # sort based on distance -- closest first
        return distances.sort_by {|element| -element.second}
    end

    def recommend(user)
       # Give list of recommendations
       recommendations = {}
       # first get list of users ordered by nearness
       nearest = computeNearestNeighbor(user)
       #
       # now get the ratings for the user
       #
       userRatings = @data[user]
       #
       # determine the total distance
       totalDistance = 0.0
       0.upto @k-1 do |i|
          totalDistance += nearest[i].second
       end
       # now iterate through the k nearest neighbors
       # accumulating their ratings
       0.upto @k-1 do |i|
          # compute slice of pie 
          weight = nearest[i].second / totalDistance
          # get the name of the person
          name = nearest[i].first
          # get the ratings for this person
          neighborRatings = @data[name]
          # get the name of the person
          # now find bands neighbor rated that user didn't
          neighborRatings.each do |artist, value|
             if not userRatings.has_key? artist
                if not recommendations.has_key? artist
                   recommendations[artist] = neighborRatings[artist] * weight
                else
                   recommendations[artist] = (recommendations[artist] \
                                              + neighborRatings[artist] \
                                              * weight)
                end
             end
          end
        end
       # now make list from dictionary
       recommendations = recommendations.to_a
       recommendations.map do |element|
           element[0] = convertProductID2name(element[0])
       end

       # finally sort and return
       recommendations.sort_by! {|element| -element[1]}
       # Return the first n items
       return recommendations[0..@n-1]
    end
end

r = Recommender.new(users)

r.loadBookDB('BX-Dump/')
r.recommend("171118").each {|element| print element[0] + " " + element[1].to_s + "\n"}

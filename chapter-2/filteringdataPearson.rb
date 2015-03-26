#!/usr/bin/env ruby
require "../MH_util"

users = {
        "Angelica" =>
            {"Blues Traveler" => 3.5, "Broken Bells" => 2.0, "Norah Jones" => 4.5,
              "Phoenix" => 5.0, "Slightly Stoopid" => 1.5, "The Strokes" => 2.5,
              "Vampire Weekend" => 2.0},
         "Bill" => 
            {"Blues Traveler" => 2.0, "Broken Bells" => 3.5, "Deadmau5" => 4.0,
             "Phoenix" => 2.0, "Slightly Stoopid" => 3.5, "Vampire Weekend" => 3.0},
         "Chan" =>
            {"Blues Traveler" => 5.0, "Broken Bells" => 1.0, "Deadmau5" => 1.0,
             "Norah Jones" => 3.0, "Phoenix" => 5, "Slightly Stoopid" => 1.0},
         "Dan" =>
            {"Blues Traveler" => 3.0, "Broken Bells" => 4.0, "Deadmau5" => 4.5,
             "Phoenix" => 3.0, "Slightly Stoopid" => 4.5, "The Strokes" => 4.0,
             "Vampire Weekend" => 2.0},
         "Hailey" =>
            {"Broken Bells" => 4.0, "Deadmau5" => 1.0, "Norah Jones" => 4.0,
             "The Strokes" => 4.0, "Vampire Weekend" => 1.0},
         "Jordyn" =>
            {"Broken Bells" => 4.5, "Deadmau5" => 4.0, "Norah Jones" => 5.0,
             "Phoenix" => 5.0, "Slightly Stoopid" => 4.5, "The Strokes" => 4.0,
             "Vampire Weekend" => 4.0},
         "Sam" =>
            {"Blues Traveler" => 5.0, "Broken Bells" => 2.0, "Norah Jones" => 3.0,
             "Phoenix" => 5.0, "Slightly Stoopid" => 4.0, "The Strokes" => 5.0},
         "Veronica" =>
            {"Blues Traveler" => 3.0, "Norah Jones" => 5.0, "Phoenix" => 4.0,
             "Slightly Stoopid" => 2.5, "The Strokes" => 3.0}
        }

def manhattan(rating1, rating2)
=begin
    Computes the Manhattan distance. Both rating1 and rating2 are dictionaries
    of the form {'The Strokes': 3.0, 'Slightly Stoopid': 2.5}
=end
    distance = 0
    total = 0
    rating1.each do |key, value|
        if rating2.has_key?key
            distance += (rating1[key] - rating2[key]).abs
            total += 1
        end
    end
    if total > 0
        return distance / total
    else
        return -1 #Indicates no ratings in common
    end
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
    # now compute denominator
    denominator = Math.sqrt(sum_x2 - (sum_x ** 2) / n) * Math.sqrt(sum_y2 - (sum_y ** 2) / n)
    if denominator == 0
        return 0
    else
        return (sum_xy - (sum_x * sum_y) / n) / denominator
    end
end    
            
def computeNearestNeighbor(username, users)
    # creates a sorted list of users based on their distance to username
    distances = []
    users.each do |user, value|
        if user != username
            distance = manhattan(users[user], users[username])
            distances << MH_util::Tuple.new(distance, user)
        end
    end
    
    # sort based on distance -- closest first
    return distances.sort
end

def recommend(username, users)
    # Give list of recommendations
    # first find nearest neighbor
    nearest = computeNearestNeighbor(username, users)[0].second
    
    recommendations = []
    # now find bands neighbor rated that user didn't
    neighborRatings = users[nearest]
    userRatings = users[username]
    neighborRatings.each do |artist, value|
        if not userRatings.has_key?artist
            recommendations << MH_util::Tuple.new(artist, neighborRatings[artist])
        end
    end
    # using the fn sorted for variety - sort is more efficient
    return recommendations.sort_by {|element| -element.second}
end

puts pearson(users['Angelica'], users['Bill'])
puts pearson(users['Angelica'], users['Hailey'])
puts pearson(users['Angelica'], users['Jordyn'])

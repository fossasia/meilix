#!/usr/bin/env bash
set -e
echo "This is a script to delete obsolete meilix iso builds by Abishek V Ashok"
echo "You have to add an authorization token to make it functional."

# jq is the JSON parser we will be using
sudo apt-get -qq -y install jq

# Storing the response to a variable for future usage
response=`curl https://api.github.com/repos/fossasia/meilix/releases | jq '.[] | .id, .published_at'`

index=1  # when index is odd, $i contains id and when it is even $i contains published_date
delete=0 # Should we delete the release?
current_year=`date +%Y`  # Current year eg) 2001
current_month=`date +%m` # Current month eg) 2
current_day=`date +%d`   # Current date eg) 24

for i in $response; do
    if [ $((index % 2)) -eq 0 ]; then # We get the published_date of the release as $i's value here
        published_year=${i:1:4}
        published_month=${i:6:2}
        published_day=${i:9:2}

        if [ $published_year -lt $current_year ]; then
             let "delete=1"
        else
            if [ $published_month -lt $current_month ]; then
                let "delete=1"
            else
                if [ $((current_day-$published_day)) -gt 10 ]; then
                    let "delete=1"
                fi
            fi
        fi
    else # We get the id of the release as $i`s value here
        if [ $delete -eq 1 ]; then
            curl -X DELETE -H "Authorization: token $KEY" https://api.github.com/repos/fossasia/meilix/releases/$i
            let "delete=0"
        fi
    fi
    let "index+=1"
done

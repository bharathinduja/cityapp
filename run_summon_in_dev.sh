docker build -t $TEST_APP_IMAGE build/.

docker run --rm -p 3000:3000 --entrypoint "summon" $TEST_APP_IMAGE -e dev ruby /usr/src/cityapp.rb -o 0.0.0.0

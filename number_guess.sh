#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c" # --no-align -t

# randomly generate a number
SECRET_NUMBER=$((RANDOM % 1000 + 1))

# prompt the user for a username
echo "Enter your username:"
read USERNAME

# search the user id in the database
USER_ID=$($PSQL "SELECT user_id FROM usernames WHERE username='$USERNAME'")

# if user doesn't exist
if [[ -z $USER_ID ]]
then
  # add new username
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
  INSERT_USERNAME_RESULT=$($PSQL "INSERT INTO usernames(username) VALUES ('$USERNAME')")

  # get new user_id
  USER_ID=$($PSQL "SELECT user_id FROM usernames WHERE username='$USERNAME'")
else
  # get user games info
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM usernames WHERE user_id = $USER_ID")
  BEST_GAME=$($PSQL "SELECT best_game FROM usernames WHERE user_id = $USER_ID")
  
  # format the variables
  GAMES_PLAYED_FORMATTED=$(echo $GAMES_PLAYED | sed -E 's/^ *| *$//g')
  BEST_GAME_FORMATTED=$(echo $BEST_GAME | sed -E 's/^ *| *$//g')
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED_FORMATTED games, and your best game took $BEST_GAME_FORMATTED guesses."

  # increment the number of games played
  GAMES_PLAYED=$((GAMES_PLAYED + 1))

  # update the number of games played
  UPDATE_GAMES_PLAYED_RESULT=$($PSQL "UPDATE usernames SET games_played = $GAMES_PLAYED WHERE user_id = $USER_ID")
fi

# Prompt the number guess
echo -e "\nGuess the secret number between 1 and 1000:"
read NUMBER

NUMBER_GUESS(){
  if [[ $1 ]]
  then
    echo -e "\n$1"
    read NUMBER
  else
    # start counting the number of guesses
    GUESSES=0
  fi

  # if the number is an integer
  if [[ $NUMBER =~ ^[0-9]+$ ]]
  then
    # update guesses number
    GUESSES=$((GUESSES + 1))

    # if number is greater than the secret number
    if [[ $NUMBER -gt $SECRET_NUMBER ]]
    then
      NUMBER_GUESS "It's lower than that, guess again:"
    # if number is less than the secret number
    elif [[ $NUMBER -lt $SECRET_NUMBER ]]
    then
      NUMBER_GUESS "It's higher than that, guess again:"
    # if the number is equal to the secret number
    else
      echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    fi
  # if the number is not an integer
  else
    NUMBER_GUESS "That is not an integer, guess again:"
  fi
}

NUMBER_GUESS

BEST_GAME=$($PSQL "SELECT best_game FROM usernames WHERE user_id = $USER_ID")
# if best_game = 0 (first try) or if the actual number of guesses is lower than the best one
if [[ "$BEST_GAME" -eq 0 || "$GUESSES" -lt "$BEST_GAME" ]]
then
  # update best_game
  BEST_GAME_UPDATE_RESULT=$($PSQL "UPDATE usernames SET best_game = $GUESSES WHERE user_id=$USER_ID")
fi
#!/usr/bin/env bash

# user configurable
words_file=/usr/share/dict/words
quit_key=0

# set by the program
num_attempts=
answer=
question=
letters=()

array_contains() {
    # checks if the second argument (string) is in the first argument (array)
    local e

    for e in "${@:1:1}"; do
        [[ "$e" == "$2" ]] && return $(true)
    done

    return $(false)
}

gameover() {
    echo -e "Game over. Answer: $answer"
    echo -e "Thanks for playing. Goodbye!\n"
}

gamewin() {
    # win condition: no more blanks to guess

    # search for underscores in $question
    if [[ "$question" =~ _ ]]; then
        return $(false)
    fi

    echo -e "You win! Great job, thanks for playing!\n"
}

generate_question() {
    # retrieve a random word from word file
    answer=$(python -c "import random, sys; print random.choice(open(sys.argv[1]).readlines())" $words_file)

    # generate blanks for the question
    local i
    for (( i=0; i<${#answer}; i++ )); do
        if [[ "${answer:$i:1}" =~ [[:space:]] ]]; then
            question+="  "
        else
            question+="_ "
        fi
    done

    # the number of attempts is based on the length of the answer
    # somewhat arbitrary formula
    num_attempts=$(( ${#answer} / 2 + 3 ))
}

print_letters() {
    if [[ "${#letters[*]}" > 0 ]]; then
        echo "${letters[*]}"
    fi
}

print_question() {
    echo -e "\n\n\t$question\n\n"
}

print_prompt() {
    echo -en "Enter a letter ($quit_key to quit). "

    local attempts="attempt"
    if [[ "$num_attempts" > 1 ]]; then
        attempts+="s"
    fi

    echo -e "$num_attempts $attempts left."
    echo -en "> "
}

print_welcome() {
    echo -e "Welcome to Hangman. Have fun!"
}

process_user_input() {
    local c="$user_input"
    local pos=()
    local i
    local ans=$(echo $answer | tr '[:upper:]' '[:lower:]')

    # figure out positions of letter in the answer
    for (( i = 0; i < ${#answer}; i++ )); do
        if [ "${ans:$i:1}" = "$c" ]; then
            pos+=($i)
        fi
    done

    # keep track of what the user has entered so far
    letters+=($c)

    # check for incorrect attempt
    if [[ "${#pos}" = 0 ]]; then
        let num_attempts-=1
        return
    fi

    # translate positions to question positions and replace blanks with the letter
    local start
    local end
    local p
    for (( i = 0; i < ${#pos[@]}; i++ )); do
        p=${pos[$i]}
        c=${answer:$p:1}
        start=$(( ${pos[$i]} * 2 ))
        end=$(( start + 2 ))

        # better way to do string manipulation?
        question="${question:0:$start}$c ${question:end}"
    done
}

valid_user_input() {
    # convert to lowercase 
    user_input=$(echo $user_input | tr '[:upper:]' '[:lower:]')

    # make sure letter is alpha    
    if [[ "$user_input" =~ [^[:alpha:]] ]]; then
        echo "Please enter a valid letter."
        return $(false)
    fi

    # check if letter has already been entered
    if array_contains "${letters[@]}" "$user_input"; then
        print_letters
        return $(false)
    fi
}


main() {
    print_welcome

    if [[ ! -f "$words_file" ]]; then
        echo -e "\nError: Could not find words file \"$words_file\".\n" >&2
        exit 1
    fi

    generate_question

    while true; do
        print_question

        if [ "$num_attempts" = 0 ]; then
            break
        fi

        if gamewin; then
            exit
        fi

        print_prompt

        read -n 1 -e user_input

        if [ "$user_input" = "$quit_key" ]; then
            break
        fi

        if ! valid_user_input; then
            continue
        fi

        process_user_input

        print_letters
    done

    gameover
}

main

TTT_3X3_states_H1 = zeros(3^4, 4);
%table where H1's valid states are rows in table,
%columns are indices of states to which transition occurs, or no action
sigma_3X3_states_H1 = zeros(3^4, 4); %policy to be taken in each state
R_3X3_states_H1 = zeros(3^4, 4); %regret value for each (state, action) pair as per CFR
u_3X3_states_H1 = zeros(3^4, 4); %utility for each (state, action) pair in CFR
T_LIMIT = 50; %Upper limit on the number of times CFR iterations are run
REWARD = 3^4;

%a 4-bit ternary code where I is (code for TTT board, due-player's symbol)
%for example (BBBX) is the start state if X is to begin the TTT game
fprintf("\nTraining in progress..\nPlease wait...\n");
for i=0:1:3^3 - 1
    i_base_3=dec2base(i, 3); %converting the number i to ternary string of characters 0, 1, 2
    list_of_blanks = zeros(3); %creating an array to store location of blanks in the code
    
    length_i_base_3 = length(i_base_3);
    while length_i_base_3 < 3
        i_base_3 = strcat('0', i_base_3); %padding with 0 in most significant digits
        length_i_base_3 = length_i_base_3 + 1;
    end
    
    i_base_3_todec = i_base_3; %saving these characters for use later
    i_base_3_next_todec = i_base_3;
    
    length_i_base_3_temp = 1;
    available_blanks = 0;
    while length_i_base_3_temp <= 3 %converting 0, 1, 2 to B, X, O symbols resp.
        if (i_base_3(length_i_base_3_temp)=='1')
            i_base_3(length_i_base_3_temp)='X';
        else
            if (i_base_3(length_i_base_3_temp)=='2')
                i_base_3(length_i_base_3_temp)='O';
            else
                i_base_3(length_i_base_3_temp)='B';
                list_of_blanks(available_blanks + 1) = length_i_base_3_temp; %storing in an array the blanks available
                available_blanks = available_blanks + 1; %counting the number of blank cells available
            end
        end
        length_i_base_3_temp = length_i_base_3_temp + 1;
    end
    
    count_of_x=count(i_base_3, 'X'); %counting the number of Xs in code
    count_of_o=count(i_base_3, 'O'); %counting the number of Os in code
    
    if (count_of_x + count_of_o) < 3
        %check if placing X or O symbol is possible in the current state
        %process first the possibility of placing (or not placing) X
        for blank_index = 1:1:available_blanks %over all possible blanks in the subgame
            i_base_3_next = i_base_3;
            i_base_3_next(list_of_blanks(blank_index)) = 'X';
            i_base_3_next_todec(list_of_blanks(blank_index)) = '1';
            %fprintf(1, '\n%d (SUBGAME: %s, DUE PLAYER: %c) -> (SUBGAME: %s, DUE PLAYER: %c) %d', 3*i + 1, i_base_3, 'X', i_base_3_next, 'O', 3*base2dec(i_base_3_next_todec, 3) + 2);
            TTT_3X3_states_H1((3*i + 1) + 1, list_of_blanks(blank_index)) = (3*base2dec(i_base_3_next_todec, 3) + 2);
            %note that index 3*base2dec(i_base_3_next_todec, 3) + 2
            %signifies that the next state of subgame *could* be for O to
            %play: the multiplication by 3 is a left-shift for code
            i_base_3_next_todec = i_base_3_todec;
        end
        %next we deal with the situation where X prefers to pass
        i_base_3_next = i_base_3;
        i_base_3_next_todec = i_base_3_todec;
        %note that if X passes, O might use the next state to benefit
        %fprintf(1, '\n%d (SUBGAME: %s, DUE PLAYER: %c, PASS) -> (SUBGAME: %s, DUE PLAYER: %c) %d', 3*i + 1, i_base_3, 'X', i_base_3_next, 'O', 3*base2dec(i_base_3_next_todec, 3) + 2);
        TTT_3X3_states_H1((3*i + 1) + 1, 4) = (3*base2dec(i_base_3_next_todec, 3) + 2);

        %process next the possibility of placing (or not placing) O
        for blank_index = 1:1:available_blanks %over all possible blanks in the subgame
            i_base_3_next = i_base_3;
            i_base_3_next(list_of_blanks(blank_index)) = 'O';
            i_base_3_next_todec(list_of_blanks(blank_index)) = '2';
            %fprintf(1, '\n%d (SUBGAME: %s, DUE PLAYER: %c) -> (SUBGAME: %s, DUE PLAYER: %c) %d', 3*i + 1, i_base_3, 'O', i_base_3_next, 'X', 3*base2dec(i_base_3_next_todec, 3) + 1);
            TTT_3X3_states_H1((3*i + 2) + 1, list_of_blanks(blank_index)) = (3*base2dec(i_base_3_next_todec, 3) + 1);
            %note that index 3*base2dec(i_base_3_next_todec, 3) + 2
            %signifies that the next state of subgame *could* be for O to
            %play: the multiplication by 3 is a left-shift for code
            i_base_3_next_todec = i_base_3_todec;
        end
        %next we deal with the situation where O prefers to pass
        i_base_3_next = i_base_3;
        i_base_3_next_todec = i_base_3_todec;
        %note that if O passes, X might use the next state to benefit
        %fprintf(1, '\n%d (SUBGAME: %s, DUE PLAYER: %c, PASS) -> (SUBGAME: %s, DUE PLAYER: %c) %d', 3*i + 1, i_base_3, 'O', i_base_3_next, 'X', 3*base2dec(i_base_3_next_todec, 3) + 1);
        TTT_3X3_states_H1((3*i + 2) + 1, 4) = (3*base2dec(i_base_3_next_todec, 3) + 1);
        
    else
        
        reward_check = has_winner_H1(i_base_3);
        if reward_check == 1   %X has already won, so O faces -ve reward
            TTT_3X3_states_H1((3*i + 1) + 1, :) = REWARD; %+ve reward
            TTT_3X3_states_H1((3*i + 2) + 1, :) = -REWARD; %-ve reward
            %this is a terminal state, where sigma*u should be the reward
            u_3X3_states_H1((3*i + 1) + 1, :) = REWARD;
            u_3X3_states_H1((3*i + 2) + 1, :) = -REWARD;
            %sigma for a terminal state is turned to uniform probab.
            sigma_3X3_states_H1((3*i + 1) + 1, :) = 1/4;
            sigma_3X3_states_H1((3*i + 2) + 1, :) = 1/4;
        else
            if reward_check == 2
                %O has already won, so X as due-player faces -ve reward
                TTT_3X3_states_H1((3*i + 1) + 1, :) = -REWARD;
                TTT_3X3_states_H1((3*i + 2) + 1, :) = REWARD;
                %this is a terminal state, where sigma*u should be the reward
                u_3X3_states_H1((3*i + 1) + 1, :) = -REWARD;
                u_3X3_states_H1((3*i + 2) + 1, :) = REWARD;
                %sigma for a terminal state is turned to uniform probab.
                sigma_3X3_states_H1((3*i + 1) + 1, :) = 1/4;
                sigma_3X3_states_H1((3*i + 2) + 1, :) = 1/4;
            end
        end
    end
end

for T=1:1:T_LIMIT %running CFR iterations T_LIMIT number of times
    %this loop is for valid subgame states I where 'X' is due to play
    for I=0:1:3^3 - 1
        %no limits on no. of Xs and Os, so there are no 'nonsense' states
        %however if state already has an 'X' or 'O' victory, we continue
        if or(and(min(TTT_3X3_states_H1((3*I + 2) + 1, :)) == REWARD, max(TTT_3X3_states_H1((3*I + 1) + 1, :)) == -REWARD), ...
                and(min(TTT_3X3_states_H1((3*I + 1) + 1, :)) == REWARD, max(TTT_3X3_states_H1((3*I + 2) + 1, :)) == -REWARD))
            continue;
        end
        
        sum_over_all_a_R_3X3_states = 0.0;
        valid_action_count = 0;
        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 1) + 1, a) > 0
                valid_action_count = valid_action_count + 1;
                sum_over_all_a_R_3X3_states = sum_over_all_a_R_3X3_states + max(R_3X3_states_H1((3*I + 1) + 1, a), 0.0);
            end
        end

        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 1) + 1, a) > 0
                if sum_over_all_a_R_3X3_states == 0.0
                    sigma_3X3_states_H1((3*I + 1) + 1, a) = 1/valid_action_count;
                else
                    sigma_3X3_states_H1((3*I + 1) + 1, a) = max(R_3X3_states_H1((3*I + 1) + 1, a), 0.0)/sum_over_all_a_R_3X3_states;
                end
                remainder = mod(TTT_3X3_states_H1((3*I + 1) + 1, a), 3);
                %note how I_prime is adjusted later s.t. due-player is 'O'
                I_prime = (TTT_3X3_states_H1((3*I + 1) + 1, a) - remainder)/3;
                u_3X3_states_H1((3*I + 1) + 1, a) = 0.0;
                for b = 1:1:4
                    if or(TTT_3X3_states_H1((3*I_prime + 2) + 1, b) > 0, or(min(TTT_3X3_states_H1((3*I_prime + 2) + 1, :)) == REWARD, max(TTT_3X3_states_H1((3*I_prime + 2) + 1, :)) == -REWARD))
                        %the sign is opposite of the existing sign in
                        %I_prime's utility function
                        u_3X3_states_H1((3*I + 1) + 1, a) = u_3X3_states_H1((3*I + 1) + 1, a) - sigma_3X3_states_H1((3*I_prime + 2) + 1, b)*u_3X3_states_H1((3*I_prime + 2) + 1, b);
                    end
                end
            end
        end

        subtraction_term = 0.0;
        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 1) + 1, a) > 0
                subtraction_term = subtraction_term + sigma_3X3_states_H1((3*I + 1) + 1, a)*u_3X3_states_H1((3*I + 1) + 1, a);
            end
        end
        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 1) + 1, a) > 0
                 R_3X3_states_H1((3*I + 1) + 1, a) =  R_3X3_states_H1((3*I + 1) + 1, a) + (u_3X3_states_H1((3*I + 1) + 1, a) - subtraction_term);
            end
        end
    end
    %this loop is for all states of board where 'O' is due to play
    for I=0:1:3^3 - 1

        %similarly if the state already has an 'X' or 'O' victory
        if or(and(min(TTT_3X3_states_H1((3*I + 2) + 1, :)) == REWARD, max(TTT_3X3_states_H1((3*I + 1) + 1, :)) == -REWARD), ...
                and(min(TTT_3X3_states_H1((3*I + 1) + 1, :)) == REWARD, max(TTT_3X3_states_H1((3*I + 2) + 1, :)) == -REWARD))
            continue;
        end
        
        sum_over_all_a_R_3X3_states = 0.0;
        valid_action_count = 0;
        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 2) + 1, a) > 0
                valid_action_count = valid_action_count + 1;
                sum_over_all_a_R_3X3_states = sum_over_all_a_R_3X3_states + max(R_3X3_states_H1((3*I + 2) + 1, a), 0.0);
            end
        end

        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 2) + 1, a) > 0
                if sum_over_all_a_R_3X3_states == 0.0
                    sigma_3X3_states_H1((3*I + 2) + 1, a) = 1/valid_action_count;
                else
                    sigma_3X3_states_H1((3*I + 2) + 1, a) = max(R_3X3_states_H1((3*I + 2) + 1, a), 0.0)/sum_over_all_a_R_3X3_states;
                end
                remainder = mod(TTT_3X3_states_H1((3*I + 2) + 1, a), 3);
                I_prime = (TTT_3X3_states_H1((3*I + 2) + 1, a) - remainder)/3;
                %note how I_prime is used later s.t. due-player is 'X'
                u_3X3_states_H1((3*I + 2) + 1, a) = 0.0;
                for b = 1:1:4
                    if or(TTT_3X3_states_H1((3*I_prime + 1) + 1, b) > 0, or(min(TTT_3X3_states_H1((3*I_prime + 1) + 1, :)) == REWARD, max(TTT_3X3_states_H1((3*I_prime + 1) + 1, :)) == -REWARD))
                        %the sign used for I_prime's utilities is -ve of
                        %I's actions
                        u_3X3_states_H1((3*I + 2) + 1, a) = u_3X3_states_H1((3*I + 2) + 1, a) - sigma_3X3_states_H1((3*I_prime + 1) + 1, b)*u_3X3_states_H1((3*I_prime + 1) + 1, b);
                    end
                end
            end
        end

        subtraction_term = 0.0;
        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 2) + 1, a) > 0
                subtraction_term = subtraction_term + sigma_3X3_states_H1((3*I + 2) + 1, a)*u_3X3_states_H1((3*I + 2) + 1, a);
            end
        end
        for a = 1:1:4
            if TTT_3X3_states_H1((3*I + 2) + 1, a) > 0
                 R_3X3_states_H1((3*I + 2) + 1, a) =  R_3X3_states_H1((3*I + 2) + 1, a) + (u_3X3_states_H1((3*I + 2) + 1, a) - subtraction_term);
            end
        end
    end
end

%------------------------------PLAY-----------------------------------------------
fprintf("\nYou may start playing now...");
play="yes";
while(play ~= "no")
    board_len = 3*3; %change this to 5*5 for 5x5 TTT
    TTT_board = string(1:board_len); % srtring array to store board

    %initializing the TTT_board with numbers 1 to length of board
    for col=1:board_len
        TTT_board(col) = int2str(col);
    end   
    fprintf("\nAvailable moves are given in number:\n");
    fprintf('%s %s %s\n', TTT_board{:}); %change this to '%s %s %s %s %s\n' for 5x5 TTT

    %Loop for the play
    for move=1:board_len/2+1       
        
        user_input=true;
        while(user_input)            
            cell = input("Enter your (symbol X) move:");
            %checking whether the cell is free
            if (TTT_board(cell) == 'X' || TTT_board(cell) == 'O')
                fprintf(2,"\n%d is already taken!\n",cell);                 
                user_input = true;
            else
                user_input = false;
            end    
        end  
        
        %Adding player 1's symbol to TTT_board
        TTT_board(cell) = 'X';        
        fprintf('%s %s %s\n', TTT_board{:});  %change this to '%s %s %s %s %s\n' for 5x5 TTT

        %Translating the TTT_board symbols to 0,1 and 2
        query="";
        for col=1:board_len
            if (TTT_board(col) == 'X')
                query = query+'1';
            elseif(TTT_board(col) == 'O')    
                query = query+'2';
            else
                query = query+'0'; 
            end    
        end           
        
        %Checking whether player 1 is winner
        winner = has_winner(TTT_board); 
        if (winner == 1 )
            fprintf(2,"\n----YOU WON----");
            break;
        end   
        %Checking whether the match is draw
        draw = is_TTT_Board_full(TTT_board,board_len);
         if (draw)
            fprintf(2,"\n----DRAW-----");
            break;
        end  

        %Translating the TTT_board symbols to 0,1 and 2
        query="";
        for col=1:board_len
            if (TTT_board(col) == 'X')
                query = query+'1';
            elseif(TTT_board(col) == 'O')    
                query = query+'2';
            else
                query = query+'0'; 
            end    
        end           

        %Querying sigma_3X3_states for the maximum value for player 2
        strategy= TTT_3X3_DivideAndConquer(R_3X3_states_H1,query,"2");
        [M,I] = max(strategy,[],'all');
        %fprintf("Query= %s Max= %d Index=%d",query, M,I);
        %Adding Player 2's symbol to TTT_board
        TTT_board(I) = 'O';
        fprintf("Computer's(symbol O) move:%d\n",I);
        fprintf("%s %s %s\n", TTT_board{:});  %change this to '%s %s %s %s %s\n' for 5x5 TTT
        %checking whether Player 2 is winner
        winner = has_winner(TTT_board); 
        if (winner == 2 )
            fprintf(2,"\n----YOU LOST----");
            break;
        end   
    end
play = input("\nPress any key to play again or type 'no' to exit the game:",'s');
end

function [is_winner] = has_winner_H1(TTT_game)

    place1 = TTT_game(1);
    place2 = TTT_game(2);
    place3 = TTT_game(3);
    if and(place1 == 'O', and(place2 == 'O', place3 == 'O'))
        is_winner = 2;
        return;
    else
        if and(place1 == 'X', and(place2 == 'X', place3 == 'X'))
            is_winner = 1;
            return;
        else
            is_winner = 0;
            return;
        end
    end
    
end

function [is_winner] = has_winner(TTT_game)

    for j=0:1:2 %checking if rows have same symbol  
        place1 = TTT_game(j*3 + 1);
        place2 = TTT_game(j*3 + 2);
        place3 = TTT_game(j*3 + 3);
        if and(place1 == 'O', and(place2 == 'O', place3 == 'O'))
            is_winner = 2;
            return;
        else
            if and(place1 == 'X', and(place2 == 'X', place3 == 'X'))
                is_winner = 1;
                return;
            end
        end
    end
    
    for j=0:1:2
        place1 = TTT_game(j + 1);
        place2 = TTT_game(j + 4);
        place3 = TTT_game(j + 7);
        if and(place1 == 'O', and(place2 == 'O', place3 == 'O'))
            is_winner = 2;
            return;
        else
            if and(place1 == 'X', and(place2 == 'X', place3 == 'X'))
                is_winner = 1;
                return;
            end
        end
    end
    
    place1 = TTT_game(1);
    place2 = TTT_game(5);
    place3 = TTT_game(9);
    if and(place1 == 'O', and(place2 == 'O', place3 == 'O'))
        is_winner = 2;
        return;
    else
        if and(place1 == 'X', and(place2 == 'X', place3 == 'X'))
            is_winner = 1;
            return;
        end
    end
    
    place1 = TTT_game(3);
    place2 = TTT_game(5);
    place3 = TTT_game(7);
    if and(place1 == 'O', and(place2 == 'O', place3 == 'O'))
        is_winner = 2;
        return;
    else
        if and(place1 == 'X', and(place2 == 'X', place3 == 'X'))
            is_winner = 1;
            return;
        end
    end
    
    is_winner = 0;
    return;
end    %end of function has_winner


function sigma_DC = TTT_3X3_DivideAndConquer(R_3X3_states_H1, TTT_string, TTT_move)
    sigma_DC = zeros(1, 9);
    regret_matrix = zeros(1, 9);
    H1='';
    H1=strcat(H1, extract(TTT_string,1));
    H1=strcat(H1, extract(TTT_string,2));
    H1=strcat(H1, extract(TTT_string,3));
    R_H1 = R_3X3_states_H1(base2dec(strcat(H1, TTT_move), 3) + 1, :);
    regret_matrix(1, 1) = R_H1(1, 1);
    regret_matrix(1, 2) = R_H1(1, 2);
    regret_matrix(1, 3) = R_H1(1, 3);
    H2='';
    H2=strcat(H2, extract(TTT_string,4));
    H2=strcat(H2, extract(TTT_string,5));
    H2=strcat(H2, extract(TTT_string,6));
    R_H2 = R_3X3_states_H1(base2dec(strcat(H2, TTT_move), 3) + 1, :);
    regret_matrix(1, 4) = R_H2(1, 1);
    regret_matrix(1, 5) = R_H2(1, 2);
    regret_matrix(1, 6) = R_H2(1, 3);
    H3='';
    H3=strcat(H3, extract(TTT_string,7));
    H3=strcat(H3, extract(TTT_string,8));
    H3=strcat(H3, extract(TTT_string,9));
    R_H3 = R_3X3_states_H1(base2dec(strcat(H3, TTT_move), 3) + 1, :);
    regret_matrix(1, 7) = R_H3(1, 1);
    regret_matrix(1, 8) = R_H3(1, 2);
    regret_matrix(1, 9) = R_H3(1, 3);
    V1='';
    V1=strcat(V1, extract(TTT_string,1));
    V1=strcat(V1, extract(TTT_string,4));
    V1=strcat(V1, extract(TTT_string,7));
    R_V1 = R_3X3_states_H1(base2dec(strcat(V1, TTT_move), 3) + 1, :);
    regret_matrix(1, 1) = regret_matrix(1, 1) + R_V1(1, 1);
    regret_matrix(1, 4) = regret_matrix(1, 4) + R_V1(1, 2);
    regret_matrix(1, 7) = regret_matrix(1, 7) + R_V1(1, 3);
    V2='';
    V2=strcat(V2, extract(TTT_string,2));
    V2=strcat(V2, extract(TTT_string,5));
    V2=strcat(V2, extract(TTT_string,8));
    R_V2 = R_3X3_states_H1(base2dec(strcat(V2, TTT_move), 3) + 1, :);
    regret_matrix(1, 2) = regret_matrix(1, 2) + R_V2(1, 1);
    regret_matrix(1, 5) = regret_matrix(1, 5) + R_V2(1, 2);
    regret_matrix(1, 8) = regret_matrix(1, 8) + R_V2(1, 3);
    V3='';
    V3=strcat(V3, extract(TTT_string,3));
    V3=strcat(V3, extract(TTT_string,6));
    V3=strcat(V3, extract(TTT_string,9));
    R_V3 = R_3X3_states_H1(base2dec(strcat(V3, TTT_move), 3) + 1, :);
    regret_matrix(1, 3) = regret_matrix(1, 3) + R_V3(1, 1);
    regret_matrix(1, 6) = regret_matrix(1, 6) + R_V3(1, 2);
    regret_matrix(1, 9) = regret_matrix(1, 9) + R_V3(1, 3);
    D1='';
    D1=strcat(D1, extract(TTT_string,1));
    D1=strcat(D1, extract(TTT_string,5));
    D1=strcat(D1, extract(TTT_string,9));
    R_D1 = R_3X3_states_H1(base2dec(strcat(D1, TTT_move), 3) + 1, :);
    regret_matrix(1, 1) = regret_matrix(1, 1) + R_D1(1, 1);
    regret_matrix(1, 5) = regret_matrix(1, 5) + R_D1(1, 2);
    regret_matrix(1, 9) = regret_matrix(1, 9) + R_D1(1, 3);
    D2='';
    D2=strcat(D2, extract(TTT_string,3));
    D2=strcat(D2, extract(TTT_string,5));
    D2=strcat(D2, extract(TTT_string,7));
    R_D2 = R_3X3_states_H1(base2dec(strcat(D2, TTT_move), 3) + 1, :);
    regret_matrix(1, 3) = regret_matrix(1, 3) + R_D2(1, 1);
    regret_matrix(1, 5) = regret_matrix(1, 5) + R_D2(1, 2);
    regret_matrix(1, 7) = regret_matrix(1, 7) + R_D2(1, 3);
    
    sum_of_regret_matrix_entries = 0.0;
    no_of_regret_matrix_entries = 0;
    for i=1:1:9
        sum_of_regret_matrix_entries = sum_of_regret_matrix_entries + regret_matrix(1, i);
        if regret_matrix(1, i) > 0
            no_of_regret_matrix_entries = no_of_regret_matrix_entries + 1;
        end
    end
    for i=1:1:9
        if sum_of_regret_matrix_entries > 0
            if regret_matrix(1, i) == max(regret_matrix(1, :))
                sigma_DC(1, i) = 1.0;
                break;
            else
                sigma_DC(1, i) = 0.0;
            end
        else
            sigma_DC(1, i) = 1/no_of_regret_matrix_entries;
        end
    end
end

function [is_full] = is_TTT_Board_full(TTT_board,board_len)
    for col=1:board_len
         if (TTT_board(col) ~= 'X' && TTT_board(col) ~= 'O')                               
            is_full = 0;
            return;
         end   
    end   
is_full = 1;   
return;   
end 
TTT_3X3_states = zeros(3^10, 9);
%table where rows as valid states of board, columns are indices of other states to which transition occurs
sigma_3X3_states = zeros(3^10, 9); %policy to be taken in each state
R_3X3_states = zeros(3^10, 9); %regret value for each (state, action) pair as per CFR
u_3X3_states = zeros(3^10, 9); %utility for each (state, action) pair in CFR
T_LIMIT = 50; %Upper limit on the number of times CFR iterations are run
REWARD = 3^10;

%a 10-bit ternary code where I is (code for TTT board, due-player's symbol)
%for example (BBBBBBBBBX) is the start state if X is to begin the TTT game

%BXB
%XOO
%XOX
fprintf("\nTraining in progress..\nPlease wait...\n");
for i=0:1:3^9 - 1
    i_base_3=dec2base(i, 3); %converting the number i to ternary string of characters 0, 1, 2
    list_of_blanks = zeros(9); %creating an array to store location of blanks in the code
    
    length_i_base_3 = length(i_base_3);
    while length_i_base_3 < 9
        i_base_3 = strcat('0', i_base_3); %padding with 0 in most significant digits
        length_i_base_3 = length_i_base_3 + 1;
    end
    
    i_base_3_todec = i_base_3; %saving these characters for use later
    i_base_3_next_todec = i_base_3;
    
    length_i_base_3_temp = 1;
    available_blanks = 0;
    while length_i_base_3_temp <= 9 %converting 0, 1, 2 to B, X, O symbols resp.
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
    
    if and(and(and(or(count_of_x == count_of_o, or(count_of_x == count_of_o - 1, count_of_x == count_of_o + 1)), count_of_x <= 5), count_of_o <= 5), count_of_x + count_of_o <= 9)
        %checks to find if the status of board is a valid one, even if
        %terminal state

        invalid_check = has_winner(i_base_3); %check if the 'valid' state is already an end-state where X or O has won
        if invalid_check == 0 %only if any action is possible in the state do we need to proceed to analyse
            %it is X's chance to play if count of X is in deficit, or if
            %counts of X and O are equal
            if or(count_of_x == count_of_o, count_of_x == count_of_o - 1)
                for blank_index = 1:1:available_blanks %over all possible blanks on the board
                    i_base_3_next = i_base_3;
                    i_base_3_next(list_of_blanks(blank_index)) = 'X';
                    i_base_3_next_todec(list_of_blanks(blank_index)) = '1';
                    %fprintf(1, '\n%d (BOARD: %s, DUE PLAYER: %c) -> (BOARD: %s, DUE PLAYER: %c) %d', 3*i + 1, i_base_3, 'X', i_base_3_next, 'O', 3*base2dec(i_base_3_next_todec, 3) + 2);
                    %the base2dec quantities print for us the I and I' states
                    %storing next state I' like a linked list pointer
                    TTT_3X3_states((3*i + 1) + 1, list_of_blanks(blank_index)) = (3*base2dec(i_base_3_next_todec, 3) + 2);
                    %note that index 3*base2dec(i_base_3_next_todec, 3) + 2
                    %signifies that the next state of board is for O to
                    %play: the multiplication by 3 is a left-shift for code
                    i_base_3_next_todec = i_base_3_todec;
                end
            end
            %similarly it is O's chance to play if symmetric checks can pass
            if or(count_of_o == count_of_x, count_of_o == count_of_x - 1)
                for blank_index = 1:1:available_blanks
                    i_base_3_next = i_base_3;
                    i_base_3_next(list_of_blanks(blank_index)) = 'O';
                    i_base_3_next_todec(list_of_blanks(blank_index)) = '2';
                    %fprintf(1, '\n%d (BOARD: %s, DUE PLAYER: %c) -> (BOARD: %s, DUE PLAYER: %c) %d', 3*i + 2, i_base_3, 'O', i_base_3_next, 'X', 3*base2dec(i_base_3_next_todec, 3) + 1);
                    TTT_3X3_states((3*i + 2) + 1, list_of_blanks(blank_index)) = (3*base2dec(i_base_3_next_todec, 3) + 1);
                    %notice how if I is for O to play, then I' is for X to
                    %play (or surrender, if I' happens to be an 'O' win)
                    i_base_3_next_todec = i_base_3_todec;
                end
            end
        else
            reward = 1; %reward is marked as '1' due to Salloum's code
            if invalid_check == 1   %X has already won, so O faces -ve reward
                TTT_3X3_states((3*i + 1) + 1, :) = REWARD; %+ve reward
                TTT_3X3_states((3*i + 2) + 1, :) = -REWARD; %-ve reward
                %this is a terminal state, where sigma*u should be the reward
                u_3X3_states((3*i + 1) + 1, :) = REWARD;
                u_3X3_states((3*i + 2) + 1, :) = -REWARD;
                %sigma for a terminal state is turned to uniform probab.
                sigma_3X3_states((3*i + 1) + 1, :) = 1/9;
                sigma_3X3_states((3*i + 2) + 1, :) = 1/9;
            else %O has already won, so X as due-player faces -ve reward
                TTT_3X3_states((3*i + 1) + 1, :) = -REWARD;
                TTT_3X3_states((3*i + 2) + 1, :) = REWARD;
                %this is a terminal state, where sigma*u should be the reward
                u_3X3_states((3*i + 1) + 1, :) = -REWARD;
                u_3X3_states((3*i + 2) + 1, :) = REWARD;
                %sigma for a terminal state is turned to uniform probab.
                sigma_3X3_states((3*i + 1) + 1, :) = 1/9;
                sigma_3X3_states((3*i + 2) + 1, :) = 1/9;
            end
        end
    end
        
end

for T=1:1:T_LIMIT %running CFR iterations T_LIMIT number of times
    %this loop is for valid, current board states I when 'X' is due to play
    for I=0:1:3^9 - 1
        %if I is a nonsense state of the game (irrespective of the player)
        %then we need not calculate anything for it - this is indicated by indices being 0
        if and(max(TTT_3X3_states((3*I + 2) + 1, :)) == 0, max(TTT_3X3_states((3*I + 1) + 1, :)) == 0)
            continue;
        else
            %similarly if the state already has an 'X' or 'O' victory
            if or(and(min(TTT_3X3_states((3*I + 2) + 1, :)) == REWARD, max(TTT_3X3_states((3*I + 1) + 1, :)) == -REWARD), ...
                    and(min(TTT_3X3_states((3*I + 1) + 1, :)) == REWARD, max(TTT_3X3_states((3*I + 2) + 1, :)) == -REWARD))
                continue;
            else
                invalid_check = 0;
            end
        end
        
        if invalid_check == 0
            sum_over_all_a_R_3X3_states = 0.0;
            valid_action_count = 0;
            for a = 1:1:9
                if TTT_3X3_states((3*I + 1) + 1, a) > 0
                    valid_action_count = valid_action_count + 1;
                    sum_over_all_a_R_3X3_states = sum_over_all_a_R_3X3_states + max(R_3X3_states((3*I + 1) + 1, a), 0.0);
                end
            end
            
            for a = 1:1:9
                if TTT_3X3_states((3*I + 1) + 1, a) > 0
                    if sum_over_all_a_R_3X3_states == 0.0
                        sigma_3X3_states((3*I + 1) + 1, a) = 1/valid_action_count;
                    else
                        sigma_3X3_states((3*I + 1) + 1, a) = max(R_3X3_states((3*I + 1) + 1, a), 0.0)/sum_over_all_a_R_3X3_states;
                    end
                    remainder = mod(TTT_3X3_states((3*I + 1) + 1, a), 3);
                    %note how I_prime is adjusted later s.t. due-player is 'O'
                    I_prime = (TTT_3X3_states((3*I + 1) + 1, a) - remainder)/3;
                    u_3X3_states((3*I + 1) + 1, a) = 0.0;
                    for b = 1:1:9
                        if or(TTT_3X3_states((3*I_prime + 2) + 1, b) > 0, or(min(TTT_3X3_states((3*I_prime + 2) + 1, :)) == REWARD, max(TTT_3X3_states((3*I_prime + 2) + 1, :)) == -REWARD))
                            %the sign is opposite of the existing sign in
                            %I_prime's utility function
                            u_3X3_states((3*I + 1) + 1, a) = u_3X3_states((3*I + 1) + 1, a) - sigma_3X3_states((3*I_prime + 2) + 1, b)*u_3X3_states((3*I_prime + 2) + 1, b);
                        end
                    end
                end
            end

            subtraction_term = 0.0;
            for a = 1:1:9
                if TTT_3X3_states((3*I + 1) + 1, a) > 0
                    subtraction_term = subtraction_term + sigma_3X3_states((3*I + 1) + 1, a)*u_3X3_states((3*I + 1) + 1, a);
                end
            end
            for a = 1:1:9
                if TTT_3X3_states((3*I + 1) + 1, a) > 0
                     R_3X3_states((3*I + 1) + 1, a) =  R_3X3_states((3*I + 1) + 1, a) + (u_3X3_states((3*I + 1) + 1, a) - subtraction_term);
                end
            end
        end
    end
    %this loop is for all states of board where 'O' is due to play
    for I=0:1:3^9 - 1
        %if I is a nonsense state of the game (irrespective of the player)
        %then we need not analyse it - this is indicated by indices being 0
        if and(max(TTT_3X3_states((3*I + 2) + 1, :)) == 0, max(TTT_3X3_states((3*I + 1) + 1, :)) == 0)
            continue;
        else
            %similarly if the state already has an 'X' or 'O' victory
            if or(and(min(TTT_3X3_states((3*I + 2) + 1, :)) == REWARD, max(TTT_3X3_states((3*I + 1) + 1, :)) == -REWARD), ...
                    and(min(TTT_3X3_states((3*I + 1) + 1, :)) == REWARD, max(TTT_3X3_states((3*I + 2) + 1, :)) == -REWARD))
                continue;
            else
                invalid_check = 0;
            end
        end
        if invalid_check == 0
            sum_over_all_a_R_3X3_states = 0.0;
            valid_action_count = 0;
            for a = 1:1:9
                if TTT_3X3_states((3*I + 2) + 1, a) > 0
                    valid_action_count = valid_action_count + 1;
                    sum_over_all_a_R_3X3_states = sum_over_all_a_R_3X3_states + max(R_3X3_states((3*I + 2) + 1, a), 0.0);
                end
            end

            for a = 1:1:9
                if TTT_3X3_states((3*I + 2) + 1, a) > 0
                    if sum_over_all_a_R_3X3_states == 0.0
                        sigma_3X3_states((3*I + 2) + 1, a) = 1/valid_action_count;
                    else
                        sigma_3X3_states((3*I + 2) + 1, a) = max(R_3X3_states((3*I + 2) + 1, a), 0.0)/sum_over_all_a_R_3X3_states;
                    end
                    remainder = mod(TTT_3X3_states((3*I + 2) + 1, a), 3);
                    I_prime = (TTT_3X3_states((3*I + 2) + 1, a) - remainder)/3;
                    %note how I_prime is used later s.t. due-player is 'X'
                    u_3X3_states((3*I + 2) + 1, a) = 0.0;
                    for b = 1:1:9
                        if or(TTT_3X3_states((3*I_prime + 1) + 1, b) > 0, or(min(TTT_3X3_states((3*I_prime + 1) + 1, :)) == REWARD, max(TTT_3X3_states((3*I_prime + 1) + 1, :)) == -REWARD))
                            %the sign used for I_prime's utilities is -ve of
                            %I's actions
                            u_3X3_states((3*I + 2) + 1, a) = u_3X3_states((3*I + 2) + 1, a) - sigma_3X3_states((3*I_prime + 1) + 1, b)*u_3X3_states((3*I_prime + 1) + 1, b);
                        end
                    end
                end
            end

            subtraction_term = 0.0;
            for a = 1:1:9
                if TTT_3X3_states((3*I + 2) + 1, a) > 0
                    subtraction_term = subtraction_term + sigma_3X3_states((3*I + 2) + 1, a)*u_3X3_states((3*I + 2) + 1, a);
                end
            end
            for a = 1:1:9
                if TTT_3X3_states((3*I + 2) + 1, a) > 0
                     R_3X3_states((3*I + 2) + 1, a) =  R_3X3_states((3*I + 2) + 1, a) + (u_3X3_states((3*I + 2) + 1, a) - subtraction_term);
                end
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
    fprintf('%s %s %s\n', TTT_board{:});

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

        query = query + '2';
        %Querying sigma_3X3_states for the maximum value for player 2
        strategy= sigma_3X3_states(base2dec(query, 3) + 1, :);
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

%------------------- FUNCTIONS ----------------------------------------
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


function [is_full] = is_TTT_Board_full(TTT_board,board_len)
    for col=1:board_len
         if (TTT_board(col) ~= 'X' && TTT_board(col) ~= 'O')                               
            is_full = 0;
            return;
         end   
    end   
is_full = 1;   
return;   
end %end of function is_TTT_Board_full
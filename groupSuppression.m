function [ time_array, large_group, n_p_array ] = groupSuppression...
    ( lambda, mu_s, mu, t_horizon, init_peers,n_pieces)


%This code corresponds to The Group Suppression Protocol in the paper.


%n_p_array stores the number of peers in the network.

%large_group keeps track of the largest club's population.

%time_array stores the time instances at which a peer arrives or a
%peer leaves or a peer simply makes a contact.

%lambda denotes the arrival rate.

%mu_s is the seed's contact(upload) rate.

%mu is an incomplete peer's contact(upload) rate.

%init_peers is the number of the peers at t=0.

%time_horizon is the time instnce at which the simulation ends.

%n_pieces represents the number of the pieces the file is divided into.

n_peers=init_peers;
agg_peers=init_peers;
n_p_array=[init_peers];
time_array=[0];
time_passed=0;
old_weight=-2;
new_weight=-2;
large_group=[init_peers-1];


peers=zeros(lambda*t_horizon+init_peers, 4+n_pieces+1);
for i=1:init_peers
    peers(i,1)=i;
end

%initialize the seed
peers(1,2)= -log(rand(1,1))/ mu_s;
peers(1,3)=0;
peers(1,4)=n_pieces;
peers(1,5:4+n_pieces)=1;

%initialize the peers
for i=2:init_peers
    peers(i,2)=-log(rand(1,1))/ mu;
    peers(i,3)=0;
    peers(i,4)=n_pieces-1;
    peers(i,5:4+n_pieces-1)=1;
end

for i=1:init_peers
    sum=0;
    for j=1:n_pieces
        sum=sum+ peers(i,4+j)*2^(j-1);
    end
    peers(i,end)=sum;
end

%initialize the arrival process's poisson clock
clock_arrival= -log(rand(1,1))/lambda;

all_weights=zeros(1,n_peers);
for i=1:n_peers
    all_weights(i)=peers(i,end);
end

uniq_weights=unique(all_weights);
corr_freqs=histc(all_weights,uniq_weights);

while time_passed<t_horizon
    activity_flag=0;
    departure_flag=0;
    departure_row=0;
    fire_array=[clock_arrival peers(1:n_peers,2)'];
    [fire_time, fire_index]=min(fire_array);
    time_passed=time_passed+fire_time;
    time_array(end+1)=time_passed;
    peers(1:n_peers,2)=peers(1:n_peers,2)-fire_time;
    clock_arrival=clock_arrival-fire_time;
    
    %this means an arrival must happen now
    if fire_index==1
        activity_flag=1;
        clock_arrival=-log(rand(1,1))/lambda;
        n_peers=n_peers+1;
        agg_peers=agg_peers+1;
        peers(n_peers,1)=agg_peers;
        peers(n_peers,2)= -log(rand(1,1))/mu;
        peers(n_peers,3)=time_passed;
        old_weight=-1;
        new_weight=0;
    %this means seed's poisson clock just fired  
    elseif fire_index==2
        peers(1,2)=-log(rand(1,1))/mu_s;
        if n_peers>1
            active_peers=peers(1:n_peers,:);
            active_peers_shuffled=active_peers(randperm(n_peers),:);
            %sort them according to number of pieces they have in ascending
            %order
            active_matrix_sorted=sortrows(active_peers_shuffled,4);
            peer_id=active_matrix_sorted(1,1);
            if peer_id~=1
                activity_flag=1;
                row_id=find(peers(1:n_peers,1)==peer_id);
                u_poss=find(peers(row_id, 5:4+n_pieces)==0);
                u_poss=u_poss(randperm(length(u_poss)));
                u_piece=u_poss(1);
                peers(row_id,4)=peers(row_id,4)+1;
                peers(row_id,4+u_piece)=1;
                old_weight=peers(row_id,end);
                peers(row_id,end)=peers(row_id,end)+2^(u_piece-1);
                new_weight=peers(row_id,end);
                if peers(row_id,4)==n_pieces
                    departure_flag=1;
                    departure_row=row_id;
                end
            end 
        end
        
    else
        fire_index=fire_index-1;
        if peers(fire_index,4)==0
            peers(fire_index,2)=-log(rand(1,1))/mu;
        else
            peers(fire_index,2)=-log(rand(1,1))/mu;
            %find the position of firing peer in unique weight array
            firing_peer_w_pos=find(uniq_weights(1,:)==peers(fire_index,end));
            if max(corr_freqs)~=corr_freqs(firing_peer_w_pos(1))
                largest=0;
            else
                set_of_max_freqs=find(corr_freqs(1,:)==max(corr_freqs));
                if numel(set_of_max_freqs)>1
                    largest=0;
                else
                    largest=1;
                end 
            end
            
            random_peer_row=randi([1,n_peers],1);
            needed_pieces=1-peers(random_peer_row,5:4+n_pieces);
            useful_pieces=peers(fire_index,5:4+n_pieces).*needed_pieces;
            usefulness=cumsum(useful_pieces);
           
            if usefulness(n_pieces)~=0
                if largest==1
                    if peers(random_peer_row,4) > peers(fire_index,4)
                        activity_flag=1;
                        possible_pieces=find(useful_pieces==1);
                        possible_pieces_shuffled=...
                            possible_pieces(randperm(length(possible_pieces)));
                        u_piece=possible_pieces_shuffled(1);
                        peers(random_peer_row,4)=peers(random_peer_row,4)+1;
                        peers(random_peer_row,4+u_piece)=1;
                        old_weight=peers(random_peer_row,end);
                        peers(random_peer_row,end)=peers(random_peer_row,end)...
                            +2^(u_piece-1);
                        new_weight=peers(random_peer_row,end);
                        if peers(random_peer_row,4)==n_pieces
                            departure_flag=1;
                            departure_row=random_peer_row;
                        end
                    end
                      
                else
                    activity_flag=1;
                    possible_pieces=find(useful_pieces==1);
                    possible_pieces_shuffled=...
                        possible_pieces(randperm(length(possible_pieces)));
                    u_piece=possible_pieces_shuffled(1);
                    peers(random_peer_row,4)=peers(random_peer_row,4)+1;
                    peers(random_peer_row,4+u_piece)=1;
                    old_weight=peers(random_peer_row,end);
                    peers(random_peer_row,end)=peers(random_peer_row,end)...
                        +2^(u_piece-1);
                   
                    new_weight=peers(random_peer_row,end);
                   if peers(random_peer_row,4)==n_pieces
                        departure_flag=1;
                        departure_row=random_peer_row;
                   end
                    
                end
            end
            
        end
         
    end
    
    if activity_flag
        if departure_flag
            old_pos=find(uniq_weights(1,:)==old_weight);
            corr_freqs(old_pos)=corr_freqs(old_pos)-1;
        else 
            if ~ismember(new_weight,uniq_weights)
                uniq_weights(end+1)=new_weight;
                corr_freqs(end+1)=1;
            else
                new_pos=find(uniq_weights(1,:)==new_weight);
                corr_freqs(new_pos)=corr_freqs(new_pos)+1;
            end
            if old_weight >= 0
                old_pos=find(uniq_weights(1,:)==old_weight);
                corr_freqs(old_pos)=corr_freqs(old_pos)-1;   
            end
        end
    end
    
    if departure_flag==1
        peers(departure_row,:)=peers(n_peers,:);
        peers(n_peers,:)=0;
        n_peers=n_peers-1;
    end
    n_p_array(end+1)=n_peers;
    large_group(end+1)=max(corr_freqs);
end
      
end




function [ time_array, large_group, n_p_array] = ...
    decentralizedGroupSuppression( lambda, mu_s, mu, t_horizon, ...
    init_peers,n_pieces)

%This code corresponds to The Decentralized Group Suppression Protocol in
%the paper.


%n_p_array stores the number of peers in the network.

%large_group keeps track of the largest club's population.

%time_array stores the time instances at which a peer arrives or a
%peer leaves or a peer simply makes a contact.


%lambda denotes the arrival rate.

%mu_s is the seed's contact(upload) rate.

%mu is an incomplete peer's contact(upload) rate.

%init_peers is the number of the peers at t=0.

%t_horizon is the time instance at which the simulation ends.

%n_pieces represents the number of the pieces the file is divided into.


n_peers=init_peers;
%number of the most recent contacts that an individual peers considers in
%making largest club decision
sample_size=3;
agg_peers=init_peers;
n_p_array=[init_peers];
time_array=[0];
time_passed=0;
old_weight=-2;
new_weight=-2;
large_group=[init_peers-1];
sjrn_count=0;
sjrn_uploads=zeros(1,500);
sjrn_times=zeros(1,500);
%ids of the most recent 5 arrivals
recent_arrvl=[0 0 0 0 0];
%number of population in recent arrivals, starts at 0
recent_pop=0;
sample_in=4+n_pieces+1;
cont_in=sample_in+sample_size;

%a row defines a peer in the following order of its columns:

%id, 
%time left to make a contact, 
%the time the peer has joined the network, 
%number of pieces the peer holds, 
%piece profile of the peer in binary(n_piece columns)
%most recent piece profiles in binary converted into decimal(3 columns)
%number of contacts so far
%number of pieces this peer has uploaded so far
%this peer's own piece profile viewed in binary value then described in decimal

peers=zeros(lambda*t_horizon+init_peers, 4+n_pieces+sample_size+1+1+1);
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

%compute their piece profiles' value in decimal when they are viewed in
%binary
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

while time_passed < t_horizon 
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
        if recent_pop==5
            recent_arrvl(2:5)=recent_arrvl(1:4);
            recent_arrvl(1)=agg_peers;
            
        else
            recent_arrvl(2:1+recent_pop)=recent_arrvl(1:recent_pop);
            recent_arrvl(1)=agg_peers;
            recent_pop=recent_pop+1;
            
        end
    %this means seed's poisson clock just fired  
    elseif fire_index==2
        peers(1,2)=-log(rand(1,1))/mu_s;
        if n_peers>1
            if recent_pop==0
                active_peers=peers(1:n_peers,:);
                active_peers_shuffled=active_peers(randperm(n_peers),:);
                peer_id=active_peers_shuffled(1,1);
            else
               peer_id=recent_arrvl(1); 
            end
            if peer_id~=1
                activity_flag=1;
                %account for the upload
                peers(1,end-1)=peers(1,end-1)+1;
                
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
        rand_row=randi([1,n_peers],1);
        num_cnt=peers(fire_index,cont_in);
        if num_cnt==sample_size
            peers(fire_index,sample_in+1:sample_in+sample_size-1 ...
                )=peers(fire_index,sample_in:sample_in+sample_size-2);
            peers(fire_index,sample_in)=peers(rand_row,end);
        else
            peers(fire_index,sample_in:sample_in+num_cnt-1)=...
                peers(fire_index,sample_in+1:sample_in+num_cnt);
            peers(fire_index,sample_in)=peers(rand_row,end);
            peers(fire_index,cont_in)=peers(fire_index,cont_in)+1;
        end
            
        if peers(fire_index,4)==0
            peers(fire_index,2)=-log(rand(1,1))/mu;
           
        else
            peers(fire_index,2)=-log(rand(1,1))/mu;
            random_peer_row=rand_row;
            needed_pieces=1-peers(random_peer_row,5:4+n_pieces);
            useful_pieces=peers(fire_index,5:4+n_pieces).*needed_pieces;
            usefulness=cumsum(useful_pieces);
            
            sample_network=[peers(fire_index,end) peers(fire_index, sample_in:sample_in+num_cnt-1)];
            uniq_vals=unique(sample_network);
            sample_freqs=histc(sample_network,uniq_vals);
            firing_peer_val_pos=find(uniq_vals(1,:)==peers(fire_index,end));
            if max(sample_freqs)~=sample_freqs(firing_peer_val_pos(1))
                largest=0;
            else
                set_of_max_freqs=find(sample_freqs(1,:)==max(sample_freqs));
                if numel(set_of_max_freqs)>1
                    largest=0;
                else
                    largest=1;
                end 
            end
           
            if usefulness(n_pieces)~=0
                if largest==1
                    if peers(random_peer_row,4) > peers(fire_index,4)
                        activity_flag=1;
                        
                        %account for the upload
                        peers(fire_index,end-1)=peers(fire_index,end-1)+1;
                        
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
                    
                    %account for the upload
                    peers(fire_index,end-1)=peers(fire_index,end-1)+1;
                    
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
        if ismember(peers(departure_row,1),recent_arrvl)
            recent_pos=find(recent_arrvl(1,:)==peers(departure_row,1));
            recent_arrvl(recent_pos:recent_pop-1)=recent_arrvl(recent_pos+1:recent_pop);
            recent_arrvl(recent_pop:5)=0;
            recent_pop=recent_pop-1;
            
        end
        peers(departure_row,:)=peers(n_peers,:);
        peers(n_peers,:)=0;
        n_peers=n_peers-1;
        
    end
    n_p_array(end+1)=n_peers;
    large_group(end+1)=max(corr_freqs);
end
      
end




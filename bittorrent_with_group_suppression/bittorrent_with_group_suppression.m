function [ t_array,  largest_n_p_array,  active_n_p_array ] = ...
    bittorrent_with_group_suppression( good_peers,p_size,file_size, arrvl,t_horizon )

%This source code implements the BitTorrent-like protocol with group
%suppression defined in our paper.

%Initialization

%number of peers at t=0
initial_n_peers=p_size;

%the number of peers that has ever connected to the torrent so far
%use this number to assign peer ids to new incoming peers  
agg_n_peers=p_size;

%this variable keeps track of how many peers there are in the network
%at t=0, network has p_size peers in it
active_n_p=p_size;


%number of arrivals per 10-second interval
arrival_rate=arrvl;

%maximum number of connections a peer can have
n_max_connections=80;

%number of pieces the file is divided into
n_pieces=file_size;

%number of connections that are assigned to a peer upon arrival
n_assigned_connections=40;
t=0;

%if the number of connections of a peer falls below this number, it will
%ask tracker to assign new connections
treshold=20;


%the index where we list a particular peer's requested pieces in binary.
%If a piece is requested in a 10-second interval, it is denoted as 1.
%Otherwise it is denoted as 0.
req_in=14+n_pieces*2+n_max_connections*4;

%rarity index is the index we start filling how many of a particular peer's
%connections have piece 1, piece 2... piece k.
rarity_in=14+n_pieces+n_max_connections*4;

t_array=zeros(1,t_horizon);
active_n_p_array=zeros(1,t_horizon);
largest_n_p_array=zeros(1,t_horizon);

%This matrix holds every key information about the system. Every row of 
%the first active_n_p rows correspond to a particular peer. It is
%intentionally chosen as very big because deleting or adding a row a large
%matrix is an expensive operation in matlab. Pre-allocating radically sped
%up the running time of the code. 

%First column holds id number of the peer.

%Second column is the number of pieces the peer has. 

%Thirds column is the number of connections that the peer has.

%Fourth column is the number of pieces uploaded to the network in 10-second
%round

%Fifth column marks the time at which the rate interval begins

%Sixth column is the upload rate into the network

%7-10th hold peer id's of the peers that this peer uploads this 10s round

%10-14 hold the corresponding pieces being uploaded to the peers

%Next n_piece columns represent this peer's piece profile in binary

%Next 80 columns hold this peer's connections' ids. If it has less than
%that we simply assign 0 to the rest of columns.

%Next 80 columns hold the time at which the connections last uploaded to
%this peer.

%Next 80 columns hold the connections' upload rate.

%Next 80 columns hold the beginning time of the interval for which the 
%upload rate of peers into this peer is calculated. For details of 
%formula of upload rate and decision over upload rate interval, see
%update_uploads10_3 function and rate calculation in that function.

%The seed's 80-column wide blocks serve somewhat different purposes
%For seed, the first 80 columns also hold the seed's connections' ids
%For seed, the second 80 columns hold the last time the seed has unchoked a
%connection
%For seed, the third 80 columns show the seed's connections' upload rate to
%the network
%For seed, the fourth 80 columns are used to store the number of pieces
%that each connection of the seed has

%Next n_pieces columns specify the rarity of each piece derived from
%connections of the peer.

%Next n_pieces columns specify the pieces that are requested from the
%connections that has currently unchokes this peer.

%The column second to last gives the piece profile's value when the profile is
%viewed as a binary number with last bit having the weight of 2^(n_pieces-1)

%The column prior to last one represents the number of pieces being
%downloaded. It cannot be more than 40.

%The last column keeps track of unchoking rounds this peer has entered since 
%joining the network.

pM=zeros(initial_n_peers+t_horizon/10*arrival_rate,req_in+n_pieces+3);

%Let them have their peer id as integers
%seed's peer id is -1
for i=2:initial_n_peers
    pM(i,1)=i;
end

%set seed's peer id as -1 to differentiate it from others
pM(1,1)=-1;
pM(1,2)=n_pieces; 

%tracker assigns connections now
for i=1:initial_n_peers
    id_array=pM(1:initial_n_peers,1)';
    id_array(i)=[];
    id_array_randomized=id_array(randperm(initial_n_peers-1));
    for j=1:n_assigned_connections
        row_address=find(pM(1:initial_n_peers,1)==id_array_randomized(j));
        if pM(row_address,3)<n_max_connections && pM(i,3)<n_max_connections ...
            && ~ismember(id_array_randomized(j),pM(i,14+n_pieces+1:14+n_pieces+pM(i,3))) 
            
            pM(i,3)=pM(i,3)+1;
            pM(row_address,3)=pM(row_address,3)+1;
            pM(i,pM(i,3)+14+n_pieces)=id_array_randomized(j);
            pM(row_address, pM(row_address,3)+14+n_pieces)=pM(i,1);  
            
        end
    end 
end

%assign piece profile to seed which should be all 1's
for k=1:n_pieces
    pM(1,14+k)=1;
end

%assign piece profile to most peers, which lack only last piece
%assign piece profile to the remaining peers that only have the last piece
%last piece plays the role of the missing piece here.
n_firsttype_peers=p_size-1-good_peers;
r=randperm(initial_n_peers-1);
for k=1:initial_n_peers-1
    if k <= n_firsttype_peers
        for j=1:n_pieces-1
            pM(r(k)+1,j+14)=1;
        end
        pM(r(k)+1, 2)=n_pieces-1;
    else
        pM(r(k)+1, 14+n_pieces)=1;
        pM(r(k)+1, 2)=1;
    end
end

%compute the value of bits by treating available pieces as 1 and others as 0
for i=1:active_n_p
    bit_value=0;
    for j=1:n_pieces
        bit_value=bit_value+(2^(j-1))*pM(i,14+j);
    end
    pM(i,end-2)=bit_value;
end

%we express the rarity of each piece to every
%individual peer, which is basically the number of connections that have a
%particular piece
for i=1:initial_n_peers
    for j=1:pM(i,3)
        myConn_id=pM(i,j+14+n_pieces);
        row_id= find(pM(1:initial_n_peers,1)==myConn_id);
        pM(i,rarity_in+1:rarity_in+n_pieces)= ...
            pM(i,rarity_in+1:rarity_in+n_pieces)+pM(row_id,15:14+n_pieces);  %#ok<FNDSB>
    end
end

%seed will upload to peers that have the minimum number of pieces
[ pM ] = seedUnchoker2_3( pM,t,pM(1,3),n_pieces,active_n_p,...
                   n_max_connections,rarity_in,req_in);

%unchoke 4 interested peers randomly
for i=2:initial_n_peers
    %unchoking only makes sense if the peer has some connections
    n_interested_peers=0;
    i_peers=zeros(1,n_max_connections);
    %ifLargest function returns 1 if peer i is a member of the
    %largest club. Otherwise, it returns 0.
    largest=ifLargest(pM,i,active_n_p,n_pieces);
    for j=1:pM(i,3)
        okToAdd=1;
        %id of my jth connection
        myConn_id=pM(i,14+n_pieces+j);
        %find the row of this id
        rx=find(pM(1:initial_n_peers,1)==myConn_id);
        %if the randomly chosen peer has less pieces than the unchoking peer
        %and the unchoking peer is in the largest club, then deny the
        %upload to this randomly chosen peer and look for other peers among
        %connections
        if largest==1 && pM(rx,2)<pM(i,2)
           okToAdd=0; 
        end
        %already_got includes bitwise sum of piece profile and
        %requested pieces
        if okToAdd==1
            already_got=pM(rx,15:14+n_pieces)...
                +pM(rx,req_in+1:req_in+n_pieces);
            b=cumsum((ones(1,n_pieces)-already_got)...
                .* pM(i,15:14+n_pieces));
            if b(n_pieces) > 0 && pM(rx,end-1)<40
                n_interested_peers=n_interested_peers+1;
                %ith peer's jth connection is interested
                i_peers(1,n_interested_peers)=j;
            end
        end 
    end
    
    if n_interested_peers > 0
        i_peers=i_peers(randperm(n_interested_peers));
        %note that i_peers stores the connection numbers
        for m=1:min(n_interested_peers,4)
            unchoked_peer_id=pM(i,14+n_pieces+i_peers(m));
            row_unchoked=find(pM(1:initial_n_peers,1)==unchoked_peer_id);
            not_needed=pM(row_unchoked,15:14+n_pieces)...
                +pM(row_unchoked,req_in+1:req_in+n_pieces);
            interesting_pieces=(ones(1,n_pieces)-not_needed).* pM(i,15:14+n_pieces);
            weighted_pieces=interesting_pieces .* ...
                pM(row_unchoked,req_in-n_pieces+1:req_in);
            
            %needed to exclude 0 values so that minimum of weighted pieces
            %gives the rarest available piece
            for k=1:n_pieces
                if weighted_pieces(k)==0
                    weighted_pieces(k)=n_max_connections*2;
                end
            end
            min_val=min(weighted_pieces);
            locations1=find(weighted_pieces(1,:)==min_val);
            %could be more than one rarest piece so randomize
            locations=locations1(randperm(numel(locations1)));
            rarest_piece_id=locations(1);
            %add this to the requested pieces
            pM(row_unchoked , req_in + rarest_piece_id)=1;
            %the id of the peer that ith peer is uploading to
            pM(i,6+m)=pM(row_unchoked,1);
            pM(i,10+m)=rarest_piece_id; 
            pM(row_unchoked,end-1)=pM(row_unchoked,end-1)+1;
        end
    end    
end

%everyone completed their fist unchoking rounds so their round counter 
%should be all 1
for i=1:initial_n_peers
    pM(i,end)=1;
end

%After starting the system, we update the the following variables
t=1;
t_array(1)=1;
active_n_p_array(1)=initial_n_peers;
largest_n_p_array(t)=getLargest(pM,active_n_p,n_pieces);

while t <= t_horizon
   
    if mod(t,10)==0
        %there should be a function that updates all the uploads
       
        [pM, n_uploaders ]= update_uploads10_3(pM,t,active_n_p,n_pieces,req_in,n_max_connections);
     
        %Let the peers that have just completed file leave the system
        %we should remove the departing peers from their connections
        [ pM, active_n_p ] = departure10_3( pM,active_n_p,n_pieces,...
            n_max_connections);
        
        %arrival process
        [ pM,active_n_p,agg_n_peers ] = arrival_3( pM,t,n_pieces, active_n_p...
            ,agg_n_peers,n_assigned_connections,arrival_rate,n_max_connections,...
            treshold );
    
          %let seed enter its unchoking round
        [ pM ] = seedUnchoker10_3( pM,t,pM(1,3),n_pieces,active_n_p...
            ,n_max_connections,rarity_in );
        
        %unchoke every peer but first randomize the peers
        %add 1 to exclude the seed
        shuffled=randperm(active_n_p-1);
        shuffled=shuffled+1;
  
        for i=1:numel(shuffled)
            %they can help if they have something to share
            if pM(shuffled(i),2)>0
                [pM]=normalUnchoker_3( pM, shuffled(i), n_pieces, n_max_connections ,...
                    active_n_p,rarity_in,req_in);
            end
        end
        
        
    elseif mod(t,2)==0
         %first update the completed uploads of the seed
        %note that we do not decrease number of connections here
        for i=1:4
            if pM(1,6+i)>0
                pM(1,4)=pM(1,4)+1;
                loc=find(pM(1:active_n_p,1)==pM(1,6+i));
                piece=pM(1,10+i);
                pM(loc,2)=pM(loc,2)+1;
                pM(loc,14+piece)=1;
                pM(loc,req_in+piece)=0;   
            end
        end
       
        %let the peers that have just completed the file thanks to the 
        %seed's current upload exit the network
        [ pM,active_n_p,need_unchoking ] = departure2_3( pM,...
            active_n_p,n_pieces,req_in, n_max_connections);
       
        %update the binary value of peers
        for i=1:active_n_p
            bit_value=0;
            for j=1:n_pieces
                bit_value=bit_value+(2^(j-1))*pM(i,14+j);
            end
            pM(i,end-2)=bit_value;
        end
       
        %seed needs to unchoke again if a peer it is uploading to has just left
        if need_unchoking==1
            [ pM ] = seedUnchoker2_3( pM,t,pM(1,3),n_pieces,active_n_p,...
                n_max_connections,rarity_in,req_in);
            
        %no one may have left among seed's peers but we may still need to
        %enter seed's unchoking round. If not, we have to choose new rare
        %pieces for peers that the seed is still uploading to
        
        %one such scenario would be that one of the seed's connections does
        %not require any piece from the seed anymore after this completed
        %download from the sedd because all the incompleted
        %pieces are being downloaded from other normal peers so this peer
        %has just become uninterested in the seed so the seed enters new
        %unchoking round although 10 seconds have not elapsed yet.
        else
           uc_needed=0;
           for i=1:4
               if pM(1,6+i)>0
                  row_id=find(pM(1:active_n_p,1)==pM(1,6+i)); 
                  dems=pM(row_id,15:14+n_pieces)+pM(row_id,req_in+1:req_in+n_pieces);
                  gop=cumsum(dems);
                  if gop(n_pieces)==n_pieces
                      uc_needed=1;
                  end
               end 
           end
           
           choked_counter=0;
           for m=1:4
               if pM(1,6+m)>0
                    choked_counter=choked_counter+1;
               end
           end
           
           %if the seed has a free slot and there is an interested peer, the
           %the seed will enter unchoking round
           if uc_needed==0 && choked_counter~=4
              for i=1:pM(1,3)
                  row_id=find(pM(1:active_n_p,1)==pM(1,14+n_pieces+i));
                  if ~ismember(pM(1,14+n_pieces+i),pM(1,7:10)) && pM(row_id(1),end-1)<36
                      dems=pM(row_id,15:14+n_pieces)+pM(row_id,req_in+1:req_in+n_pieces);
                      gop=cumsum(dems);
                      if gop(n_pieces)<n_pieces
                          uc_needed=1;
                      end 
                  end
              end      
           end
           
           if uc_needed==1
               [ pM ] = seedUnchoker2_3( pM,t,pM(1,3),n_pieces,active_n_p,...
                   n_max_connections,rarity_in,req_in);
           else
               [ pM ] = s_choose_new_pieces_3( pM,t,pM(1,3),n_pieces,active_n_p,...
                   n_max_connections,rarity_in,req_in);   
           end   
        end  
    else
    end
    t_array(t)=t;
    active_n_p_array(t)=active_n_p;
    largest_n_p_array(t)=getLargest(pM,active_n_p,n_pieces);
    t=t+1;
end
end



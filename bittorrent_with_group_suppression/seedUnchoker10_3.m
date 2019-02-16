function [ pM ] = seedUnchoker10_3( pM,t,n_c,n_p,n_active,n_max_c,rarity_in )

%This function enables the seed to unchoke its connections at times that
%are multiples of 10.

conn_index=14+n_p;
tlast_index=conn_index+n_max_c;
upratio_index=tlast_index+n_max_c;
num_pieces_index=upratio_index+n_max_c;

row1=pM(1,conn_index+1:conn_index+n_c);
row2=pM(1,tlast_index+1:tlast_index+n_c);
row3=pM(1,upratio_index+1:upratio_index+n_c);
row4=pM(1,num_pieces_index+1:num_pieces_index+n_c);

%sorting in an ascending fashion based on the number of the pieces of 
%the connections first,
%an then, in case of a tie, look at the upload rate to the network and 
%favor the one that has contributed more so far
mtr=[row4' row3' row2' row1'];
mtr=mtr(randperm(n_c),:);
sorted_mtr=sortrows(mtr,[1 -2 -3]);

for i=1:4
    for j=1:n_c
        pM(1,14+n_p+n_max_c*(i-1)+j)=sorted_mtr(j,5-i);
    end
end

unchoked_peers=[];
unchoked_peers_sorted=[];
old_unchoked_peers=[];
for i=1:4
    if pM(1,6+i)>0
        old_unchoked_peers(end+1)=pM(1,6+i);
    end
end

newly_unchoked_counter=0;
pass_conn=0;
while newly_unchoked_counter < 4 && pass_conn < pM(1,3)
    pass_conn=pass_conn+1;
    peer_id=pM(1,14+n_p+pass_conn);
    row_id=find(pM(1:n_active,1)==peer_id);
    bb= pM(row_id, 14+n_p*2+n_max_c*4+1:14+n_p*2+n_max_c*4+n_p) +pM(row_id, 14+1:14+n_p);
    bbb=cumsum(bb);
    if bbb(n_p) < n_p && pM(row_id,end-1)+5 <=40
        unchoked_peers_sorted(end+1)=peer_id;
        pM(row_id,end-1)=pM(row_id,end-1)+5;
        newly_unchoked_counter=newly_unchoked_counter+1 ; 
    end    
end 

%update the unchoked connections and tlast according to unchoked_peers_sorted
%to do that use newly_unchoked_counter, especially tlast

%set all the uploading connections to 0
pM(1,7:14)=zeros(1,8);
for i=1:numel(unchoked_peers_sorted)
    pM(1,6+i)=unchoked_peers_sorted(i);
    pos_peer=find(pM(1,14+n_p+1:14+n_p+pM(1,3)) == unchoked_peers_sorted(i));
    %update tlast if this peer is newly unchoked
    if  ~ismember(unchoked_peers_sorted(i),old_unchoked_peers)
        pM(1,14+n_p+n_max_c+pos_peer)=t;
    end
end

%choose the pieces for every unchoked peer must request
for j=1:numel(unchoked_peers_sorted)
    row_id=find(pM(1:n_active,1)==pM(1,6+j));
    %update the rarity of pieces for this unchoked peer
    pM(row_id,rarity_in+1:rarity_in+n_p)=0;
    for k=1:pM(row_id,3)
        c_row=find(pM(1:n_active,1)==pM(row_id,14+n_p+k));
        pM(row_id,rarity_in+1:rarity_in+n_p)=pM(row_id,rarity_in+1:rarity_in+n_p)...
            +pM(c_row(1),15:14+n_p);
    end
    
    not_needed=pM(row_id,15:14+n_p)+pM(row_id, ...
        14+n_p*2+n_max_c*4+1:14+n_p*2+n_max_c*4+n_p);
    interesting_pieces=(ones(1,n_p)-not_needed);
    weighted_pieces=interesting_pieces .* pM(row_id,14+n_p+n_max_c*4+1:14+n_p+n_max_c*4+n_p);
    for k1=1:n_p
        if weighted_pieces(k1)==0
            weighted_pieces(k1)=n_max_c+1;
        end
    end
    min_val=min(weighted_pieces);
    locations1=find(weighted_pieces(1,:)==min_val);
    locations=locations1(randperm(numel(locations1)));
    rarest_piece_id=locations(1);
    %add this to the requested pieces
    pM(row_id,14+n_p*2+n_max_c*4+rarest_piece_id)=1;
    %the id of the peer that ith peer is uploading to
    pM(1,10+j)=rarest_piece_id;
end
end


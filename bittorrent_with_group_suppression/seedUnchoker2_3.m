function [ pM ] = seedUnchoker2_3( pM,t,n_c,n_p,n_active,n_max_c,...
    rarity_in,req_in )

%This function unchokes the seed's connections at t such that mod(t,2)=0
%but mod(t,10)!=0

conn_index=14+n_p;
tlast_index=conn_index+n_max_c;
upratio_index=tlast_index+n_max_c;
num_pieces_index=upratio_index+n_max_c;

pM(1,14+n_p+n_max_c*3+1:14+n_p+n_max_c*4)=0;
for i=1:pM(1,3)
    row_id=find(pM(1:n_active,1)==pM(1,14+n_p+i));
    pM(1,14+n_p+n_max_c*3+i)=pM(row_id,2);
end

row1=pM(1,conn_index+1:conn_index+n_c);
row2=pM(1,tlast_index+1:tlast_index+n_c);
row3=pM(1,upratio_index+1:upratio_index+n_c);
row4=pM(1,num_pieces_index+1:num_pieces_index+n_c);

%sorting in an ascending fashion based on the number of the pieces 
%of the connections first and then
%in case of tie look at the upload rate to the network and favor the one
%that has contributed more so far

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
        row_id=find(pM(1:n_active,1)==pM(1,6+i));
        pM(row_id,end-1)=pM(row_id,end-1)-5;
    end
end

newly_unchoked_counter=0;
pass_conn=0;
while newly_unchoked_counter < 4 && pass_conn < pM(1,3)
    pass_conn=pass_conn+1;
    peer_id=pM(1,14+n_p+pass_conn);
    row_id=find(pM(1:n_active,1)==peer_id);
    bb= pM(row_id, req_in+1:req_in+n_p) +pM(row_id, 14+1:14+n_p);
    bbb=cumsum(bb);
    if bbb(n_p) < n_p && pM(row_id,end-1)+5 <=40
        unchoked_peers_sorted(end+1)=peer_id;
        pM(row_id,end-1)=pM(row_id,end-1)+5;
        newly_unchoked_counter=newly_unchoked_counter+1 ; 
    end    
end 

%update the unchoked connections and tlast according to unchoked_peers_sorted
%to do that use newly_unchoked_counter especially tlast

%reset all the connections that the seed was uploading to.
pM(1,7:14)=0;
for i=1:numel(unchoked_peers_sorted)
    pM(1,6+i)=unchoked_peers_sorted(i);
    pos_peer=find(pM(1,14+n_p+1:14+n_p+pM(1,3)) == unchoked_peers_sorted(i));
    %update tlast if this peer is newly unchoked
    if  ~ismember(unchoked_peers_sorted(i),old_unchoked_peers)
        pM(1,14+n_p+n_max_c+pos_peer)=t;
    end
end

for j=1:numel(unchoked_peers_sorted)
    row_id=find(pM(1:n_active,1)==pM(1,6+j));
    %this unchoked peer updates the rarity of the piece 
    %first set it to 0
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
    %exclude the pieces with rarity equal to 0.
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
    pM(1,10+j)=rarest_piece_id;
end
end


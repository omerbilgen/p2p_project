function [ pM ] = seedUnchoker10_3( pM,t,n_c,n_p,n_active,n_max_c,rarity_in )

%This function enables the seed to unchoke its connections at times that
%are multiples of 10.

unchoked_peers=[];
unchoked_tlast=[];
unchoked_u_ratio=[];
unchoked_peers_sorted=[];
old_unchoked_peers=[];
for i=1:4
    if pM(1,6+i)>0
        old_unchoked_peers(end+1)=pM(1,6+i);
    end
end

for i=1:4
    if pM(1,6+i)>0
        order_peer=find(pM(1,15+n_p:14+n_p+n_c)==pM(1,6+i));
        row_peer=find(pM(1:n_active,1)==pM(1,6+i));
        b=cumsum( pM(row_peer,15:14+n_p) + pM(row_peer,14+n_max_c*4+n_p*2+1 ...
            :14+n_max_c*4+n_p*3) );
        if b(n_p)~=n_p && t-pM(1,14+n_p+n_max_c+order_peer)<20 
            unchoked_peers(end+1)=pM(row_peer,1);
            unchoked_tlast(end+1)=pM(1,14+n_p+n_max_c+order_peer);
            unchoked_u_ratio(end+1)=pM(14+n_p+n_max_c*2+order_peer);
            pM(row_peer,end-1)=pM(row_peer,end-1)+5;
        end
        
    end
end

[unchoked_tlast_sorted, I]=sort(unchoked_tlast,'descend');
%sorted based on tlast
unchoked_peers_sorted=unchoked_peers(I);
unchoked_u_ratio_sorted=unchoked_u_ratio(I);
%if there is no tie with the fourth peer, we are fine
%if there is one, we need to figure out how many ties
if numel(unchoked_peers_sorted)>0 && numel(unchoked_peers_sorted)==4
    tie_locations=find( unchoked_tlast_sorted==min(unchoked_tlast_sorted) );
    n_ties=numel(tie_locations);
    if n_ties > 1
        
        [s2 I]=sort(unchoked_u_ratio_sorted(tie_locations),'descend');
        s3=unchoked_peers_sorted(4-n_ties+1:4);
        s4=s3(I);
        unchoked_peers_sorted(4-n_ties+1:4)=s4;
    end
end

%now sort other interested peers based on their uplading rate
%we need 4-length of unchoked peers so far, which is numel(unchoked_peers_sorted)

%first randomize the order of the connections so that if there is equality
%on their upload rate, which we expect happens a lot since we assumed
%constant upload rate, the peers in tie are unchoked in random fashion
permute_everyone=randperm(pM(1,3));
for z=1:3
    temp=pM(1,14+n_p+n_max_c*(z-1)+1:14+n_p+n_max_c*(z-1)+pM(1,3));
    pM(1,14+n_p+n_max_c*(z-1)+1:14+n_p+n_max_c*(z-1)+pM(1,3))=temp(permute_everyone);
end

%sort based on the uplad ratios and apply the same ordering to the connections 
%and the last time they were unchoked arrays
[uploads_sorted, upl_ordering]=sort(pM(1,14+n_p+n_max_c*2+1: ...
    14+n_max_c*2+n_p+pM(1,3)),'descend');
pM(1,14+n_p+n_max_c*2+1:14+n_max_c*2+n_p+pM(1,3))=uploads_sorted;

temp=pM(1,14+n_p+1:14+n_p+pM(1,3));
pM(1,14+n_p+1:14+n_p+pM(1,3))=temp(upl_ordering);

temp=pM(1,14+n_p+n_max_c+1:14+n_p+n_max_c+pM(1,3));
pM(1,14+n_p+n_max_c+1:14+n_p+n_max_c+pM(1,3))=temp(upl_ordering);

%if the number of unchoked peers from previous round is below 4, we are going
%to need other peers to unchoke
newly_unchoked_counter=0;
pass_conn=0;
n_needed_peers=4-numel(unchoked_peers_sorted);

while newly_unchoked_counter < n_needed_peers && pass_conn < pM(1,3)
    
    pass_conn=pass_conn+1;
    peer_id=pM(1,14+n_p+pass_conn);
    row_id=find(pM(1:n_active,1)==peer_id);
    bb= pM(row_id, 14+n_p*2+n_max_c*4+1:14+n_p*2+n_max_c*4+n_p) +pM(row_id, 14+1:14+n_p);
    bbb=cumsum(bb);
    
    if bbb(n_p) < n_p && ~ismember(peer_id, unchoked_peers_sorted) ...
            && pM(row_id,end-1)+5 <=40
        
        unchoked_peers_sorted(end+1)=peer_id;
        pM(row_id,end-1)=pM(row_id,end-1)+5;
        newly_unchoked_counter=newly_unchoked_counter+1 ; 
    end    
end

if mod(pM(1,end),3)~=0
   if numel(unchoked_peers_sorted) ==4
       a1=randperm(pM(1,3));
       done=0;
       coun=0;
       while done==0 && coun < pM(1,3)
           coun=coun+1;
           peer_id=pM(1,14+n_p+a1(coun));
           row_id=find(pM(1:n_active,1)==peer_id);
           bb= pM(row_id, 14+n_p*2+n_max_c*4+1:14+n_p*2+n_max_c*4+n_p) +pM(row_id, 14+1:14+n_p);
           bbb=cumsum(bb);
           if bbb(n_p) < n_p && ~ismember(peer_id,unchoked_peers_sorted)...
                   && pM(row_id,end-1)+5 <= 40
               row_notunchoked=find(pM(1:n_active,1)==unchoked_peers_sorted(4));
               pM(row_notunchoked,end-1)=pM(row_notunchoked,end-1)-5;
               unchoked_peers_sorted(4)=peer_id;
               pM(row_id,end-1)=pM(row_id,end-1)+5;
               done=1;
           end        
       end  
   end   
end

%update the unchoked connections and tlast according to unchoked_peers_sorted
%to do that use newly_unchoked_counter especially tlast

%set all the uploading connections to 0
pM(1,7:14)=0;
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
    %update the rarity matrix
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


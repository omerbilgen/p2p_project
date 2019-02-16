function [ pM ] = normalUnchoker_3( pM, myRow, n_p, n_m_c ,active_n_p,...
    rarity_in,req_in)

%This function enables the peer residing in myRow to unchoke the peers in
%this particular round


n_c=pM(myRow,3);
unchoked=[];

%If the unchoking round is a multiple of 3, then it is time to change our
%optimistically unchoked peer and choose a new peer uniformly at random
if mod(pM(myRow,end),3)==0
    %shuffle the connections
    done=0;
    pass_count=0;
    while done==0 && pass_count < pM(myRow,3)
        pass_count=pass_count+1;
        row_id=find(pM(1:active_n_p,1)==pM(myRow,14+n_p+pass_count));
        if ~ismember(pM(myRow,14+n_p+pass_count),pM(myRow,7:10)) && pM(row_id,end-1)<40
            
            not_needed= pM(row_id, req_in+1:req_in+n_p)...
                +pM(row_id, 14+1:14+n_p);
            interesting=(ones(1,n_p)-not_needed).*pM(myRow,15:14+n_p);
            bbb=cumsum(interesting);
            if bbb(n_p)>0
               %bring this connection to the front
               ord=pass_count;
               done=1;
               %all the 80-column wide blocks should be reordered
               for z=1:4
                   temp1=pM(myRow,14+n_p+(z-1)*n_m_c+ord:14+n_p+(z-1)*n_m_c+n_c);
                   temp2=pM(myRow,14+n_p+(z-1)*n_m_c+1:14+n_p+(z-1)*n_m_c+ord-1);
                   pM(myRow,14+n_p+(z-1)*n_m_c+1:14+n_p+(z-1)*n_m_c+n_c-ord+1)=temp1;
                   pM(myRow,14+n_p+(z-1)*n_m_c+n_c-ord+2:14+n_p+(z-1)*n_m_c+n_c)=temp2;
               end
            end
        end 
    end
end
 
%sort all the connections in descending order of their upload ratio to this
%peer
[~, I]=sort(pM(myRow,14+n_p+n_m_c*2+1:14+n_p+n_m_c*2+n_c),'descend');
temp=pM(myRow,14+n_p+1:14+n_p+n_c);
conn_sorted=temp(I);

counter=0;
while counter < numel(conn_sorted) && numel(unchoked)<3
    counter=counter+1;
    row_id=find(pM(1:active_n_p,1)==conn_sorted(counter));
    not_needed= pM(row_id, 14+n_p*2+n_m_c*4+1:14+n_p*2+n_m_c*4+n_p)...
        +pM(row_id, 14+1:14+n_p);
    interesting=(ones(1,n_p)-not_needed).*pM(myRow,15:14+n_p);
    bbb=cumsum(interesting);
    %add this connection to the list of unchoked connections if it has an
    %available download slot and we have a piece that it is seeking
    if bbb(n_p)>0 && pM(row_id,end-1)<40
        unchoked(end+1)=conn_sorted(counter);
        pM(row_id,end-1)=pM(row_id,end-1)+1;
    end
end


%time for optimistic unchoking
%note that if the unchoking round is not a multiple of 3, we keep the same 
%optimistically unchoked peer unchoked if, of course, it is still
%interested in our pieces
pass_count=0;
counter2=0;
while counter2 < 4-numel(unchoked) && pass_count < n_c
    pass_count=pass_count+1;
    row_id=find(pM(1:active_n_p,1)==pM(myRow,14+n_p+pass_count));
    not_needed= pM(row_id, 14+n_p*2+n_m_c*4+1:14+n_p*2+n_m_c*4+n_p)...
        +pM(row_id, 14+1:14+n_p);
    interesting=(ones(1,n_p)-not_needed).*pM(myRow,15:14+n_p);
    bbb=cumsum(interesting);
    
    if bbb(n_p)>0  && ~ismember(pM(row_id,1),unchoked) && pM(row_id,end-1)<40
        unchoked(end+1)=pM(row_id,1);
        pM(row_id,end-1)=pM(row_id,end-1)+1;
        counter2=counter2+1;  
    end  
end

%set the upload slots and pieces to be uploaded to 0
pM(myRow,7:14)=0;

for i=1:numel(unchoked)
    pM(myRow,6+i)=unchoked(i);
end

%choose the pieces to be uploaded to unchoked peers
for j=1:numel(unchoked)
    row_id=find(pM(1:active_n_p,1)==pM(myRow,6+j));
    %update the rarity matrix of the unchoked peer
    pM(row_id,rarity_in+1:rarity_in+n_p)=0;
    for k=1:pM(row_id,3)
        c_row=find(pM(1:active_n_p,1)==pM(row_id,14+n_p+k));
        pM(row_id,rarity_in+1:rarity_in+n_p)=pM(row_id,rarity_in+1:rarity_in+n_p)...
            +pM(c_row(1),15:14+n_p);
    end
    
    %the unchoked peer updates its rarity then finds the rarest one among the pieces
    %that we offer it
    not_needed=pM(row_id,15:14+n_p)+pM(row_id, req_in+1:req_in+n_p);
    interesting_pieces=(ones(1,n_p)-not_needed).* pM(myRow,15:14+n_p);
    weighted_pieces=interesting_pieces .* pM(row_id,14+n_p+n_m_c*4+1:14+n_p+n_m_c*4+n_p);
    for k1=1:n_p
        if weighted_pieces(k1)==0
            weighted_pieces(k1)=n_m_c+1;
        end
    end
    min_val=min(weighted_pieces);
    locations1=find(weighted_pieces(1,:)==min_val);
    %randomize if more than one piece are equally rare
    locations=locations1(randperm(numel(locations1)));
    rarest_piece_id=locations(1);
    %add this to the requested pieces
    pM(row_id,req_in+rarest_piece_id)=1;
    pM(myRow,10+j)=rarest_piece_id;
end

    
end







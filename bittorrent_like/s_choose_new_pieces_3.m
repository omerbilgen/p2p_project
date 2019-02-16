function [ pM ] = s_choose_new_pieces_3(pM,t,n_c,n_p,n_active,n_max_c,...
    rarity_in,req_in)
%this function chooses new rarest pieces for the peers unchoked by the seed

pM(1,11:14)=0;

for j=1:4
    if pM(1,6+j)>0
        row_id=find(pM(1:n_active,1)==pM(1,6+j));
        pM(row_id,rarity_in+1:rarity_in+n_p)=0;
        %update the rarity of this unchoked peer
        for k=1:pM(row_id,3)
            c_row=find(pM(1:n_active,1)==pM(row_id,14+n_p+k));
            pM(row_id,rarity_in+1:rarity_in+n_p)=pM(row_id,rarity_in+1:rarity_in+n_p)...
                +pM(c_row(1),15:14+n_p);
        end
        
        not_needed=pM(row_id,15:14+n_p)+pM(row_id, ...
            req_in+1:req_in+n_p);
        interesting_pieces=(ones(1,n_p)-not_needed);
        weighted_pieces=interesting_pieces .* pM(row_id,rarity_in+1:rarity_in+n_p);
        for k1=1:n_p
            if weighted_pieces(k1)==0
                weighted_pieces(k1)=n_max_c+1;
            end
        end
        min_val=min(weighted_pieces);
        locations1=find(weighted_pieces(1,:)==min_val);
        %randomize the rarest pieces
        locations=locations1(randperm(numel(locations1)));
        rarest_piece_id=locations(1);
        %add this to the requested pieces
        pM(row_id,req_in+rarest_piece_id)=1;
        pM(1,10+j)=rarest_piece_id;
        
    end     
end
end


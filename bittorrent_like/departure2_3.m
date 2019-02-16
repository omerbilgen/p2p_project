function [ pM,active_n_p,need_unchoking ] = departure2_3( pM,active_n_p,n_pieces,req_in, ...
    n_max_connections)

%This function updates what needs to be updated throughout the network
%after some peers leave due to 2-second long seed uploads. It amounts to
%seeing if the seed need to go through an unchoking round and updating the
%departed peer's connections and notifying peers that were getting some
%piece from the departed peer that they are not getting that piece and etc.

need_unchoking=0;

for i=1:4
    if pM(1,6+i)>0
        loc=find(pM(1:active_n_p,1)==pM(1,6+i));
        if pM(loc,2)==n_pieces
            need_unchoking=1;
            pM(1,6+i)=0;
            pM(1,10+i)=0;
            %if this peer was uploading to some other peer, that download will
            %not happen, so every peer that this peer is uploading to should
            %update things accordingly
            for j=1:4
                if pM(loc,6+j) > 0
                    loc_affected=find(pM(1:active_n_p,1)==pM(loc,6+j));
                    affected_piece=pM(loc,10+j);
                    pM(loc_affected,req_in+affected_piece)=0;
                    pM(loc_affected,end-1)=pM(loc_affected,end-1)-1;
                end
            end
            
            %every peer connected to this peer should disconnect from this peer
            for k=1:pM(loc,3)
                disconn_row=find(pM(1:active_n_p,1)==pM(loc, 14+n_pieces+k));
          
                %find the order of departing peer within the  connections of 
                %the peer located in disconn_row
                ord=find(pM(disconn_row(1),14+n_pieces+1:14+n_pieces+n_max_connections)==pM(loc,1));
                for rs=1:4
                    pM(disconn_row(1),14+n_pieces+(rs-1)*n_max_connections+ord ...
                        : 14+n_pieces+(rs-1)*n_max_connections+pM(disconn_row(1),3)-1)=...
                        pM(disconn_row(1),14+n_pieces+(rs-1)*n_max_connections+ord+1 ...
                        : 14+n_pieces+(rs-1)*n_max_connections+pM(disconn_row(1),3));
                    pM(disconn_row(1),14+n_pieces+(rs-1)*n_max_connections+pM(disconn_row(1),3))=0;
                end
                pM(disconn_row,3)=pM(disconn_row,3)-1;
                %if these connections were uploading to departing
                %peer, they should clear departing peer's id from the list of 
                %peer ids that are downloading from them
                if ismember(pM(loc,1),pM(disconn_row,7:10))
                    undortunate_index=find(pM(disconn_row,7:10)==pM(loc,1));
                    pM(disconn_row,6+undortunate_index)=0;
                    pM(disconn_row,10+undortunate_index)=0;
                end
                
            end
            %we deleted its connections and halted its uploading process 
            %to other peers
            %now update active peers
            pM(loc,:)=pM(active_n_p,:);
            pM(active_n_p,:)=0;
            active_n_p=active_n_p-1;
        end
    end
 
end



end


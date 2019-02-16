function [ pM, active_n_p ] = departure10_3( pM,active_n_p,n_pieces, ...
    n_max_connections)

%this function deletes the peers that have just completed all the pieces
%from the pM matrix and halts their connections to the remaining peers

i=2;
while i <= active_n_p
    if pM(i,2)==n_pieces
        for j=1:pM(i,3)
            disconn_row=find(pM(1:active_n_p,1)==pM(i, 14+n_pieces+j));
            
            if ismember(pM(i,1),pM(disconn_row,7:10))
                rel=find(pM(disconn_row,7:10)==pM(i,1));
                for klm=rel:3
                    pM(disconn_row,klm+6)=pM(disconn_row,6+klm+1);
                end
                pM(disconn_row,10)=0;
            end
            ord=find(pM(disconn_row(1),14+n_pieces+1: ...
                14+n_pieces+n_max_connections)==pM(i,1));
            for rs=1:4
                pM(disconn_row(1),14+n_pieces+(rs-1)*n_max_connections+ord ...
                    : 14+n_pieces+(rs-1)*n_max_connections+pM(disconn_row(1),3)-1)=...
                    pM(disconn_row(1),14+n_pieces+(rs-1)*n_max_connections+ord+1 ...
                    : 14+n_pieces+(rs-1)*n_max_connections+pM(disconn_row(1),3));
                pM(disconn_row(1),14+n_pieces+(rs-1)*n_max_connections+pM(disconn_row(1),3))=0; 
            end 
            pM(disconn_row,3)=pM(disconn_row,3)-1;
        end
        pM(i,:)=pM(active_n_p,:);
        pM(active_n_p,:)=0;
        i=i-1;
        active_n_p=active_n_p-1;
    end
    i=i+1;
end

end


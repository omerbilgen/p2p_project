function [ pM,active_n_p,agg_n_peers ] = arrival_3( pM,t,n_pieces, ...
    active_n_p,agg_n_peers,n_assigned_connections,arrival_rate,...
    n_max_connections,treshold )
%Main purpose of this function is to assign newcomers to already existing
%peers in the network and assign new connections to peers with connections
%less than 20.

%the array in which we store peers connected to less than tweny peers
under20=zeros(active_n_p);
count=0;
conn_in=14+n_pieces;
tlast_in=14+n_pieces+n_max_connections;
since_in=14+n_pieces+n_max_connections*3;

for i=1:active_n_p
    if pM(i,3)<treshold
        count=count+1;
        under20(count)=i;
    end
end

%randomize the peers
under_20=under20(randperm(count));

if count>0
    for k=1:count
        i=under_20(k);
        row_address=1:active_n_p;
        %exclude itself from the possible new connections to be added
        row_address(i)=[];
        row_address=row_address(randperm(active_n_p-1));
        for j=1:min(n_assigned_connections,active_n_p-1)
            if pM(row_address(j),3)<n_max_connections && pM(i,3)<n_max_connections ...
                    && ~ismember(pM(row_address(j),1),pM(i,14+n_pieces+1:14+n_pieces+pM(i,3)))
                
                pM(i,3)=pM(i,3)+1;
                pM(row_address(j),3)=pM(row_address(j),3)+1;
                pM(i,pM(i,3)+14+n_pieces)=pM(row_address(j),1);
                pM(row_address(j), pM(row_address(j),3)+14+n_pieces)=pM(i,1);
                
                pM(i, 14+n_pieces+n_max_connections*3+pM(i,3))=t;
                pM(row_address(j),14+n_pieces+n_max_connections*3+pM(row_address(j),3))=t;
                
                %seed's row is constructed differently, particularly 80 column
                %wide blocks correspond to different variables as outlined in
                %bittorrent_like.m
                if i==1
                    pM(i,14+n_pieces+n_max_connections+pM(i,3))=0;
                    pM(i,14+n_pieces+n_max_connections*2+pM(i,3))=pM(row_address(j),6);
                    pM(row_address(j),14+n_pieces+n_max_connections+pM(row_address(j),3))=t;
                    pM(row_address(j),14+n_pieces+n_max_connections*2+pM(row_address(j),3))=0;
                    
                elseif row_address(j)==1
                    
                    pM(row_address(j),14+n_pieces+n_max_connections*2+pM(row_address(j),3))=pM(i,6);
                    pM(row_address(j),14+n_pieces+n_max_connections+pM(row_address(j),3))=0;
                    pM(i,14+n_pieces+n_max_connections+pM(i,3))=t;
                    pM(i,14+n_pieces+n_max_connections*2+pM(i,3))=0;
                    
                else
                    
                    pM(i,14+n_pieces+n_max_connections+pM(i,3))=t;
                    pM(i,14+n_pieces+n_max_connections*2+pM(i,3))=0;
                    pM(row_address(j),14+n_pieces+n_max_connections+pM(row_address(j),3))=t;
                    pM(row_address(j),14+n_pieces+n_max_connections*2+pM(row_address(j),3))=0;
                end
            end
        end
    end
end

for i=1:arrival_rate
    agg_n_peers=agg_n_peers+1;
    active_n_p=active_n_p+1;
    pM(active_n_p,1)=agg_n_peers;
    pM(active_n_p,5)=t;
    row_address=1:active_n_p-1;
    row_address=row_address(randperm(active_n_p-1));
    
    for j=1:min(n_assigned_connections,active_n_p-1)
        
        if pM(row_address(j),3)<n_max_connections && pM(active_n_p,3)<n_max_connections 
            pM(active_n_p,3)=pM(active_n_p,3)+1;
            pM(row_address(j),3)=pM(row_address(j),3)+1;
            pM(active_n_p,pM(active_n_p,3)+conn_in)=pM(row_address(j),1);
            pM(row_address(j), pM(row_address(j),3)+conn_in)=pM(active_n_p,1);
            pM(active_n_p,tlast_in+pM(active_n_p,3) )=t;
            pM(active_n_p,since_in+pM(active_n_p,3) )=t;
            pM(row_address(j),since_in+pM(row_address(j),3))=t;
            
            if row_address(j)==1
                pM(row_address(j),tlast_in+pM(row_address(j),3))=0;   
            else
                pM(row_address(j),tlast_in+pM(row_address(j),3))=t;
                
            end  
        end  
    end     
end


end




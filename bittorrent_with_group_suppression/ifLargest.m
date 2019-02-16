function [ largest ] = ifLargest( pM, row, active_n_p, n_p )

%it returns 1 if the peer in question belongs to the largest club.
%Otherwise returns 0.

largest=0;
peer_values=zeros(1,pM(row,3)+1);
peer_values(1)= pM(row,end-2);
for i=1:pM(row,3)
    row_id=find(pM(1:active_n_p,1)==pM(row,14+n_p+i));
    peer_values(i+1)=pM(row_id,end-2);
end

[urt, ~, ~]=unique(peer_values);
bincount=histc(peer_values,urt);
[sorted_bincount, order]=sort(bincount,'descend');
sorted_peer_values=urt(order);
pos=find(sorted_peer_values(1,:)==pM(row,end-2));
freq=sorted_bincount(pos);

if numel(sorted_peer_values)==1
    largest=1; 
else
    if freq~=sorted_bincount(1)
        largest=0;
    elseif sorted_bincount(1)~=sorted_bincount(2)
        largest=1;
    else  
    end  
end
end


function [ n_l_p ] =getLargest(pM,active_n_p,n_pieces)

%This function returns the value of the most populous piece profile when the piece profiles
%are viewed as binary numbers where the first bit has weight of 2^0 
%and the last bit has weight of 2^(n_pieces-1)

%first update bit values of every peer
for i=1:active_n_p
    bit_value=0;
    for j=1:n_pieces
        bit_value=bit_value+pM(i,14+j)*(2^(j-1));
    end
    pM(i,end-2)=bit_value; 
end

peer_values=zeros(1,active_n_p);

for i=1:active_n_p
    peer_values(i)=pM(i,end-2);
end

[urt, ~, ~]=unique(peer_values);
bincount=histc(peer_values,urt);
[sorted_bincount, ~]=sort(bincount,'descend');
n_l_p=sorted_bincount(1);

end


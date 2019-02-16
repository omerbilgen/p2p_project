function [ pM, n_uploaders ] = update_uploads10_3(pM,t,active_n_p,n_p,...
    req_in,n_max_c)

%This function updates the network at t such that mod(t,10)=0. It includes
%updating every peer's upload rate to its connections and adding pieces
%that they have downloaded in the last 10 seconds to their piece profile

n_uploaders=0;

for i=1:active_n_p
    %update the round counter because this t is a multiple of 10
    if pM(i,2)>0
     pM(i,end)=pM(i,end)+1;
    end
    
    for j=1:4
        if pM(i,6+j)>0
            pM(i,4)=pM(i,4)+1;
            peer_id=pM(i,6+j);
            piece_id=pM(i,10+j);
            %row_id is the row where the downloading peer is located
            row_id=find(pM(1:active_n_p,1)==peer_id);
            pM(row_id,14+piece_id)=1;
            pM(row_id,2)=pM(row_id,2)+1;
            pM(row_id,req_in+piece_id)=0;
            %the uploading peer's order within the connections of the 
            %downloading peer
            ord=find(pM(row_id,14+n_p+1:14+n_p+n_max_c)==pM(i,1));
            t_last=pM(row_id,14+n_p+n_max_c+ord);
            rate=pM(row_id,14+n_p+n_max_c*2+ord);
            rate_since=pM(row_id,14+n_p+n_max_c*3+ord);
            %update the upload rate of the uploading peer in the downloading 
            %peer's appropriate column
            pM(row_id,14+n_p+n_max_c*2+ord)=( rate*(t_last-rate_since)+1)/...
                (t-rate_since);
            
            %update rate_since time if it is not recent
            pM(row_id,14+n_p+n_max_c+ord)=t;
            if rate_since < t-20
                pM(row_id,14+n_p+n_max_c*3+ord)=t-20;
            end
        end
    end
end


for i=2:active_n_p
    for j=1:pM(i,3)
        %we now update ith peer's connections'upload rates to this peer
        %and other related quantities if the connections have not uploaded 
        %to this ith peer in this round
        if pM(i,14+n_p+n_max_c+j)<t
            
            t_last=pM(i,14+n_p+n_max_c+j);
            rate=pM(i,14+n_p+n_max_c*2+j);
            rate_since=pM(i,14+n_p+n_max_c*3+j);
            %note that there is no +1 following rate*(t_last-rate_since)
            %unlike the update we carried out in the previous for iteration
            %it is because the connection has not uploaded to this peer in
            %this round
            pM(i,14+n_p+n_max_c*2+j)=rate*(t_last-rate_since)/(t-rate_since);
            pM(i,14+n_p+n_max_c+j)=t;
            if rate_since < t-20
                pM(i,14+n_p+n_max_c*3+j)=t-20;
            end
        end
    end   
end

%every peer's upload rate to the network is found by the same formula that
%we apply to determine individual peers' connections' upload rate to that
%individual peer
for i=1:pM(1,3)
    peer_id=pM(1,14+n_p+i);
    row_id=find(pM(1:active_n_p,1)==peer_id);
    pM(1,14+n_p+n_max_c*2+i)=(pM(1,14+n_p+n_max_c*2+i)*(t-10-pM(row_id,5))...
        +pM(row_id,4))/(t-pM(row_id,5));
    pM(row_id,6)= pM(1,14+n_p+n_max_c*2+i);
     if pM(row_id,5) < t-20
         pM(row_id,5)=t-20;
    end
end

%one might ask why do we have to calculate this even though the peer may
%not be a neighbor of the seed. We should consider the scenario where the
%peer in question connects to the seed later. How could the seed calculate 
%the upload rate of the past? Thus, we need to update the upload rate of 
%every peer in the network
for i=1:active_n_p
    %the seed's connections are alrady updated, so exclude them
    if ~ismember(pM(i,1),pM(1,14+n_p+1:14+n_p+n_max_c))
        pM(i,6)=(pM(i,6)*(t-10-pM(i,5))+pM(i,4))/(t-pM(i,5));
        if pM(i,5) < t-20
         pM(i,5)=t-20;
        end
    end
    
end

%set number of uploads to 0 for this round
%set number of download slots to 0 
for i=2:active_n_p
    pM(i,4)=0;
    pM(i,end-1)=0;
end


end


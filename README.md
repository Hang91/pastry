Group member:
Hang Jin, Ying Zhu

Please use ./pastry numNodes numRequests to run the script
example:
./pastry 1000 5

Implemented pastry node and pastry system.
Every pastry node can start to send message numRequests times and forward message to node that is closer to destination than itself.


nodeId is 32 digit base 16 integer. Used md5 and integer from 1 to nodeNum to get them.
leaf greater and less set size is 16, all is 32.
neighbor set size is 32.
Optimized the time complexity of routing table construction with binary search from n^2 to nlog(n) 

I used a 8GB memory computer. When the node number is greater than 5000, there is not enough memory for it. My largest network is 5000 nodes with average hops 2.809


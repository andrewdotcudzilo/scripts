@                       IN	SOA	ns3.softcomca.com.	postmaster.softcomca.com.	(
                        2016050913     ; serial number
			21600      ; refresh [6h]		
			3600       ; retry   [1h]		
			691200     ; expire  [8d]		
            3600)     ; minimum TTL [1d]
;
@                       IN	NS	ns3.softcomca.com.
@                       IN	NS	ns4.softcomca.com.
@                       IN	MX	1 mail
ftp                     IN	CNAME	@
www                     IN	CNAME	@
emailadmin				IN	A 	168.144.1.21
smtp                    IN  A   168.144.68.90
mail                    IN  A   168.144.68.90
@                       IN  A   168.144.69.63

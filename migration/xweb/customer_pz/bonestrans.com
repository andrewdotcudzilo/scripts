N      SOA     ns5.softcomca.com.      postmaster.softcomca.com.       (
                        2014091516     ; serial number
                        21600      ; refresh              
                        3600       ; retry             
                        691200     ; expire            
            3600)     ; minimum TTL 
;
@                       IN      NS      ns5.softcomca.com.
@                       IN      NS      ns6.softcomca.com.
@                       IN      MX      1       mail
ftp                     IN      CNAME   @
www                     IN      CNAME   @
emailadmin                              IN      A       168.144.1.21
smtp                    IN  A   168.144.68.68
mail                    IN  A   168.144.68.68
@                       IN  A   168.144.181.156


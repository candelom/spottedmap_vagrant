## Maintainer: @awahed
##
## Modified from nginx http version
## Modified from https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
## Lines starting with two hashes (##) are comments with information.
## Lines starting with one hash (#) are configuration parameters that can be uncommented.

#Spottedmap_web
upstream spottedmap_web_upstream {

    server 10.240.231.14:8080;
    ## put more upstream servers here
    keepalive 64;
}


server {
       listen         80;
       server_name    spottedmap.com;
       return         301 https://$server_name$request_uri;
}

server {
        server_name www.spottedmap.com;
        return 301 $scheme://spottedmap.com$request_uri;
}
server {
    
    listen 443 ssl;

    server_name spottedmap.com; ## Replace this with something like asq.example.com
    server_tokens off; ## Don't show the nginx version number, a security best practice

    ssl_certificate   /var/www/ssl_cert/spottedmap.com/spottedmap_combined.crt;
    ssl_certificate_key /var/www/ssl_cert/spottedmap.key;

    ## https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;

    ## recommended ciphers if no backwards compatibility (IE6/WinXP) is required
    ## if you enable them make sure you disable the backwards compatibility ciphers
    # ssl_ciphers 'AES256+EECDH:AES256+EDH:!aNULL:!eNULL';

    ## ciphers with backwards compatibility (IE6/WinXP)
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128:AES256:AES:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK';

    ssl_prefer_server_ciphers on;
    ssl_session_cache  builtin:1000  shared:SSL:10m;

    add_header Strict-Transport-Security max-age=63072000;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;

    # host_without_www
    if ( $host ~* ^www\.(?<nowww>.*)$ ) {
    	rewrite .* $scheme://$nowww$request_uri permanent;
    }

    ## Individual nginx logs for this ASQ server block
    access_log  /var/log/nginx/spottedmap_access.log;
    error_log   /var/log/nginx/spottedmap_error.log;

    ## if upstream fails
    error_page 502  /errors/502.html;

    ## serve static assets
    location ~ ^/(images/|img/|javascript/|js/|css/|stylesheets/|fonts/|flash/|media/|static/|robots.txt|humans.txt|favicon.ico) {
      root /var/www/spottedmap_web/public;
      access_log off;
      expires max;
    }

    location /errors {
      internal;
      alias /var/www/spottedmap_web/public/errors;
    }

    ## proxy to node
    location / {
      proxy_redirect off;
      proxy_set_header   X-Real-IP $remote_addr;
      proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Proto $scheme;
      proxy_set_header   Host $host;
      proxy_set_header   X-NginX-Proxy true;
      proxy_set_header   Connection "";
      proxy_http_version 1.1;
      proxy_pass http://spottedmap_web_upstream;
      ## upgrade is used for websockets
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      tcp_nodelay on;
    }
}

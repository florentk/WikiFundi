WikiFundi
=========

WikiFundi is a solution which provide a pre-configured Mediawiki in a
similar way like Wikipedia. Probably the easiest way to train users if
you do not have access to Internet!

Here steps to install it with Docker or on a RaspberryPi.

Mirroring with WikiFundi
------------------------

The WikiFundi image extends the `openzim/mediawiki` Docker image to
allow mirroring a existing wiki (by example Wikipedia) and
use this wiki offline

The config files are located in `config` directory.

This directory contain the configuration of :

* `mirroring/mirroring.json` : 
    Pages to copy from an other wiki and modifications after copy. 
    To get file structure :
      ```
        export PYWIKIBOT2_DIR=config/pywikibot/`
        ./wikimedia_sync.py --help
      ```
* `mediawiki/LocalSettings.custom.php` : 
    You can customise the Mediawiki by editing your this file. 
    If you want to know more, have a look to [https://www.mediawiki.org/wiki/Manual:LocalSettings.php](documentation)
* `parsoid/config.yaml` :
    Parsoid config file (allow to use VisualEdit)
* `pywikibot/user-config.py` :
    [Configure pywikibot library](https://www.mediawiki.org/wiki/Manual:Pywikibot/user-config.py) to use MediaWiki API (needed for mirroring)


You can also customize your logo in `assets/images`

To build and run :

```
mkdir -p data
docker build -t wikifundi_en .
sudo docker run -p 8080:80 -v ${PWD}/data:/var/www/data -it wikifundi_en
```
  
On start, if the database not exist, then it is initialized and the
mirroring script is lauched. If the databse exist, you can force 
mirroring by changing environments variables :

 `sudo docker run -p 8080:80 -e MIRRORING=1 -v ${PWD}/data:/var/www/data -it wikifundi_en`
 
You can also change options script with MIRRORING_OPTIONS : 

* `-f, --force` : always copy  the content (even if page exist on site dest). Default : False
* `-t, --no-sync-templates` : do not copy templates used by the pages to sync. Involve no-sync-dependances-templates. Default : False
* `-d, --no-sync-dependances-templates` : do not copy templates used by templates.  Default : False
* `-u, --no-upload-files` : do not copy files (images, css, js, sounds, ...) used by the pages to sync. Default : False
* `-p, --no-sync` : do not copy anything. If not -m, just modify. Default : False
* `-m, --no-modify` : do not modify pages. Default : False 
* `-e, --export-dir <directory>` : write json export files in this directory

To Mirroring without templates dependences  :

 `sudo docker run -p 8080:80 -e MIRRORING=1 -e MIRRORING_OPTIONS="-d" -v ${PWD}/data:/var/www/data -it wikifundi_en`
 
Go to  [http://localhost:8080/](http://localhost:8080/)

Default admin logging :

* User : Admin
* Password : wikiadmin
 
After mirroring, two tarballs are generated : one for data, log and config files and one for images (uploaded files). 
To get this tarballs, go to [http://localhost:8080/data-mw_wikifundi_en.tgz](http://localhost:8080/data-mw_wikifundi_en.tgz)
and [http://localhost:8080/images-mw_wikifundi_en.tar](http://localhost:8080/images-mw_wikifundi_en.tar)

Install on a RaspberryPi
------------------------

## Install Raspbian-lite on your RaspberryPi

Download a Raspbian-lite image and install it following these online
instructions: https://www.raspberrypi.org/downloads/raspbian/

and upgrade it:

```
sudo apt-get update
sudo apt-get dist-ugprade
```

## Get the Wikifundi dump

```
sudo mkdir /var/www
wget http://download.kiwix.org/other/wikifundi/
tar -xvf fr.africapack.kiwix.org_2016-08.tar.bz2
sudo mv fr.africapack.kiwix.org /var/www/
sudo chown -R www-data:www-data /var/www/
```

## Install a few packages necessary

`sudo apt-get install nginx php5-fpm memcached nodejs imagemagick
texlive texlive-latex-extra php-pear php5-curl php5-sqlite libav-tools
librsvg2-bin poppler-utils redis-server npm dvipng`

## Configure Nginx

Remark: please everywhere replace "fr.africapack.kiwix.org" by the
name fo your web-site and do not forget to check that you (local) DNS
can resolve it.

Create your virtual host file at `/etc/nginx/sites-available/fr.africapack.kiwix.org`

---

```
upstream php {
        server unix:/var/run/php5-fpm.sock;
}

server {
    listen      80;
    listen      [::]:80;

    server_name fr.africapack.kiwix.org;
    root        /var/www/fr.africapack.kiwix.org;
    access_log  /var/log/nginx/fr.africapack.kiwix.org.access.log;
    error_log   /var/log/nginx/fr.africapack.kiwix.org.error.log;

    client_max_body_size 100m;
    client_body_timeout 600;

    # Mediawiki redirections
    location / {
        index index.html index.php index.php5;
        rewrite ^/wiki/(.*)$ /w/index.php?title=$1&$args;
        rewrite ^/([^/\.]*)$ /wiki/$1 redirect;
    }

    # PHP handler
    location ~ ^(?!.*/images/).*\.(php|hh) {
        fastcgi_keep_conn        on;
        fastcgi_pass             php;
        fastcgi_index            index.php;
        fastcgi_param            SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include                  fastcgi_params;
        fastcgi_split_path_info  ^(.+\.php?)(/.+)$;
        fastcgi_param            PATH_INFO $fastcgi_path_info;
        fastcgi_param            SERVER_SOFTWARE nginx;
        fastcgi_param            REQUEST_URI $request_uri;
        fastcgi_param            QUERY_STRING $query_string;
        fastcgi_intercept_errors on;
        fastcgi_param            HTTP_ACCEPT_ENCODING      ""; # Safari has a problem here
    }

    # Force caching images
    location ~ ^/[^w].*\.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 10d;
    }
}
```

---

```
cd /etc/nginx/sites-enabled
ln -s ../site-available/fr.africapack.kiwix.org 
sudo service php5-fpm restart
sudo service nginx restart
```
## Configure Lua

If you have lua problems (which is the case on RaspberryPi), you need
to use the lua of the system.

`sudo apt-get install lua5.1`

and then put in the
`/var/www/fr.africapack.kiwix.org/w/Localsettings.custom.php` the
following line:
`$wgScribuntoEngineConf['luastandalone']['luaPath'] = "/usr/bin/lua5.1";`

## Configure Parsoid

Parsoid is the serveur mandatory for the visual editor.

```
wget http://download.kiwix.org/other/wikifundi/parsoid_2016-08.tar.bz2
tar -xvf parsoid_2016-08.tar.bz2
sudo mv parsoid /var/www
```

Create a link for new nodejs name:

```
cd /usr/bin`
sudo ln -s nodejs node
```

Do not forget to customize your parsoid configuration in
`/var/www/parsoid/localsettings.js`

`sudo chown -R www-data:www-data /var/www`

To start the Parsoid daemon, run `/var/www/parsoid/bin/server.js`

## Get the Math renderer correctly

`sudo apt-get install build-essential dvipng ocaml cjk-latex
texlive-fonts-recommended texlive-lang-greek texlive-latex-recommended`

```
cd /var/www/fr.africapack.kiwix.org/w/extensions/Math/math
sudo make clean all
cd /var/www/fr.africapack.kiwix.org/w/extensions/Math/texvccheck
sudo make clean all
cd ..
sudo chown -R www-data:www-data .
```

## Clean cache

got to `/var/www/fr.africapack.kiwix.org/w/maintenance/` and run:
`./update.php --skip-external-dependencies`


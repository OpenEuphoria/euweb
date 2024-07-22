# OpenEuphoria's Web Application

## Dependencies

* https://github.com/OpenEuphoria/edbi
* https://github.com/OpenEuphoria/webclay
* https://github.com/OpenEuphoria/creole

## Configuration

Read [source/config.e](https://github.com/OpenEuphoria/euweb/blob/master/source/config.e).
Create your own configuration file and include it from `source/config.e` inside an `ifdef`.

A sample config file might look like:

```euphoria
public constant DB_DRIVERS_PATH = "drivers"
public constant DB_URL = "mysql://user:password@localhost:3306/database_name"

-- Do NOT include the trailing slash
public constant ROOT_URL = "http://localhost"

public constant AUTO_LOGIN_UID = 0 -- 0 disables, otherwise set to your UID

-- reCAPTCHA keys
public constant RECAPTCHA_PRIVATE_KEY = ""
public constant RECAPTCHA_PUBLIC_KEY = ""
```

Create a `eu.cfg` file in the `euweb/htdocs` directory. It should have the following:

```
-batch
-i /path/to/euphoria/include
-p etml,etag:/dir/to/webclay/webclay/etml.ex
-i /path/to/edbi
-i /path/to/creole
-i /path/to/webclay
-i /path/to/euweb/source
-d <ifdef used in config.e>
```

This enables the webclay preprocessor and ensures that all of the include files can be found when
running euweb. The preprocessor needs to be run by a user that can write the post processed files.
The cgi process likely will not be running with those permissions. For the initial configuration,
and any time any of the templates in euweb/source/templates change, you will probably need to
execute euweb/htdocs/euweb.ex manually from the command line in order to reprocess the templates.

## Database

euweb uses a MySQL database, so you'll need to have the MySQL server installed. The `sql/euweb.sql`
file will create the database schema required, and adds a few users and a post, as well.  It uses
a database named euweb.  To run it:

```
$ mysql -u <username> -p < euweb.sql
```

## Apache

Configuration files can be in different places on different systems. This guide will assume the
following files:

* /etc/apache2/apache2.conf
* /etc/apache2/sites-enabled/000-default

If you do not have the second, look for some lines like the following in `apache2.conf`:

```
# Include the virtual host configurations:
Include /etc/apache2/sites-enabled/
```

The 000-default file should look like this:

```
<VirtualHost *:80>
  ServerAdmin webmaster@localhost

  DocumentRoot /var/www/htdocs
  <Directory />
    Options FollowSymLinks
    AllowOverride All
  </Directory>

  <Directory /var/www/htdocs>
    Options Indexes FollowSymLinks MultiViews ExecCGI
    AllowOverride All
    Order allow,deny
    Allow from all
    AddHandler cgi-script .ex
  </Directory>

  ErrorLog /var/log/apache2/error.log

  # Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
  LogLevel warn

  CustomLog /var/log/apache2/access.log combined

</VirtualHost>
```

This assumes that `/var/www/htdocs` is the root directory from which apache will serve pages. You
can simply make a symlink from /var/www to your euweb htdocs dir:

```
$ cd /var/www
$ sudo ln -s /dir/to/euweb/htdocs htdocs
```

## .htaccess

euweb uses some rewrite rules to make some friendly urls through an .htaccess file. A default
.htaccess is in the repository, though you can additionally configure it.

While developing and testing, your local IP may end up being in the banned list. If this happens,
you can simply delete that line from the `IP_BAN_LIST`, or revert the file via svn (assuming you
haven't changed anything else).

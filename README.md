# [jaesin/drupal7ci-mysql](https://hub.docker.com/repository/docker/jaesin/drupal7ci-mysql)

This Docker project adds composer and mysql-server=5.7 to `juampynr/drupal7ci`. It is intended for testing a drupal 7 codebase that uses a single database.

## Apache docroot

The apache site root is `/var/www/html/docroot`. If you require a different docroot, you can modify/replace `` and restart apache.

## Mysql

The database is initialized with the a single database and user. The db connection URL is `mysql://drupal:drupal@127.0.0.1/drupal`. 

## Composer

In order to install dependencies you can use `/usr/local/bin/composer -d /var/www/html install`. It may be the case you only need to install dev dependencies but the command is the same.

## Simpletest

If using drush to install a base system for testing you can use something like the following:

```bash
/usr/local/bin/php /var/www/html/vendor/bin/drush si -y \
  -r /var/www/html/docroot \
  --db-url="mysql://drupal:drupal@127.0.0.1/drupal" \
  testing \
  install_configure_form.update_status_module='[FALSE,FALSE]'
```

You could then use the following to run your tests:

```bash
cd /var/www/html/docroot
sudo -u www-data /usr/local/bin/php ./scripts/run-tests.sh \
	--color \
	--verbose \
	--url http://127.0.0.1/ \
	--directory sites/all/modules/custom/
```

## Code Analysis

If you have PHPStan, PHPCS and `drupal/coder` as dev dependencies in composer you can add the following to your testing step:

```bash
cd /var/www/html/docroot
/usr/local/bin/php ../vendor/bin/phpcs sites/all/themes/custom sites/all/modules/custom
/usr/local/bin/php ../vendor/bin/phpstan analyse -c path/to/phpstan-config.neon

```

PHPSTAN config:

```neon
parameters:
  bootstrapFiles:
    - bootstrap.php
  level: 6
  paths:
    - ../../themes/custom
    - ../../modules/custom
```
PHPSTAN bootstrap file:

```php
<?php
/**
 * @file This file is used to boostrap an instance for testing.
 */

$root_path = '/var/www/html/docroot/';

// The Remote address is required by drupal.
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';
$_SERVER['REQUEST_URI'] = '/';
$_SERVER['REQUEST_METHOD'] = 'GET';

// Bootstrap Drupal.
define('DRUPAL_ROOT', realpath($root_path));
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);
```

## Github actions

If you are using this repository as your runner image with github actions, you will have to start apache and mysql with `service apache2 start && service mysql start`. Github actions takes over the entrypoint so `tini -- /usr/local/bin/docker-init` won't be executed.
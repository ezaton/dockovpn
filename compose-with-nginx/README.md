# Using nginx

## nginx configuration
nginx is used as a buffer in front of the openvpn configuration, with htpasswd to allow a simple moderation of the access to the newly added account.
The current example docker-compose demonstrates a simple method of doing it.

## Purpose
Originally, when creating a new account/configuration directive, a web service is activated until the configuration is obtained by a remote client.
This configuration is designed to add a layer of simple authentication to protect against random port scan which will obtain OpenVPN configuration.

## Configuration directives
Two files can be found:
| Name    | Description |
| default.conf | nginx main configuration file, enforcing a simple reverse proxy, with htpass authentication |
| htpasswd | htpasswd file, containing the user(s) simple authentication details |

## Generating htpasswd contents
An easy method to create your own dedicated password entry would be to browse to https://www.web2generators.com/apache-tools/htpasswd-generator
Enter the details, and in return, you will get a line to add to the file. 


# koinwatch-proxy-load-balancer
0. Clone project and change directory into repo folder.

1. Install needed components.

```bash
bash install-docker.sh
```
2. Create the .htpasswd file:

```bash
 htpasswd -c .htpasswd <username>
 Press Enter and type the password for user at the prompts.
```
Add more user
```bash
 htpasswd -c htpasswd
 Press Enter and type the password for user at the prompts.
```
3. Fill in the docker-compose file:
```bash
            CERTBOT_EMAIL: <email to get cert status>
            DOMAIN: proxy1.koinwatch.com <- your proxy domain name
            DNS_IP: 8.8.8.8 <- DNS to use with proxy
```
4. Build the image:
```bash
docker-compose build
```
5. Start the service:
```bash
docker-compose up -d
```

# About
Create the infrastructure needed by you django project in docker.

### Clone Repository
```
git clone https://github.com/fredericowu/docker-django
cd docker-django
```


### Basic Usage
1. Configure you environment with a git repository:
```sh
./config.sh https://github.com/fredericowu/cognitivo
```
2. Check your environment configuration by editing env/docker_django

3. Run build and start.
```sh
make build && make start
```
4. Open your browser and access the host (default port: 7778)


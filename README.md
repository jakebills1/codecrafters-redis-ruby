## Purpose
This is a partial implementation of Redis in Ruby, to learn more about how a server program like Redis could be written in Ruby, following CodeCrafters' [Build Your Own Redis](https://app.codecrafters.io/courses/redis/overview) challenge. 
I have written about my experience on my blog at www.jakebills.com 

## Usage
### Running the server
Assuming a ruby installation is present, run the following in the project directory:
```bash
$ ./your_program.sh
```
### Testing using redis-cli
In another terminal, make sure you have redis-cli and don't already have a redis server running on port 6379, and run:
```bash
$ redis-cli PING
  PONG
$ redis-cli ECHO hi
  hi
$ redis-cli SET foo bar
  OK
$ redis-cli GET foo
  "bar"
```





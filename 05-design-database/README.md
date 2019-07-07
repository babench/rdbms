Design the database
=======

### Run

 - Run the PostgreSQL instance by [Docker Compose](https://docs.docker.com/compose/) with local db
```bash
$ docker-compose -f ./05-design-database/docker-compose.yml up
$ docker exec -ti otus-database bash
bash-4.4# psql -U store_user -d store
psql (11.4)
Type "help" for help.
```

 - ...

### Stop

 * The app is terminated by the response to a user interrupt such as typing `^C` (Ctrl + C) or a system-wide event of a shutdown
```bash
...
^CGracefully stopping... (press Ctrl+C again to force)
Killing otus-database  ... done
```

 * Remove containers and networks
```bash
$ docker-compose -f ./05-design-database/docker-compose.yml down
Removing otus-database ... done
Removing network 05-design-database_default
```


## Documentation


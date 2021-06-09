# docker-airflow

This repository contains dockerfile for Apache Airflow 2.0 as well as a docker-compose to spin up a airflow cluster using the Celery Executor. 



## Prerequisites

- [Install docker](https://gist.github.com/shivanshthapliyal/1abf664fbd39d36cd2c6115ea3f44f4c#docker-installation)
- [Install docker-compose](https://gist.github.com/shivanshthapliyal/1abf664fbd39d36cd2c6115ea3f44f4c#docker-compose)

---

## Usage

**Step 1.** Clone the Repository
```
git clone https://github.com/shivanshthapliyal/docker-airflow.git
```

**Step 2.** 
```
cd docker-airflow 
docker-compose -f docker-compose-CeleryExecutor.yml up --remove-orphans
```

That's it, Airflow Webserver UI should now be available at: http://localhost:8080 and Celery Flower UI at: http://localhost:5555

> **Note:** Default admin credentials are:
    **Username** : admin 
    **Password** : airflowadmin007
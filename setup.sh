#!/bin/bash
command=$1
if [[ "$command" == "up" ]]
then
    if [ ! -f ./Dockerfile ] || [ ! -f ./requirements.txt ] || [ ! -f ./docker-compose.yml ]
    then
        wget https://raw.githubusercontent.com/shivanshthapliyal/docker-airflow/main/Dockerfile https://raw.githubusercontent.com/shivanshthapliyal/docker-airflow/main/requirements.txt https://raw.githubusercontent.com/shivanshthapliyal/docker-airflow/main/docker-compose.yml
    fi;
    # To build docker image locally : 
    # Add any pip requirements if needed to requirements.txt
    docker build -t docker-airflow .
    # To run airflow : 
    docker-compose up
else [[ "$command" == "down" ]]   
    if [ ! -f ./docker-compose.yml ]
    then
        wget https://raw.githubusercontent.com/shivanshthapliyal/docker-airflow/main/docker-compose.yml
    fi  
    docker-compose down
fi;

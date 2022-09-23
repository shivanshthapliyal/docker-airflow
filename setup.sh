#!/bin/bash
command=$1
if [ -x "$(command -v docker)" ]; then
    echo "Docker is installed..."
    if [ -x "$(command -v docker-compose)" ]; then
        echo "Docker-compose is installed..."
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
            docker-compose up -d 
        else [[ "$command" == "down" ]]   
            if [ ! -f ./docker-compose.yml ]
            then
                wget https://raw.githubusercontent.com/shivanshthapliyal/docker-airflow/main/docker-compose.yml
            fi  
            docker-compose down
        fi;
    else
        echo "Install docker-compose first.."
    fi
else
    echo "Install docker first.."
fi

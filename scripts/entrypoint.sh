#!/usr/bin/env bash

# User-provided configuration must always be respected.
#
# Therefore, this script must only derives Airflow AIRFLOW__ variables from other variables
# when the user did not provide their own configuration.

TRY_LOOP="100"

wait_for_port() {
   local name="$1" host="$2" port="$3"
   local j=0
   while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
     j=$((j+1))
     if [ $j -ge $TRY_LOOP ]; then
       echo >&2 "$(date) - $host:$port still not reachable, giving up"
       exit 1
     fi
     echo "$(date) - waiting for $name... $j/$TRY_LOOP"
     sleep 5
   done
}

echo "Trying to execute entrypoint script "

# Global defaults and back-compat
: "${AIRFLOW_HOME:="/usr/local/airflow"}"
: "${AIRFLOW__CORE__FERNET_KEY:=${FERNET_KEY:=$(python3 -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")}}"
: "${AIRFLOW__CORE__EXECUTOR:=${EXECUTOR:-Sequential}Executor}"
: "${ENVIRONMENT:="test"}"
: "${AIRFLOW__CORE__DEFAULT_TIMEZONE:="Asia/Dubai"}"

# Load DAGs examples (default: Yes)
if [[ -z "$AIRFLOW__CORE__LOAD_EXAMPLES" && "${LOAD_EX:=n}" == n ]]; then
  AIRFLOW__CORE__LOAD_EXAMPLES=False
fi

export \
  AIRFLOW_HOME \
  AIRFLOW__CORE__EXECUTOR \
  AIRFLOW__CORE__FERNET_KEY \
  AIRFLOW__CORE__LOAD_EXAMPLES \
  ENVIRONMENT

echo "Airflow home is ${AIRFLOW_HOME}"
echo "Executor is ${AIRFLOW__CORE__EXECUTOR}"

if [[ ${METASTORE} == 'Local' || -z "$METASTORE" ]]; then
  echo "Received Local executor - will use SQLlite as db"
  AIRFLOW__CORE__EXECUTOR="SequentialExecutor"
  export AIRFLOW__CORE__EXECUTOR
elif [[ ${METASTORE} != 'External' ]]; then
    echo "METASTORE value received is ${METASTORE} - applying Internal Metastore conf"
    # Check if the user has provided explicit Airflow configuration concerning the database
    if [ -z "$AIRFLOW__CORE__SQL_ALCHEMY_CONN" ]; then
      # Default values corresponding to the default compose files
      : "${MYSQL_HOST:="MYSQL"}"
      : "${MYSQL_PORT:="3306"}"
      : "${MYSQL_USER:="airflow_pg_user"}"
      : "${MYSQL_PASSWORD:="airflow_pg_password"}"
      : "${MYSQL_DB:="airflow_pg_db"}"
      : "${MYSQL_EXTRAS:-""}"

      AIRFLOW__CORE__SQL_ALCHEMY_CONN="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}${MYSQL_EXTRAS}"
      export AIRFLOW__CORE__SQL_ALCHEMY_CONN

      # Check if the user has provided explicit Airflow configuration for the broker's connection to the database
      if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]; then
        AIRFLOW__CELERY__RESULT_BACKEND="db+mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}${MYSQL_EXTRAS}"
        export AIRFLOW__CELERY__RESULT_BACKEND
      fi
    else
      if [[ "$AIRFLOW__CORE__EXECUTOR" == "CeleryExecutor" && -z "$AIRFLOW__CELERY__RESULT_BACKEND" ]]; then
        >&2 printf '%s\n' "FATAL: if you set AIRFLOW__CORE__SQL_ALCHEMY_CONN manually with CeleryExecutor you must also set AIRFLOW__CELERY__RESULT_BACKEND"
        exit 1
      fi

      # Derive useful variables from the AIRFLOW__ variables provided explicitly by the user
      MYSQL_ENDPOINT=$(echo -n "$AIRFLOW__CORE__SQL_ALCHEMY_CONN" | cut -d '/' -f3 | sed -e 's,.*@,,')
      MYSQL_HOST=$(echo -n "$MYSQL_ENDPOINT" | cut -d ':' -f1)
      MYSQL_PORT=$(echo -n "$MYSQL_ENDPOINT" | cut -d ':' -f2)
    fi
else
    echo "METASTORE value received is ${METASTORE} - applying External Metastore conf"
    if [ -z "$AIRFLOW__CORE__SQL_ALCHEMY_CONN" ]; then
        # Default values corresponding to the default compose files
        if [[ -z "${MYSQL_HOST}" ]]; then
            echo "MYSQL - host is not specified - applying default values"
            : "${MYSQL_HOST:="MYSQL"}"
        fi
        if [[ -z "${MYSQL_PORT}" ]]; then
            echo "MYSQL - port is not specified - applying default values"
            : "${MYSQL_PORT:="5432"}"
        fi
        if [[ -z "${MYSQL_USER}" ]]; then
            : "${MYSQL_USER:="airflow_pg_user"}"
            echo "MYSQL - user is not specified - applying default values"
        fi
        if [[ -z "$MYSQL_PASSWORD" ]]; then
            echo "MYSQL - password is not specified - applying default values"
            : "${MYSQL_PASSWORD:="airflow_pg_password"}"
        fi
        if [[ -z "$MYSQL_DB" ]]; then
            echo "MYSQL - db is not specified - applying default values"
            : "${MYSQL_DB:="airflow_pg_db"}"
        fi
            : "${MYSQL_EXTRAS:-""}"

        AIRFLOW__CORE__SQL_ALCHEMY_CONN="mysql+mysqldb://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}${MYSQL_EXTRAS}"

        export AIRFLOW__CORE__SQL_ALCHEMY_CONN

        # Check if the user has provided explicit Airflow configuration for the broker's connection to the database
        if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]; then
          AIRFLOW__CELERY__RESULT_BACKEND="db+mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}${MYSQL_EXTRAS}"
          export AIRFLOW__CELERY__RESULT_BACKEND
        fi
    else
        if [[ "$AIRFLOW__CORE__EXECUTOR" == "CeleryExecutor" && -z "$AIRFLOW__CELERY__RESULT_BACKEND" ]]; then
          >&2 printf '%s\n' "FATAL: if you set AIRFLOW__CORE__SQL_ALCHEMY_CONN manually with CeleryExecutor you must also set AIRFLOW__CELERY__RESULT_BACKEND"
          exit 1
        fi

        # Derive useful variables from the AIRFLOW__ variables provided explicitly by the user
        MYSQL_ENDPOINT=$(echo -n "$AIRFLOW__CORE__SQL_ALCHEMY_CONN" | cut -d '/' -f3 | sed -e 's,.*@,,')
        MYSQL_HOST=$(echo -n "$MYSQL_ENDPOINT" | cut -d ':' -f1)
        MYSQL_PORT=$(echo -n "$MYSQL_ENDPOINT" | cut -d ':' -f2)
    fi
    # wait_for_port "MYSQL" "$MYSQL_HOST" "$MYSQL_PORT"
fi

######################### Service initiatation ################################

if [[ "$1" == '/bin/bash' ]]; then
    echo "Received instruction to run the bash"
    /bin/bash
fi

if [[ "$1" == 'webserver' ]]; then
    echo "Received instruction to run the webserver"
    airflow db init
    airflow users create -u ${AIRFLOW_ADMIN_UNAME} -p ${AIRFLOW_ADMIN_PWD} -f airflow -l admin -r Admin -e airflow.admin@airflow.com
    sleep 5;
    airflow webserver -d
fi

if [[ "$1" == 'scheduler' ]]; then
    echo "Received instruction to run the ${1}"
    sleep 5;
    airflow $1
fi

if [[ "$1" == 'worker' || "$1" == 'flower' ]]; then
    echo "Received instruction to run the ${1}"
    sleep 5;
    airflow celery $1
fi

if [[ "$1" == 'silent' ]]; then
    echo "Received instruction to be silent"
fi


#
# # Install custom python package if requirements.txt is present
# if [ -e "/requirements.txt" ]; then
#     $(command -v pip) install --user -r /requirements.txt
# fi
#
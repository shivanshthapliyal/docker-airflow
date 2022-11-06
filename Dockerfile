# AIRFLOW VERSION 2.0
# BUILD: docker build --rm -t airflow/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM ubuntu:20.04
LABEL maintainer="SHIVANSH THAPLIYAL"

# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

## Airflow
ARG AIRFLOW_VERSION=2.0.1
ARG AIRFLOW_USER_HOME=/usr/local/airflow
#ARG AIRFLOW_DEPS=""
#ARG PYTHON_DEPS=""
ARG PYTHON_VERSION=3.7

#####################################################################################################
################################### ENV declaration #################################################
#####################################################################################################

ENV CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

ENV AIRFLOW_BASE_URL="" \
    AIRFLOW_FERNET_KEY="" \
    AIRFLOW_HOME=${AIRFLOW_USER_HOME} \
    AIRFLOW_HOSTNAME_CALLABLE="" \
    ############ LDAP #########
    LDAP_ALLOW_SELF_SIGNED="True" \
    LDAP_BIND_PASSWORD="" \
    LDAP_BIND_USER="" \
    LDAP_ENABLE="no" \
    LDAP_SEARCH="" \
    LDAP_TLS_CA_CERTIFICATE="" \
    LDAP_UID_FIELD="uid" \
    LDAP_URI="" \
    LDAP_USE_TLS="" \
    LOAD_EXAMPLES="yes" \
    ############ Airflow Base users ###########
    AIRFLOW_USERNAME="Admin" \
    AIRFLOW_FIRSTNAME="Admin-Firstname" \
    AIRFLOW_EMAIL="admin@example.com" \
    AIRFLOW_LASTNAME="Admin-Lastname" \
    AIRFLOW_PASSWORD="Admin-Password1234" \
    AIRFLOW_POOL_DESC="" \
    AIRFLOW_POOL_NAME="" \
    AIRFLOW_POOL_SIZE="" \
    AIRFLOW_USER_REGISTRATION_ROLE="Public" \
    AIRFLOW_WEBSERVER_HOST="127.0.0.1" \
    AIRFLOW_WEBSERVER_PORT_NUMBER="8080" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    #OS_ARCH="amd64" \
    #OS_FLAVOUR="debian-10" \
    #OS_NAME="linux"
    ######### Redis ############
    REDIS_HOST="redis" \
    REDIS_PASSWORD="" \
    REDIS_PORT_NUMBER="6379" \
    REDIS_USER=""     \
    REDIS_USE_SSL="no" \
    ######### Metastore ########
    ###METASTORE to use - Internal, External or Local(docker)
    METASTORE=""  \
    POSTGRES_HOST="" \
    POSTGRES_PORT=5432 \
    POSTGRES_USER="" \
    POSTGRES_PASSWORD="" \
    POSTGRES_DB="" \
    ######### Executor ########
    EXECUTOR="Celery"


#####################################################################################################
############################# Install Basic dependencies ############################################
#####################################################################################################

### Install basic dependencies
RUN set -ex \
    && buildDeps=' \
        git \
        krb5-user \
        ldap-utils \
        libffi6 \
        libsasl2-2 \
        libsasl2-modules \
        libssl1.1 \
        locales  \
        lsb-release \
        sasl2-bin \
        sqlite3 \
        unixodbc \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install sudo wget nano telnet unzip -yqq \
    && apt-get install libsasl2-dev python-dev libldap2-dev libssl-dev -yqq \
    && apt-get install libmysqlclient-dev libaio1 -yqq

#####################################################################################################
################################## Create Airflow user ##############################################
#####################################################################################################

### Add airflow user and set sudo permissions for the same
RUN useradd -rm -d ${AIRFLOW_USER_HOME} -s /bin/bash -g root -G sudo -u 1001 airflow \
  && adduser airflow sudo \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && touch /sudo_as_admin_successful \
  && touch ${AIRFLOW_USER_HOME}/sudo_as_admin_successful


#####################################################################################################
###################### Install Airflow along with python and dependencies ###########################
#####################################################################################################


### Install python and airflow packages
RUN apt-get install python3.7 -yqq \
    && apt-get install python3-pip -yqq

###Copy requirements file to update packages
COPY requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt

### Install airflow with all the required plugins
COPY plugins.txt /plugins.txt
RUN pip3 install "apache-airflow[$(cat plugins.txt)]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

#####################################################################################################
############################ Airflow configuration and image setup ##################################
#####################################################################################################

COPY scripts/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg
# COPY config/webserver_config.py ${AIRFLOW_USER_HOME}/webserver_config.py
RUN chown -R airflow: ${AIRFLOW_USER_HOME}
RUN chmod 777 /entrypoint.sh

EXPOSE 8080 5555 8793
# ENV TZ UTC

# Installing extra requirements
RUN apt-get install software-properties-common -yqq \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt install python3.6 python3.7 git -yqq
    
# TImezone configuration
RUN apt-get install tzdata -yqq 
ENV CONTAINER_TIMEZONE="Asia/Dubai"
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone

# Adding custom modules
# ADD ./modules/ /usr/lib/python3/dist-packages/ 

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["silent"]

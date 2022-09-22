FROM apache/airflow:2.3.4
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/airflow
RUN chown -R airflow:root /usr/local/airflow

USER airflow
# Installed extra custom requirements
COPY requirements.txt /docker-context-files/requirements.txt
RUN if [[ -f /docker-context-files/requirements.txt ]]; then \
      pip install --no-cache-dir --user -r /docker-context-files/requirements.txt; \
    fi

# RUN pip install --no-cache-dir lxml
# COPY --chown=airflow:root test_dag.py /opt/airflow/dags
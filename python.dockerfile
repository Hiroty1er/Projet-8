FROM python:3.13-slim
ARG PYTHON_WORKING_DIR

RUN mkdir /${PYTHON_WORKING_DIR}
COPY ./requirement.txt /${PYTHON_WORKING_DIR}
COPY ./schema_postgres.sql /${PYTHON_WORKING_DIR}
COPY ./stg_stations.sql /${PYTHON_WORKING_DIR}
COPY ./fct_releves_horaires.sql /${PYTHON_WORKING_DIR}

RUN pip install -r /${PYTHON_WORKING_DIR}/requirement.txt
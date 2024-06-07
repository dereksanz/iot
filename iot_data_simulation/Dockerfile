FROM python:3.9-alpine

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY iot_data_simulation.py iot_data_simulation.py

CMD ["python", "iot_data_simulation.py"]


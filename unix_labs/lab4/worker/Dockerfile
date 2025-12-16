FROM python:3.9-slim
WORKDIR /main
RUN pip install pika
COPY worker.py .
CMD ["python", "worker.py"]

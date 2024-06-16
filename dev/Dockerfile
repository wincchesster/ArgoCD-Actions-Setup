FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y python3
RUN apt-get install -y python3-pip


WORKDIR /app
COPY . /app

CMD ["python3", "server.py"]

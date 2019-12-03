FROM ubuntu:latest

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . .

RUN apt-get update
RUN apt-get install -y unzip
RUN apt-get install -y wget
RUN wget https://releases.hashicorp.com/terraform/0.12.17/terraform_0.12.17_linux_amd64.zip
RUN unzip terraform_0.12.17_linux_amd64.zip
RUN mv terraform /usr/local/bin/

RUN ["terraform", "init", "./Services/Development"]
RUN ["terraform", "apply", "-auto-approve", "./Services/Development"]
RUN ["terraform", "init", "./Services/Production"]
RUN ["terraform", "apply", "-auto-approve", "./Services/Production"]

CMD [ "/bin/bash" ]

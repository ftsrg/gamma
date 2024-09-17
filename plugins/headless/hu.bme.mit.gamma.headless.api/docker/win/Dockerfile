FROM ubuntu

# First, the OS is updated, and then the necessary tools and packages are installed

RUN apt-get update
RUN apt-get install -y default-jre
RUN apt-get install nano
RUN apt-get install -y maven
RUN apt-get install -y default-jdk
RUN apt-get install -y libswt-gtk*
RUN apt-get install wget

# Second, the UPPAAL and Theta verification tools are added, with their environmental variables

WORKDIR "/home"
RUN mkdir uppaal
ADD uppaal /home/uppaal
ENV PATH="/home/uppaal/bin-Linux:${PATH}"

ENV THETA_FOLDER="/home/theta"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$THETA_FOLDER"
ENV THETA_XSTS_CLI_PATH="$THETA_FOLDER/theta-xsts-cli.jar"
RUN mkdir -p $THETA_FOLDER

ADD theta /home/theta

WORKDIR "/home/theta"

RUN ./get-theta.sh

# Finally, the headless Gamma and generator is added, along with the webserver

WORKDIR "/home"
RUN mkdir project
ADD project /home/project
RUN mkdir server
ADD server /home/headless
WORKDIR "/home/headless/"
RUN mvn package
EXPOSE 8080
ENTRYPOINT mvn exec:java
#WORKDIR "/home"